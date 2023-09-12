Function Invoke-ACPIAction {
    <#
    .SYNOPSIS
    Performs ACPI actions like Sleep, Hibernate, Shutdown, or Reboot and schedules them if needed.

    .DESCRIPTION
    This function allows you to perform ACPI actions on a Windows computer, such as Sleep, Hibernate, Shutdown, or Reboot.
    You can schedule these actions to run at a specified time and repeat them at defined intervals for a specified duration.

    .PARAMETER Action
    Mandatory - the ACPI action to perform, valid values are "Sleep," "Hibernate," "Shutdown," or "Reboot."
    .PARAMETER DelaySeconds
    NotMandatory - specifies the number of seconds to delay before performing the ACPI action. Default is 0 seconds.
    .PARAMETER Force
    NotMandatory - if specified, forces the ACPI action without prompting for confirmation.
    .PARAMETER ScheduleTime
    NotMandatory - time at which to schedule the ACPI action. Use the format "hh:mm tt" (e.g., "3:00 PM"). The action will run once at this time unless additional scheduling options are specified.
    .PARAMETER RepeatInterval
    NotMandatory - interval (in minutes) at which to repeat the ACPI action. Use in combination with RepeatDuration to repeat the action multiple times. Default is 0 (no repetition).
    .PARAMETER RepeatDuration
    NotMandatory - the total duration (in minutes) for which to repeat the ACPI action at the specified RepeatInterval. Default is 0 (no repetition).
    .PARAMETER TaskName
    NotMandatory - a custom name for the scheduled task. If not provided, a default name is generated based on the selected ACPI action.

    .EXAMPLE
    Invoke-ACPIAction -Action Reboot -ScheduleTime "3:00 PM" -RepeatInterval 60 -RepeatDuration 120 -TaskName "your_ACPT_scheduled_Action"

    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Sleep", "Hibernate", "Shutdown", "Reboot")]
        [string]$Action,

        [Parameter(Mandatory = $false)]
        [int]$DelaySeconds = 0,

        [Parameter(Mandatory = $false)]
        [switch]$Force = $false,

        [Parameter(Mandatory = $false)]
        [string]$ScheduleTime,

        [Parameter(Mandatory = $false)]
        [int]$RepeatInterval = 0,

        [Parameter(Mandatory = $false)]
        [int]$RepeatDuration = 0,

        [Parameter(Mandatory = $false)]
        [string]$TaskName
    )
    try {
        if ($ScheduleTime) {
            $ScriptPath = "$env:TEMP\ACPIActions_$Action.ps1"
            $ScriptContent = @"
Function Invoke-ACPIAction {
    param (
        [string]`$Action,
        [int]`$DelaySeconds = 0,
        [switch]`$Force = `$false
    )
    Write-Host "Performing `$Action action..."
    Start-Sleep -Seconds `$DelaySeconds
    if (`$Action -in "Sleep", "Hibernate") {
        [System.Runtime.InteropServices.Marshal]::LoadLibrary("PowrProf.dll")
        [System.Windows.Forms.Application]::SetSuspendState(`$Action, `$Force, `$Force)
    } elseif (`$Action -eq "Shutdown") {
        Stop-Computer -Force:`$Force
    } elseif (`$Action -eq "Reboot") {
        Restart-Computer -Force:`$Force
    }
}
Invoke-ACPIAction -Action "$Action" -DelaySeconds 0 -Force:`$Force
"@
            $ScriptContent | Out-File -FilePath $ScriptPath -Force
            $RepetitionIntervalSec = $RepeatInterval * 60
            $RepetitionDurationSec = $RepeatDuration * 60
            $TaskTrigger = @()
            $TaskTrigger += New-ScheduledTaskTrigger -At $ScheduleTime -Once
            if ($RepetitionIntervalSec -gt 0 -and $RepetitionDurationSec -gt 0) {
                $NumRepetitions = [math]::Ceiling($RepetitionDurationSec / $RepetitionIntervalSec)
                for ($i = 1; $i -lt $NumRepetitions; $i++) {
                    $RepetitionTime = (Get-Date $ScheduleTime).AddMinutes($i * $RepeatInterval)
                    $TaskTrigger += New-ScheduledTaskTrigger -At $RepetitionTime -Once
                }
            }
            $TaskNameToUse = if ($TaskName) { $TaskName } else { "ACPIAction_$Action" }
            $ActionArgs = "-File '$ScriptPath'"
            Register-ScheduledTask -TaskName $TaskNameToUse -Trigger $TaskTrigger -Action (New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument $ActionArgs)
            Write-Host "Scheduled $Action action to run at $ScheduleTime with TaskName: $TaskNameToUse." -ForegroundColor DarkGreen
        }
        else {
            Write-Host "Performing $Action action..."
            Start-Sleep -Seconds $DelaySeconds
            if ($Action -in "Sleep", "Hibernate") {
                [System.Runtime.InteropServices.Marshal]::LoadLibrary("PowrProf.dll")
                [System.Windows.Forms.Application]::SetSuspendState($Action, $Force, $false)
            }
            elseif ($Action -eq "Shutdown") {
                Stop-Computer -Force:$Force
            }
            elseif ($Action -eq "Reboot") {
                Restart-Computer -Force:$Force
            }
        }
    }
    catch {
        Write-Host "Error: $_"
    }
}
