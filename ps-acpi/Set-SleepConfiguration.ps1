Function Set-SleepConfiguration {
    <#
    .SYNOPSIS
    Configures sleep-related settings on the system.
    
    .DESCRIPTION
    This function allows you to manage sleep, hibernate, and fast startup settings on your system. It provides options to enable or disable sleep, set a custom sleep timeout, check the current sleep configuration, enable or disable hibernate, and enable fast startup.

    .PARAMETER EnableSleep
    Enables sleep mode with the default timeout.
    .PARAMETER SleepTimeout
    Sets the sleep timeout in seconds. Use with -EnableSleep parameter.
    .PARAMETER DisableSleep
    Disables sleep mode.
    .PARAMETER CheckSleep
    Checks and displays the current sleep settings.
    .PARAMETER EnableHibernate
    Enables hibernate mode.
    .PARAMETER DisableHibernate
    Disables hibernate mode.
    .PARAMETER EnableFastStartup
    Enables fast startup mode.

    .EXAMPLE
    Set-SleepConfiguration -EnableSleep
    Set-SleepConfiguration -DisableSleep

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$EnableSleep,

        [Parameter(Mandatory = $false)]
        [int]$SleepTimeout = 0,

        [Parameter(Mandatory = $false)]
        [switch]$DisableSleep,

        [Parameter(Mandatory = $false)]
        [switch]$CheckSleep,

        [Parameter(Mandatory = $false)]
        [switch]$EnableHibernate,

        [Parameter(Mandatory = $false)]
        [switch]$DisableHibernate,

        [Parameter(Mandatory = $false)]
        [switch]$EnableFastStartup
    )
    if ($EnableSleep) {
        powercfg /change standby-timeout-ac 15
        Write-Host "Sleep enabled with default timeout" -ForegroundColor Cyan
    }
    elseif ($DisableSleep) {
        powercfg /change standby-timeout-ac 0
        Write-Host "Sleep disabled" -ForegroundColor Cyan
    }
    elseif ($SleepTimeout -ne 0) {
        powercfg /change standby-timeout-ac $SleepTimeout
        Write-Host "Sleep timeout set to $SleepTimeout seconds" -ForegroundColor Cyan
    }
    elseif ($CheckSleep) {
        $CurrentSetting = powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String "Power Setting Index"
        if ($CurrentSetting) {
            $CurrentValue = $CurrentSetting -replace '\D'
            $CurrentInfo = powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE | Select-String "Power Setting Index" -Context 0, 2 | ForEach-Object { $_.Context.PostContext -replace '.*:\s+' }
            Write-Host "Current sleep setting: $($CurrentValue) - $($CurrentInfo)" -ForegroundColor Cyan
        }
        else {
            Write-Host "Failed to retrieve current sleep setting" -ForegroundColor Cyan
        }
    }
    elseif ($EnableHibernate) {
        powercfg /hibernate on
        Write-Host "Hibernate enabled" -ForegroundColor Cyan
    }
    elseif ($DisableHibernate) {
        powercfg /hibernate off
        Write-Host "Hibernate disabled" -ForegroundColor Cyan
    }
    elseif ($EnableFastStartup) {
        powercfg /h on
        Write-Host "Fast Startup enabled" -ForegroundColor Cyan
    }
    else {
        Write-Warning -Message "Invalid parameters, use -EnableSleep, -DisableSleep, -SleepTimeout, -CheckSleep, -EnableHibernate, -DisableHibernate, or -EnableFastStartup!"
    }
}
