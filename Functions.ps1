<#
    Enter all functions here to be imported into the session.
    This script will be invoked with no new scope.
#>

Function RunElevated($ScriptBLock)
{
    <#
        This function attempts to create an elevated process to execute the provided script block.
    #>
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell"
    $newProcess.Arguments = $ScriptBlock
    $newProcess.Verb = "runas"
    [void][System.Diagnostics.Process]::Start($newProcess)
}

Function Get-GeoId($Name='*')
{
    $cultures = [System.Globalization.CultureInfo]::GetCultures('InstalledWin32Cultures') #| Out-GridView
     foreach($culture in $cultures)
    {
       try{
           $region = [System.Globalization.RegionInfo]$culture.Name
           #Write-Host "00 :"$Name "|" $region.DisplayName "|" $region.Name "|" $region.GeoId "|" $region.EnglishName "|" $culture.LCID
           if($region.Name -like $Name)
           {
                $region.GeoId
           }
       }
       catch {}
    }
}

Function Get-GitHubContents
{
    [CmdletBinding(DefaultParameterSetName = 'Public')]
    Param (
        [Parameter(Mandatory, ParameterSetName = 'Public', Position = 0)]
        [Parameter(Mandatory, ParameterSetName = 'Private', Position = 0)]
        [string]$Account,

        [Parameter(Mandatory, ParameterSetName = 'Public', Position = 1)]
        [Parameter(Mandatory, ParameterSetName = 'Private', Position = 1)]
        [string]$Repo,

        [Parameter(Mandatory, ParameterSetName = 'Public', Position = 2)]
        [Parameter(Mandatory, ParameterSetName = 'Private', Position = 2)]
        [string]$FilePath,

        [Parameter(ParameterSetName = 'Private', Position = 3)]
        [string]$AuthToken
    )
    If ([string]::IsNullOrWhiteSpace($AuthToken)) {
        Write-Verbose "Parameter Set: Public" -Verbose:(&{switch($args){"Continue"{$true};default{$false}}}($VerbosePreference))
        $Public = $true
    }
    else
    {
        Write-Verbose "Parameter Set: Private" -Verbose:(&{switch($args){"Continue"{$true};default{$false}}}($VerbosePreference))
    }
    Add-Type -AssemblyName System.Web
    $RestMethod_Parameters = @{}
    $RestMethod_Parameters.Add('Method','Get')
    $RestMethod_Parameters.Add('UseBasicParsing',$true)
    If ($Public)
    {
        $RestMethod_Parameters.Add(
            'URI',
            [System.Web.HttpUtility]::UrlPathEncode("https://raw.githubusercontent.com/${Account}/${Repo}/main/${FilePath}")
        )
    }
    Else # Private
    {
        $RestMethod_Parameters.Add(
            'URI',
            [System.Web.HttpUtility]::UrlPathEncode("https://api.github.com/repos/${Account}/${Repo}/contents/${FilePath}")
        )
        $RestMethod_Parameters.Add(
            'Header',
            @{
                Accept = "application/vnd.github+json"
                Authorization = "Bearer ${AuthToken}"
                "X-GitHub-Api-Version" = "2022-11-28"
            }
        )
    }
    Write-Verbose "RestMethod_Parameters:`n$($RestMethod_Parameters | ConvertTo-Json | Out-String)" -Verbose:(&{switch($args){"Continue"{$true};default{$false}}}($VerbosePreference))
    $Content = Invoke-RestMethod @RestMethod_Parameters
    If ($Public)
    {
        return $Content
    }
    Else
    {
        return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($Content.content)))
    }
}
