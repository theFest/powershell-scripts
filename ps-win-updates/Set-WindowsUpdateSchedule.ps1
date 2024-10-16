function Set-WindowsUpdateSchedule {
    <#
    .SYNOPSIS
    Configures the schedule for Windows Updates, including installation time and active hours.

    .DESCRIPTION
    This function allows you to configure Windows Update scheduling settings. You can specify the day of the week and time for updates, set active hours to prevent restarts, and optionally disable automatic rebooting after updates. It supports both local and remote execution, and logs the results of the operation.

    .EXAMPLE
    Set-WindowsUpdateSchedule -Method "COM" -Schedule "Tuesday" -Time "12:00" -ActiveHoursStart "09:00" -ActiveHoursEnd "18:00"
    Set-WindowsUpdateSchedule -Method "ScheduledTask" -Schedule "Everyday" -Time "02:00" -DisableAutoReboot
    Set-WindowsUpdateSchedule -Method "COM" -Schedule "Friday" -Time "15:00" -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -ConfirmAction

    .NOTES
    v0.2.4
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the method for scheduling Windows Updates (COM or ScheduledTask)")]
        [ValidateSet("COM", "ScheduledTask")]
        [string]$Method,

        [Parameter(Mandatory = $true, HelpMessage = "Day of the week for Windows Update installations (or 'Everyday')")]
        [ValidateSet("Everyday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")]
        [string]$Schedule,

        [Parameter(Mandatory = $false, HelpMessage = "Time for Windows Update installations in 24-hour format (HH:mm)")]
        [ValidatePattern("\b([01]?[0-9]|2[0-3]):[0-5][0-9]\b")]
        [string]$Time = "03:00",

        [Parameter(Mandatory = $false, HelpMessage = "Start time for active hours (HH:mm)")]
        [ValidatePattern("\b([01]?[0-9]|2[0-3]):[0-5][0-9]\b")]
        [string]$ActiveHoursStart = "08:00",

        [Parameter(Mandatory = $false, HelpMessage = "End time for active hours (HH:mm)")]
        [ValidatePattern("\b([01]?[0-9]|2[0-3]):[0-5][0-9]\b")]
        [string]$ActiveHoursEnd = "17:00",

        [Parameter(Mandatory = $false, HelpMessage = "Disable automatic reboot after updates")]
        [switch]$DisableAutoReboot,

        [Parameter(Mandatory = $false, HelpMessage = "Name of the remote computer. Defaults to the local machine if not provided")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Username for remote authentication")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for remote authentication")]
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the path to save logs of the operation")]
        [string]$LogPath = "$env:USERPROFILE\Desktop\WindowsUpdateSchedule.log",

        [Parameter(Mandatory = $false, HelpMessage = "Ask for confirmation before applying changes")]
        [switch]$ConfirmAction
    )
    BEGIN {
        if (!(Test-Path -Path $LogPath)) {
            New-Item -ItemType File -Path $LogPath -Force
        }
        $DayOfWeek = switch ($Schedule) {
            "Sunday" { 0 }
            "Monday" { 1 }
            "Tuesday" { 2 }
            "Wednesday" { 3 }
            "Thursday" { 4 }
            "Friday" { 5 }
            "Saturday" { 6 }
            "Everyday" { -1 }
        }
    }
    PROCESS {
        if ($ConfirmAction -and -not $PSCmdlet.ShouldProcess("Windows Update Schedule", "Are you sure you want to apply these settings?")) {
            return
        }
        $SetWindowsUpdateSettings = {
            param (
                [int]$DayOfWeek,
                [string]$Time,
                [string]$ActiveHoursStart,
                [string]$ActiveHoursEnd,
                [switch]$DisableAutoReboot
            )
            try {
                if ($Method -eq "ScheduledTask") {
                    $TaskName = "WindowsUpdateAutoInstall"
                    $TaskTrigger = if ($DayOfWeek -ne -1) {
                        New-ScheduledTaskTrigger -Weekly -DaysOfWeek ([System.DayOfWeek]$DayOfWeek) -At $Time
                    }
                    else {
                        New-ScheduledTaskTrigger -Daily -At $Time
                    }
                    $TaskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command `"wuauclt /updatenow`"" 
                    Register-ScheduledTask -Action $TaskAction -Trigger $TaskTrigger -TaskName $TaskName -Force
                    Write-Host "Scheduled task for Windows Update configured." -ForegroundColor Cyan
                }
                elseif ($Method -eq "COM") {
                    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
                    $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
                    if ($SearchResult.Updates.Count -eq 0) {
                        Write-Host "No updates available." -ForegroundColor Yellow
                    }
                    else {
                        Write-Host "$($SearchResult.Updates.Count) updates found." -ForegroundColor Green
                    }
                }
                $ActiveHoursStart = [int]::Parse($ActiveHoursStart.Split(":")[0])
                $ActiveHoursEnd = [int]::Parse($ActiveHoursEnd.Split(":")[0])
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "ActiveHoursStart" -Value $ActiveHoursStart
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "ActiveHoursEnd" -Value $ActiveHoursEnd
                Write-Host "Active hours set from $ActiveHoursStart to $ActiveHoursEnd."
                if ($DisableAutoReboot) {
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update" -Name "NoAutoRebootWithLoggedOnUsers" -Value 1
                    Write-Host "Automatic reboot after updates is disabled." -ForegroundColor Cyan
                }
                return $true
            }
            catch {
                Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }
        }
        if ($ComputerName -ne $env:COMPUTERNAME) {
            $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential($User, $SecurePassword)
            $Result = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock $SetWindowsUpdateSettings -ArgumentList $DayOfWeek, $Time, $ActiveHoursStart, $ActiveHoursEnd, $DisableAutoReboot
        }
        else {
            $Result = & $SetWindowsUpdateSettings -DayOfWeek $DayOfWeek -Time $Time -ActiveHoursStart $ActiveHoursStart -ActiveHoursEnd $ActiveHoursEnd -DisableAutoReboot $DisableAutoReboot
        }
    }
    END {
        if ($Result -eq $true) {
            Write-Host "Windows Update schedule configured successfully." -ForegroundColor Green
        }
        else {
            Write-Host "Failed to configure Windows Update schedule!" -ForegroundColor DarkRed
        }
    }
}
