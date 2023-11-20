#Requires -Modules @{ ModuleName="Az"; ModuleVersion="10.4.1" }
#Requires -PSEdition Core
#Requires -Version 7.3.4

<#
    Script takes the LanguageCode and sets the preferred language in Azure
#>

$WarningPreference = 'Ignore'
$InformationPreference = 'Ignore'

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
If (-not ((Get-Module -ListAvailable -Name Az).Version -eq [Version]::new(10,4,1))) {throw "Invalid module version"}

## PowerShell version
If (-not ($PSVersionTable.PSVersion -eq [Version]::new(7,3,4))) {throw "Invalid PSVersion"}

## Setup Vars
$LanguageFormat = $DefaultRegionList | Where-Object {$_.LanguageCode -eq $LanguageCode}
$CountryCode = $LanguageFormat.RegionCode.Split('-')[1]
$RegionCode = $LanguageFormat.RegionCode

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
        $ConnectAzAccount = {
            Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant $tenant
        }
    }
}

## Reconfigure Mailbox Region
#$dateFormat = $LanguageFormat.DateFormat
#$timeFormat = $LanguageFormat.TimeFormat

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

## Pull all users and update both AzADUser and MailboxRegionalConfig
$users = $(
    switch ($ParamSet)
    {
        'Admin_Set' {Get-AzADUser}
        'CloudSlice_Set' {Get-AzADUser -UserPrincipalName $PortalUser}
    }
)
If ($null -eq $users) {Write-Error "No cloud users found."}
foreach ($user in $users) {
    Update-AzADUser -UPNOrObjectId $user.UserPrincipalName -PreferredLanguage $RegionCode -UsageLocation $CountryCode
 
    #if ($user = Get-Mailbox $user.UserPrincipalName -ErrorAction SilentlyContinue)
    #{ $user | Get-MailboxRegionalConfiguration | Set-MailboxRegionalConfiguration -Language $languageCode -DateFormat $dateFormat -TimeFormat $timeFormat }
}
Disconnect-AzAccount | Out-Null
