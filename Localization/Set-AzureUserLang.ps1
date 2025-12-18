#Requires -Modules @{ ModuleName="Az.Resources"; ModuleVersion="6.11.1" }
#Requires -Modules @{ ModuleName="Az.Accounts"; ModuleVersion="2.19.0" }
#Requires -PSEdition Core
#Requires -Version 7.3.4

<#
    Script takes the LanguageCode and sets the preferred language in Azure
#>

$ProgressPreference = 'Ignore'
$WarningPreference = 'Ignore'
$InformationPreference = 'Ignore'
$ParamSet = $null

# Test Environment
try {$AzContext = Get-AzContext -ErrorAction Stop} catch {}

If ($null -eq $AzContext)
{
    Write-Output "No AZ context"
    # Required variables
    $Req_Vars = @{
        LanguageCode = '@lab.LanguageCode'
        DefaultRegionList = 'LODSContent/Orchestration/Localization/DefaultRegionList.json'
        Admin_Set = @{
            AdminUser = '@lab.CloudCredential(1).AdministrativeUsername'
            AdminPassword = '@lab.CloudCredential(1).AdministrativePassword'
        }
        CloudSlice_Set = @{
            appID = '00000000-0000-0000-0000-000000000000'
            appSecret = 'secret'
            tenant = '00000000-0000-0000-0000-000000000000'
            PortalUser = '@lab.CloudPortalCredential(1).Username'
        }
    }

    # Test for Variables
    Foreach ($Req_Var in $Req_Vars.Keys)
    {
        if ($Req_Var -notmatch '_Set')
        {
            if (-not (Get-Variable -name $Req_Var -ErrorAction Ignore))
            {
                Write-Error "Required Variable missing: '$Req_Var'"
            }
            if ((Get-Variable -name $Req_Var -ErrorAction Ignore).Value -match "^@lab")
            {
                Write-Error "LabVariable '$((Get-Variable -name $Req_Var).Value)' invalid"
            }
        }
        else
        {
            $SetTotal = $Req_Vars.Item($Req_Var).Count
            $SetCount = 0
            Foreach ($Req_SubVar in $Req_Vars.Item($Req_Var).Keys)
            {
                if (-not (Get-Variable -name $Req_SubVar -ErrorAction Ignore))
                {
                    $ErrorMessage += "Required Variable missing: '$Req_SubVar'" | Out-String
                } elseif ((Get-Variable -name $Req_SubVar -ErrorAction Ignore).Value -match "^@lab")
                {
                    $ErrorMessage += "LabVariable '$((Get-Variable -name $Req_SubVar -ErrorAction Ignore).Value)' invalid" | Out-String
                } else {$SetCount++}
            }
            If ($SetCount -ne $SetTotal)
            {
                $ErrorMessage += "Set: $Req_Var not complete" | Out-String
            }
            else
            {
                [string[]]$ParamSet += $Req_Var
            }
        }
    }
    If ($null -eq $ParamSet) {throw $ErrorMessage}
    elseif ($ParamSet.Count -gt 1) {throw "Both Admin and CloudSlice variables defined. Only define one."}
    # Test Environment
    ## Module
    if (Get-Module -ListAvailable -Name Az*) {throw "Remove all Az modules from the environment."}

    ## PowerShell version
    If (-not ($PSVersionTable.PSVersion -eq [Version]::new(7,3,4))) {throw "Minimum PSVersion 7.3.4 required."}

    $RequiredModules = @(
        @{ ModuleName="Az.Resources"; ModuleVersion="6.11.1" } # Dependency on Az.Accounts; Must be first
        @{ ModuleName="Az.Accounts"; ModuleVersion="2.19.0" }
    )

    Foreach ($RequiredModule in $RequiredModules)
    {
        # Remove modules before uninstalling
        Get-Module -Name $RequiredModule.ModuleName | Remove-Module -Force
        # Uninstall all modules not matching the version
        Get-Module -ListAvailable $RequiredModule.ModuleName | `
            Where-Object {[Version]$RequiredModule.ModuleVersion -ne $_.Version} | `
            Uninstall-Module -Force
        # Install module version if not present
        If (
            -not (
                ([Version]$RequiredModule.ModuleVersion) -in 
                (Get-Module -ListAvailable -Name $RequiredModule.ModuleName).Version
            )
        )
        {
            Install-Module -Name $RequiredModule.ModuleName -RequiredVersion $RequiredModule.ModuleVersion -Force -AllowClobber | Out-Null
        }
    }

    switch ($ParamSet)
    {
        'Admin_Set' {
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($AdminUser, (ConvertTo-SecureString -AsPlainText -Force -String $AdminPassword))
            $ConnectAzAccount = {
                Connect-AzAccount -Credential $Credential
            }
        }
        'CloudSlice_Set' {
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($appID, (ConvertTo-SecureString -AsPlainText -Force -String $appSecret))
            if (-not [string]::IsNullOrWhiteSpace($cloudSubscriptionId))
            {
                $ConnectAzAccount = {
                    Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant $tenant -Subscription $cloudSubscriptionId -SkipContextPopulation
                }
            }
            else
            {
                $ConnectAzAccount = {
                    Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant $tenant -SkipContextPopulation
                }
            }
        }
    }
    # Connect to Exchange Online & Az
    # Connect-ExchangeOnline -Credential $Credential -ShowBanner:$false
    while ($i++ -lt 3)
    {
        try {
            $AzAdConnect = . $ConnectAzAccount
            break
        }catch {$ErrorMessage += $_}
    }
    If ($null -eq $AzAdConnect) {throw "Failed to connect to Azure AD"}
}

## Setup Vars
$LanguageFormat = $DefaultRegionList | Where-Object {$_.LanguageCode -eq $LanguageCode}
$CountryCode = $LanguageFormat.RegionCode.Split('-')[1]
$RegionCode = $LanguageFormat.RegionCode

## Reconfigure Mailbox Region
#$dateFormat = $LanguageFormat.DateFormat
#$timeFormat = $LanguageFormat.TimeFormat

## Pull all users and update both AzADUser and MailboxRegionalConfig
$users = $(
    switch ($ParamSet)
    {
        'Admin_Set' {Get-AzADUser}
        'CloudSlice_Set' {Get-AzADUser -UserPrincipalName $PortalUser}
        default {Get-AzADUser -UserPrincipalName $PortalUser}
    }
)
If ($null -eq $users) {Write-Error "No cloud users found."}
foreach ($user in $users) {
    Update-AzADUser -UPNOrObjectId $user.UserPrincipalName -PreferredLanguage $RegionCode -UsageLocation $CountryCode
 
    #if ($user = Get-Mailbox $user.UserPrincipalName -ErrorAction SilentlyContinue)
    #{ $user | Get-MailboxRegionalConfiguration | Set-MailboxRegionalConfiguration -Language $languageCode -DateFormat $dateFormat -TimeFormat $timeFormat }
}
Disconnect-AzAccount | Out-Null
