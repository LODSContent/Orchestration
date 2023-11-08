<#
    This script is to correct the time sync in a Virtual Machine.
#>

# Functions used:
#   RunElevated

RunElevated({
sc.exe triggerinfo w32time delete
sc.exe config w32time start=auto
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config" -Name "MaxNegPhaseCorrection" -Value 172800
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config" -Name "MaxPosPhaseCorrection" -Value 172800
Restart-Service W32Time
w32tm /resync
})
