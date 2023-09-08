Function Invoke-ACPIAction {
    <#
    .SYNOPSIS
    Performs ACPI-related actions such as Sleep, Hibernate, Shutdown, Reboot, and retrieves power and battery information.

    .DESCRIPTION
    The Invoke-ACPIAction function allows you to perform various ACPI-related actions on your computer in C#.
    
    .PARAMETER Action
    Mandatory - the ACPI action to perform. Valid values are "Sleep," "Hibernate," "Shutdown," "Reboot," "QueryPowerStatus," and "BatteryInfo."
    .PARAMETER DelaySeconds
    NotMandatory - specifies an optional delay (in seconds) before executing the ACPI action, the default is 0 seconds.
    .PARAMETER Force
    NotMandatory - specifies whether to force the ACPI action, especially useful for Shutdown and Reboot. By default, actions are not forced.
    .PARAMETER ScheduleTime
    NotMandatory - specifies a time at which to schedule the ACPI action. If provided, the action will be scheduled to run at the specified time.
    .PARAMETER RepeatInterval
    NotMandatory - specifies the interval (in minutes) at which the scheduled task should repeat.
    .PARAMETER RepeatDuration
    NotMandatory - specifies the duration (in minutes) for which the scheduled task should repeat.
    .PARAMETER TaskName
    NotMandatory - specifies a custom name for the scheduled task.

    .EXAMPLE
    Invoke-ACPIAction -Action Shutdown -ScheduleTime "3:00 PM" -RepeatInterval 60 -RepeatDuration 120 -TaskName "MyShutdownTask"

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Sleep", "Hibernate", "Shutdown", "Reboot", "QueryPowerStatus", "BatteryInfo")]
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
            $TaskAction = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "Invoke-ACPIAction -Action $Action -DelaySeconds $DelaySeconds -Force:$Force"
            $TaskTrigger = New-ScheduledTaskTrigger -At $ScheduleTime -Once
            if ($RepeatInterval -gt 0 -and $RepeatDuration -gt 0) {
                $TaskTrigger.RepetitionInterval = [TimeSpan]::FromMinutes($RepeatInterval)
                $TaskTrigger.RepetitionDuration = [TimeSpan]::FromMinutes($RepeatDuration)
            }
            Register-ScheduledTask -TaskName ($TaskName -or "ACPIAction_$Action") -Action $TaskAction -Trigger $TaskTrigger
            Write-Host "Scheduled $Action action to run at $ScheduleTime." -ForegroundColor DarkGreen
        }
        else {
            switch ($Action) {
                "Sleep" {
                    Write-Host "Putting the computer to sleep..."
                    Start-Sleep -Seconds $DelaySeconds
                    Invoke-ACPIAction -Action "QueryPowerStatus"
                    Add-Type -TypeDefinition @"
                        using System;
                        using System.Runtime.InteropServices;
                        public class Win32Power {
                            [DllImport("PowrProf.dll", SetLastError = true)]
                            public static extern bool SetSuspendState(bool hibernate, bool forceCritical, bool disableWakeEvent);
                        }
"@
                    [Win32Power]::SetSuspendState($false, $Force, $false)
                }
                "Hibernate" {
                    Write-Host "Hibernating the computer..."
                    Start-Sleep -Seconds $DelaySeconds
                    Invoke-ACPIAction -Action "QueryPowerStatus"
                    Add-Type -TypeDefinition @"
                        using System;
                        using System.Runtime.InteropServices;
                        public class Win32Power {
                            [DllImport("PowrProf.dll", SetLastError = true)]
                            public static extern bool SetSuspendState(bool hibernate, bool forceCritical, bool disableWakeEvent);
                        }
"@
                    [Win32Power]::SetSuspendState($true, $Force, $false)
                }
                "Shutdown" {
                    $Message = "Shutting down the computer"
                    if ($Force) {
                        $Message += " forcefully"
                    }
                    Write-Host "$Message..."
                    Start-Sleep -Seconds $DelaySeconds
                    Invoke-ACPIAction -Action "QueryPowerStatus"
                    Stop-Computer -Force:$Force
                }
                "Reboot" {
                    $Message = "Rebooting the computer"
                    if ($Force) {
                        $Message += " forcefully"
                    }
                    Write-Host "$Message..."
                    Start-Sleep -Seconds $DelaySeconds
                    Invoke-ACPIAction -Action "QueryPowerStatus"
                    Restart-Computer -Force:$Force
                }
                "QueryPowerStatus" {
                    $BatteryInfo = Get-WmiObject -Class Win32_Battery
                    $PowerStatus = if ($BatteryInfo.BatteryStatus -eq 2) { "Battery" } else { "AC" }
                    Write-Host "Power Status: $PowerStatus"
                }
                "BatteryInfo" {
                    $BatteryInfo = Get-WmiObject -Class Win32_Battery
                    Write-Host "Battery Status: $($BatteryInfo.BatteryStatus)"
                    Write-Host "Battery Capacity: $($BatteryInfo.EstimatedChargeRemaining)%"
                    Write-Host "Battery Voltage: $($BatteryInfo.DesignVoltage)mV"
                }
                default {
                    throw "Unsupported ACPI action: $Action"
                }
            }
        }
    }
    catch {
        Write-Host "Error: $_"
    }
}
