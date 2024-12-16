function Set-SleepConfiguration {
    <#
    .SYNOPSIS
    Configures sleep, hibernate, and fast startup settings on the system.

    .DESCRIPTION
    This function allows you to manage power settings such as sleep, hibernate, and fast startup modes. It provides options to enable or disable sleep, configure custom sleep timeouts, check current sleep settings, enable or disable hibernate, and enable fast startup for faster boot times.

    .EXAMPLE
    Set-SleepConfiguration -EnableSleep
    Set-SleepConfiguration -SleepTimeout 300 -EnableSleep
    Set-SleepConfiguration -DisableSleep
    Set-SleepConfiguration -CheckSleep
    Set-SleepConfiguration -EnableHibernate
    Set-SleepConfiguration -DisableHibernate
    Set-SleepConfiguration -EnableFastStartup

    .NOTES
    Version: 0.1.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Enables sleep mode with a default or specified timeout. Use this to configure the system's sleep functionality")]
        [switch]$EnableSleep,

        [Parameter(Mandatory = $false, HelpMessage = "Specifies the sleep timeout in seconds. Must be a positive integer and used with -EnableSleep")]
        [int]$SleepTimeout,

        [Parameter(Mandatory = $false, HelpMessage = "Disables sleep mode entirely, preventing the system from entering sleep mode")]
        [switch]$DisableSleep,

        [Parameter(Mandatory = $false, HelpMessage = "Displays the current sleep settings, including timeouts for AC (plugged-in) and DC (battery) power modes")]
        [switch]$CheckSleep,

        [Parameter(Mandatory = $false, HelpMessage = "Enables hibernate mode, which saves the system state to disk and powers off to conserve energy")]
        [switch]$EnableHibernate,

        [Parameter(Mandatory = $false, HelpMessage = "Disables hibernate mode and deletes the hibernate file to free up disk space")]
        [switch]$DisableHibernate,

        [Parameter(Mandatory = $false, HelpMessage = "Enables fast startup, a hybrid feature that speeds up boot times by combining hibernate and shutdown behaviors")]
        [switch]$EnableFastStartup
    )
    try {
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            throw "This function requires administrative privileges. Please run PowerShell as an administrator."
        }
        if ($EnableSleep -and $DisableSleep) {
            throw "You cannot use -EnableSleep and -DisableSleep together!"
        }
        if ($EnableSleep -and $SleepTimeout -le 0) {
            throw "When using -SleepTimeout with -EnableSleep, specify a positive timeout value in seconds!"
        }
        if ($EnableSleep) {
            $Timeout = if ($SleepTimeout -gt 0) { $SleepTimeout } else { 900 }
            powercfg /change standby-timeout-ac $Timeout
            powercfg /change standby-timeout-dc $Timeout
            Write-Host "Sleep enabled with a timeout of $Timeout seconds." -ForegroundColor Cyan
        }
        if ($DisableSleep) {
            powercfg /change standby-timeout-ac 0
            powercfg /change standby-timeout-dc 0
            Write-Host "Sleep mode disabled." -ForegroundColor Cyan
        }
        if ($CheckSleep) {
            $CurrentSettingAC = powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String "(AC)" | ForEach-Object { $_ -replace '.*:\s+', '' }
            $CurrentSettingDC = powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String "(DC)" | ForEach-Object { $_ -replace '.*:\s+', '' }
            Write-Host "Current sleep timeout (AC): $CurrentSettingAC seconds" -ForegroundColor Cyan
            Write-Host "Current sleep timeout (DC): $CurrentSettingDC seconds" -ForegroundColor Cyan
        }
        if ($EnableHibernate) {
            powercfg /hibernate on
            Write-Host "Hibernate mode enabled." -ForegroundColor Cyan
        }
        if ($DisableHibernate) {
            powercfg /hibernate off
            Write-Host "Hibernate mode disabled." -ForegroundColor Cyan
        }
        if ($EnableFastStartup) {
            powercfg /h on
            Write-Host "Fast startup enabled." -ForegroundColor Cyan
        }
    }
    catch {
        Write-Error "An error occurred: $_"
    }
}
