$LanguageRegionCode = '@lab.LanguageRegionCode'

$BaseURI = "https://raw.githubusercontent.com/LODSContent/Orchestration/main"
$Scripts = @(
    "Functions.ps1"
    "TimeSync/Set-TimeSync.ps1"
    "Localization/Set-Localization.ps1"
)

Foreach ($Script in $Scripts)
{
    Invoke-Command -NoNewScope -ScriptBlock ([scriptblock]::Create((Invoke-RestMethod -Uri "${BaseURI}/${Script}")))
}
if ($Reboot) {shutdown -r -t 3}
