<#
    Script takes the LanguageRegionCode lab variable and sets the Windows environment locale and language settings to match
#>

# Functions used:
#   RunScheduledTask
#   RunElevated
#   Get-GeoId

# Required variables
$Req_Vars = @{
    LanguageRegionCode = '@lab.LanguageRegionCode'
}

# Test for Variables
Foreach ($Req_Var in $Req_Vars.Keys)
{
    if (-not (Get-Variable -name $Req_Var -ErrorAction Ignore))
    {
        Write-Error "Required Variable missing: '$Req_Var'"
    }
}

############################################

$currentLanguage = (Get-Culture).Name
if ($LanguageRegionCode -eq 'ja-JA') {$LanguageRegionCode = 'ja-JP'}
if ($LanguageRegionCode -eq 'ko-KO') {$LanguageRegionCode = 'ko-KR'}

if($LanguageRegionCode -ne $currentLanguage)
{
    $OSInfo = Get-WmiObject -Class Win32_OperatingSystem
    $languagePacks = $OSInfo.MUILanguages
    If($LanguageRegionCode)
    {
        If ($languagePacks.ToLower() -contains $LanguageRegionCode.ToLower() -eq $False) # Exact Match
        {
            # Find best Match
            $newLanguageRegionCode = $languagePacks | Where-Object {$PSItem -match "^$($LanguageRegionCode.Split('-')[0])-"} | Select-Object -First 1
            If ($null -eq $newLanguageRegionCode)
            {
                # Handle language pack not matching - Language not installed
                Write-Error "This language pack $LanguageRegionCode is not installed. Please install it first."
            }
            else
            {
                $LanguageRegionCode = $newLanguageRegionCode
            }
        }
        # Language installed, set it.
        if ($LanguageRegionCode -eq 'ja-JP') {
            $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\i8042prt\Parameters"
            Set-ItemProperty -Path $registryPath -Name 'LayerDriver JPN' -Value 'kbd106.dll' -Type String
            Set-ItemProperty -Path $registryPath -Name 'OverrideKeyboardIdentifier' -Value 'PCAT_106KEY' -Type String
            Set-ItemProperty -Path $registryPath -Name 'OverrideKeyboardSubtype' -Value 0x00000002 -Type DWord
        }
        $RunScheduledTask_Params = @{}
        $RunScheduledTask_Params.Add("Command","")
        If (-not [string]::IsNullOrWhiteSpace($VMUser))
        {
            $RunScheduledTask_Params.Add("User",$VMUser)
        }
        #Set-Culture $LanguageRegionCode
        $RunScheduledTask_Params.Command = "Set-Culture $LanguageRegionCode"
        RunScheduledTask @RunScheduledTask_Params
        #Set-WinSystemLocale $LanguageRegionCode
        $RunScheduledTask_Params.Command = "Set-WinSystemLocale $LanguageRegionCode"
        RunScheduledTask @RunScheduledTask_Params
        #Set-WinHomeLocation $(Get-GeoId($LanguageRegionCode))
        $GeoID = Get-GeoId($LanguageRegionCode)
        $RunScheduledTask_Params.Command = "Set-WinHomeLocation $GeoID"
        RunScheduledTask @RunScheduledTask_Params
        
        # Find all matching major language inputs
        $LanguageInput = $(
            $LanguageRegionCode # Set Lab langauge as default
            #$languagePacks | Where-Object {$PSItem -match ($LanguageRegionCode.Split('-')[0])} # Add other regions in matching language
            [Globalization.CultureInfo]::GetCultures('AllCultures').Name  | Where-Object {$PSItem -match "^$($LanguageRegionCode.Split('-')[0])-"} # Add other regions in matching language
            "en-US" # Add English as a fall back
        )
        #Set-WinUserLanguageList $LanguageInput -force
        $LanguageInput = $LanguageInput -join ","
        $RunScheduledTask_Params.Command = "Set-WinUserLanguageList ('${LanguageInput}' -split ',') -force -WarningAction SilentlyContinue"
        RunScheduledTask @RunScheduledTask_Params
        RunElevated({New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "Edge" -Force})
        RunElevated({New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "SpellcheckLanguage" -Force})
        New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Force
        RunElevated($({New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "ApplicationLocaleValue" -Value {0}} -f $LanguageRegionCode))
        RunElevated($({New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge\SpellcheckLanguage" -Name 1 -Value {0}} -f $LanguageRegionCode))
        New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Name "ApplicationLocaleValue" -Value $LanguageRegionCode
        New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Edge" -Name "DefinePreferredLanguages" -Value $LanguageRegionCode
        
        # Remove deprecated scheduled task
        if (Get-ScheduledTask -TaskName "Localization" -ErrorAction Ignore)
        {
            RunElevated({Disable-ScheduledTask -TaskName "Localization"})
        }
        # Reboot required
        $Reboot = $true
    }
} 
