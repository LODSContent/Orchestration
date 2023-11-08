<#
   This script is the first to be pulled down.
#>

# Required variables
#   $Bootstrap_Params = @{
#      Scripts = @{
#         "0" = "Scriptname"
#      }
#      PostAction = {shutdown -r -t 5}
#   }

if (-not (Get-Variable -name Bootstrap_Params -ErrorAction Ignore))
{
  Write-Error "Required Variable missing: 'Bootstrap_Params'"
}

# Import functions
#$Account = 'GlenHess'
#$Repo = 'TestScripts'
$ScriptPath = 'Functions.ps1'

$Content = Get-GitHubContents $Account $Repo $ScriptPath $GitHubAuthToken

Invoke-Command -ScriptBlock $([scriptblock]::Create($content)) -NoNewScope

# Get Script list
$Scripts_List = Get-GitHubContents $Account $Repo "Scripts.json" $GitHubAuthToken

try {
   # Execute scripts in order
   $Bootstrap_Params.Scripts.Keys | Sort-Object | Foreach-Object {
       $ScriptName = $Bootstrap_Params.Scripts."$PSItem"
       $ScriptItem = $Scripts_List | Where-Object {$PSItem.Name -eq $ScriptName}
       if ($null -ne $ScriptItem)
       {
           $ScriptContent = Get-GitHubContents $Account $Repo $ScriptItem.Path
           Write-Host "Executing Script: '${ScriptName}'"
           Invoke-Command -ScriptBlock $([scriptblock]::Create($ScriptContent)) -NoNewScope
           Write-Host "Completed Executing Script: '${ScriptName}'"
       }
       else {
           Write-Error "Script: '${ScriptName}' not found"
       }
   }

   # Execute Post Action
   Invoke-Command -ScriptBlock $Bootstrap_Params.PostAction -NoNewScope
} catch {
   $ErrorMessage = "[Script failure]: " | Out-String
   $PSItem | Foreach-Object {$ErrorMessage += "$($PSItem.Exception.Message); " | Out-String}
   throw($ErrorMessage)
}
