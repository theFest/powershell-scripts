Function Invoke-RebootAndResumeScript {
    <#
    .SYNOPSIS
    Restarts the computer and resumes the execution of a PowerShell script after the restart.

    .DESCRIPTION
    This function restarts the computer and, upon restart, resumes the execution of a specified PowerShell script. It also supports registering the script as a scheduled task to run after the computer restarts.

    .PARAMETER ScriptPath
    Path to the PowerShell script that should be executed after the computer restarts. Script path must point to an existing file.
    .PARAMETER ScheduledTaskStart
    Specifies when the scheduled task should start, values are "OnStart" (default), "AtLogon", or "OnIdle".
    .PARAMETER WaitTime
    Time, in seconds, to wait after the computer restarts before resuming script execution, default value is 5 seconds.
    .PARAMETER TaskName
    Name of the scheduled task that will run the script after restart, default task name is "RebootAndResumeScript".
    .PARAMETER LogPath
    Path to the log file where execution details are recorded, default log path is "C:\Logs\RebootAndResumeScript.log". The log path must point to an existing directory.
    .PARAMETER WriteEventLog
    Type of event log entry to be written after script execution, values are "Success" (default), "Error", or "Warning".

    .EXAMPLE
    Invoke-RebootAndResumeScript -ScriptPath "C:\Path\To\YourScript.ps1" -ScheduledTaskStart OnStart -WaitTime 10 -TaskName "MyTask" -LogPath "D:\Logs\MyScriptLog.log" -WriteEventLog Error

    .NOTES
    v0.0.8
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "The path to the PowerShell script to be executed after reboot")]
        [ValidateScript({
                if (-Not (Test-Path $_ -PathType "Leaf")) {
                    throw "The specified script path '$_' does not exist or is not a file!"
                }
                $true
            })]
        [string]$ScriptPath,

        [Parameter(Mandatory = $false, HelpMessage = "Specify when the scheduled task should start")]
        [ValidateSet("OnStart", "AtLogon", "OnIdle")]
        [string]$ScheduledTaskStart = "OnStart",

        [Parameter(Mandatory = $false, HelpMessage = "The time, in seconds, to wait after the computer restarts")]
        [int]$WaitTime = 5,

        [Parameter(Mandatory = $false, HelpMessage = "The name of the scheduled task")]
        [string]$TaskName = "RebootAndResumeScript",

        [Parameter(Mandatory = $false, HelpMessage = "The path to the log file")]
        [string]$LogPath = "C:\Logs\RebootAndResumeScript.log",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the type of event log entry")]
        [ValidateSet("Success", "Error", "Warning")]
        [string]$WriteEventLog = "Success"
    )
    try {
        $ErrorActionPreference = "Stop"
        Write-Verbose -Message "Registering a scheduled task if specified"
        if ($ScheduledTaskStart) {
            Write-Host "Creating the task action to run the script after restart" -ForegroundColor Yellow
            $TaskAction = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
            Write-Verbose -Message "Determine the appropriate trigger for the task start time..."
            $TaskTrigger = switch ($ScheduledTaskStart) {
                "OnStart" { New-ScheduledTaskTrigger -AtStartup }
                "AtLogon" { New-ScheduledTaskTrigger -AtLogOn }
                "OnIdle" { New-ScheduledTaskTrigger -AtIdle }
            }
            Write-Verbose -Message "Registering the scheduled task..."
            Register-ScheduledTask -TaskName $TaskName -Trigger $TaskTrigger -Action $TaskAction -User "NT AUTHORITY\SYSTEM" -Force -Verbose
        }
        Add-Content -Path $LogPath -Value "Starting script execution: $(Get-Date)" -Verbose
        Write-Verbose -Message "Initiating a restart and proceeding without waiting"
        Restart-Computer -Force
        Write-Verbose -Message "Sleep for the specified time after restart"
        Start-Sleep -Seconds $WaitTime
        Add-Content -Path $LogPath -Value "Resuming script execution: $(Get-Date)" -Verbose
        & $ScriptPath
        Add-Content -Path $LogPath -Value "Script resumed successfully: $(Get-Date)" -Verbose
        Add-Content -Path $LogPath -Value "End of script execution: $(Get-Date)" -Verbose
        if ($WriteEventLog) {
            $LogFileContent = Get-Content -Path $LogPath -Raw
            Write-EventLog -LogName Application -Source 'RebootAndResumeScript' -EntryType $WriteEventLog -Message $LogFileContent
        }
        Write-Host "Reboot and resume script successful" -ForegroundColor Green
    }
    catch {
        Write-Error -Message "Error in function Invoke-RebootAndResumeScript: $($_.Exception.Message)"
        Add-Content -Path $LogPath -Value "Error: $(Get-Date) - $_" -Verbose
    }
}
