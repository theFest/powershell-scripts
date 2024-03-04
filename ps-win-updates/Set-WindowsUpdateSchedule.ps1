Function Set-WindowsUpdateSchedule {
    <#
    .SYNOPSIS
    Sets the Windows Update schedule.

    .DESCRIPTION
    This function allows you to set the Windows Update schedule by specifying the desired day of the week.

    .PARAMETER Schedule
    Specifies the day of the week for the Windows Update schedule.

    .EXAMPLE
    Set-WindowsUpdateSchedule -Schedule "Everyday"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Everyday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")]
        [string]$Schedule
    )
    $AutomaticUpdates = New-Object -ComObject Microsoft.Update.AutoUpdate
    $DayOfWeek = switch ($Schedule) {
        "Everyday" { 0 }
        "Sunday" { 1 }
        "Monday" { 2 }
        "Tuesday" { 3 }
        "Wednesday" { 4 }
        "Thursday" { 5 }
        "Friday" { 6 }
        "Saturday" { 7 }
    }
    if ($null -eq $DayOfWeek) {
        throw "Invalid schedule, provide a valid schedule: Everyday, Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday."
    }
    $AutomaticUpdates.Settings.ScheduledInstallationDay = $DayOfWeek
    $AutomaticUpdates.Settings.Save()
    Write-Host "Windows Update schedule set to $Schedule" -ForegroundColor Green
}
