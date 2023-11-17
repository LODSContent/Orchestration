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
    AdminUser = '@lab.CloudCredential(1).AdministrativeUsername'
    AdminPassword = '@lab.CloudCredential(1).AdministrativePassword'
}

# Test for Variables
Foreach ($Req_Var in $Req_Vars.Keys)
{
    if (-not (Get-Variable -name $Req_Var -ErrorAction Ignore))
    {
        Write-Error "Required Variable missing: '$Req_Var'"
    }
    if ((Get-Variable -name $Req_Var).Value -match "^@lab")
    {
        Write-Error "LabVariable '$((Get-Variable -name $Req_Var).Value)' invalid"
    }
}

# Test Environment
## Module
If (-not ((Get-Module -ListAvailable -Name Az).Version -eq [Version]::new(10,4,1))) {throw "Invalid module version"}

## PowerShell version
If (-not ($PSVersionTable.PSVersion -eq [Version]::new(7,3,4))) {throw "Invalid PSVersion"}

## Setup Vars
$LanguageFormat = $DefaultRegionList | Where-Object {$_.LanguageCode -eq $LanguageCode}
$CountryCode = $LanguageFormat.RegionCode.Split('-')[1]
$RegionCode = $LanguageFormat.RegionCode

$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($AdminUser, (ConvertTo-SecureString -AsPlainText -Force -String $AdminPassword))

## Reconfigure Mailbox Region
#$dateFormat = $LanguageFormat.DateFormat
#$timeFormat = $LanguageFormat.TimeFormat

# Connect to Exchange Online & Az
# Connect-ExchangeOnline -Credential $Credential -ShowBanner:$false
while ($i++ -lt 3)
{
    try {
        $AzAdConnect = Connect-AzAccount -Credential $Credential
        break
    }catch {$ErrorMessage += $_}
}
If ($null -eq $AzAdConnect) {throw "Failed to connect to Azure AD"}

## Pull all users and update both AzADUser and MailboxRegionalConfig
$users = Get-AzADUser
foreach ($user in $users) {
    Update-AzADUser -UPNOrObjectId $user.UserPrincipalName -PreferredLanguage $RegionCode -UsageLocation $CountryCode
 
    #if ($user = Get-Mailbox $user.UserPrincipalName -ErrorAction SilentlyContinue)
    #{ $user | Get-MailboxRegionalConfiguration | Set-MailboxRegionalConfiguration -Language $languageCode -DateFormat $dateFormat -TimeFormat $timeFormat }
}
Disconnect-AzAccount | Out-Null
