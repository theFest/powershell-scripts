function Invoke-RebootAndResumeScript {
    <#
    .SYNOPSIS
    Initiates a computer restart and resumes script execution after restart.
    
    .DESCRIPTION
    This function restarts the local computer and resumes the execution of a specified PowerShell script after the restart. It can optionally create a scheduled task to run the script at different startup times.
    
    .PARAMETER ScriptPath
    Mandatory - path to the PowerShell script that will be resumed after the computer restart.
    .PARAMETER ScheduledTaskStart
    NotMandatory - pecifies when the scheduled task should start: 'OnStart', 'AtLogon', or 'OnIdle'.
    .PARAMETER WaitTime
    NotMandatory - amount of time to wait (in seconds) after the restart before resuming the script execution.
    .PARAMETER TaskName
    NotMandatory - name of the scheduled task to be created (if ScheduledTaskStart is specified).
    .PARAMETER LogPath
    NotMandatory - the path to the log file where execution details will be recorded.
    .PARAMETER WriteEventLog
    NotMandatory - type of event log entry to write after the script execution: 'Success', 'Error', or 'Warning'.
    
    .EXAMPLE
    Invoke-RebootAndResumeScript -ScriptPath "C:\Temp\you_ps_script.ps1" -ScheduledTaskStart OnStart -Verbose
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ 
                Test-Path $_ -PathType "Leaf" 
            })]
        [String]$ScriptPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("OnStart", "AtLogon", "OnIdle")]
        [String]$ScheduledTaskStart = "OnStart",

        [Parameter(Mandatory = $false)]
        [Int]$WaitTime = 5,

        [Parameter(Mandatory = $false)]
        [String]$TaskName = "RebootAndResumeScript",

        [Parameter(Mandatory = $false)]
        [String]$LogPath = "C:\Logs\RebootAndResumeScript.log",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Success", "Error", "Warning")]
        [String]$WriteEventLog = "Success"
    )
    try {
        $ErrorActionPreference = "Stop"
        Write-Verbose -Message "Registering a scheduled task if specified"
        if ($ScheduledTaskStart) {
            Write-Host "Creating the task action to run the script after restart" -ForegroundColor Yellow
            $TaskAction = New-ScheduledTaskAction -Execute "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
            Write-Verbose -Message "Determine the appropriate trigger for the task start time..."
            switch ($ScheduledTaskStart) {
                'OnStart' { 
                    $TaskTrigger = New-ScheduledTaskTrigger -AtStartup 
                }
                'AtLogon' { 
                    $TaskTrigger = New-ScheduledTaskTrigger -AtLogOn 
                }
                'OnIdle' { 
                    $TaskTrigger = New-ScheduledTaskTrigger -AtIdle 
                }
            }
            Write-Verbose -Message "Registering the scheduled task..."
            Register-ScheduledTask -TaskName $TaskName -Trigger $TaskTrigger -Action $TaskAction -User "NT AUTHORITY\SYSTEM" -Force -Verbose
        }
        Add-Content -Path $LogPath -Value "Starting script execution: $(Get-Date)" -Verbose
        Write-Verbose -Message "Initiating a restart and proceed without waiting"
        Restart-Computer
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
        Write-Host "Reboot and resume script successful." -ForegroundColor Green
    }
    catch {
        $ErrorMessage = "Error in function Invoke-RebootAndResumeScript: $($_.Exception.Message)"
        Write-Error -Exception "$ErrorMessage"
        Add-Content -Path $LogPath -Value "Error: $(Get-Date) - $ErrorMessage" -Verbose
    }
    finally {
        $ErrorActionPreference = "Continue"
    }
}
