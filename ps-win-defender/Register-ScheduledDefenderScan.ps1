Function Register-ScheduledDefenderScan {
    <#
    .SYNOPSIS
    Schedules a Windows Defender scan to run daily at a specified hour.

    .DESCRIPTION
    This function schedules a Windows Defender scan to run either a QuickScan or a FullScan daily at a specified hour of the day.

    .PARAMETER ScanType
    Type of scan to schedule, values are "QuickScan" or "FullScan", default is "QuickScan".
    .PARAMETER HourOfDay
    Hour of the day when the scan should run, default is 2 (2:00 AM).
    .PARAMETER TaskName
    Name of the scheduled task, default is "On-demand scheduled Defender Scan".

    .EXAMPLE
    Register-ScheduledDefenderScan -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Type of scan to schedule")]
        [ValidateSet("QuickScan", "FullScan")]
        [string]$ScanType = "QuickScan",

        [Parameter(Mandatory = $false, HelpMessage = "Hour of the day when the scan should run")]
        [ValidateRange(0, 23)]
        [int]$HourOfDay = 2,

        [Parameter(Mandatory = $false, HelpMessage = "Name of the scheduled task")]
        [string]$TaskName = "On-demand scheduled Defender Scan"
    )
    try {
        Write-Verbose -Message "Creating task action..."
        $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command 'Start-MpScan -ScanType $ScanType'"
        Write-Verbose -Message "Setting trigger time..."
        $TriggerTime = [datetime]::Today.AddHours($HourOfDay)
        $TaskTrigger = New-ScheduledTaskTrigger -Once -At $TriggerTime
        Write-Verbose -Message "Registering scheduled task..."
        Register-ScheduledTask -TaskName $TaskName -Action $TaskAction -Trigger $TaskTrigger -RunLevel Highest -Force -Verbose
        Write-Host "Windows Defender $ScanType scan scheduled daily at ${HourOfDay}:00" -ForegroundColor Green
    }
    catch {
        Write-Error -Message "Error occurred while scheduling Windows Defender scan: $_!"
    }
    finally {
        #Write-Host "Schedule scan time:" (Get-MpPreference).ScanScheduleTime
        Write-Verbose -Message "Scheduled task registration process completed"
    }
}
