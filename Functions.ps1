<#
    Enter all functions here to be imported into the session.
    This script will be invoked with no new scope.
#>

Function RunElevated()
{
    Param (
        $ScriptBlock,
        [switch]$Wait
    )
    <#
        This function attempts to create an elevated process to execute the provided script block.
    #>
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell"
    $newProcess.Arguments = $ScriptBlock
    $newProcess.Verb = "runas"
    $Process = [System.Diagnostics.Process]::Start($newProcess)
    If ($Wait)
    {
        while (Get-Process -Id $Process.Id -ErrorAction Ignore)
        {
            Start-Sleep -Milliseconds 300
        }
    }
}

Function RunScheduledTask
{
    Param (
        [string]$Command,
        [string]$User
    )
    <#
        This function attempts to create a scheduled task as the current user to execute the provided script block.
    #>
    $StartProgram = "powershell.exe"
    $Arguments = (
        "-WindowStyle Hidden",
        "-command `"${Command}`""
    ) -join " "

    $action = New-ScheduledTaskAction -Execute $StartProgram -Argument $Arguments
    $RunAsUser = $(
        if ([strng]::IsNullOrWhiteSpace($User)) {whoami}
        else {("${env:USERDOMAIN}",$User) -join "\"}
    )
    $principal = New-ScheduledTaskPrincipal -UserId $RunAsUser
    $settings = New-ScheduledTaskSettingsSet
    $task = New-ScheduledTask -Action $action -Principal $principal -Settings $settings

    $ScheduledTask_Parameters = @{}
    $ScheduledTask_Parameters.Add('TaskName',"ScriptExecute")
    $ScheduledTask_Parameters.Add('InputObject',$task)
    If ($VMCredentials)
    {
        $ScheduledTask_Parameters.Add('User',$VMCredentials.User)
        $ScheduledTask_Parameters.Add('Password',$VMCredentials.Password)
    }

    #$ScheduledTask = Register-ScheduledTask -TaskName "ScriptExecute" -InputObject $task
    $ScheduledTask = Register-ScheduledTask @ScheduledTask_Parameters

    $ScheduledTask | Start-ScheduledTask
    while (-not (($ScheduledTask | Get-ScheduledTaskInfo).LastTaskResult -in 0,1)) {Start-Sleep -Seconds 1}
    if (($ScheduledTask | Get-ScheduledTaskInfo).LastTaskResult -eq 1)
    {Write-Error "Command '$command' ended with error."}
    $ScheduledTask | Unregister-ScheduledTask -Confirm:$false
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
        [string]$AuthToken,

        [Parameter(ParameterSetName = 'Public', Position = 4)]
        [Parameter(ParameterSetName = 'Private', Position = 4)]
        [string]$OutFile
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
        If (-not [string]::IsNullOrWhiteSpace($OutFile))
        {
            $RestMethod_Parameters.Add(
                'OutFile',
                $OutFile
            )
        }
    }
    Else # Private
    {
        $RestMethod_Parameters.Add(
            'URI',
            [System.Web.HttpUtility]::UrlPathEncode("https://api.github.com/repos/${Account}/${Repo}/contents/${FilePath}")
        )
        $RestMethod_Parameters.Add(
            'Headers',
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
        If ([string]::IsNullOrWhiteSpace($OutFile))
        {
            return $Content
        }
    }
    Else
    {
        If ([string]::IsNullOrWhiteSpace($OutFile))
        {
            return [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(($Content.content)))
        }
        Else
        {
            Invoke-WebRequest -Uri $Content.download_url -OutFile $OutFile
        }
    }
}
