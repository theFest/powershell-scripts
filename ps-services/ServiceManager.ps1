Function ServiceManager {
    <#
    .SYNOPSIS
    Perform various operations on Windows services.

    .DESCRIPTION
    This function allows you to perform different operations on Windows services, such as starting, stopping, restarting, pausing, continuing, enabling or disabling auto-start, setting recovery options, and more.

    .PARAMETER ServiceName
    Mandatory - specifies the name of the Windows service to be managed.
    .PARAMETER Action
    Mandatory - specifies the action to perform on the service. Valid values include:
    - Start
    - Stop
    - Restart
    - Status
    - Pause
    - Continue
    - EnableAutoStart
    - DisableAutoStart
    - SetRecovery
    .PARAMETER Force
    NotMandatory - forces the specified action, even if it may result in unintended consequences.
    .PARAMETER WhatIf
    NotMandatory - simulates the action without actually performing it, providing a preview of the outcome.
    .PARAMETER RetryCount
    NotMandatory - the number of times to retry the action in case of failure.
    .PARAMETER RetryDelay
    NotMandatory - specifies the delay in seconds between retry attempts.
    .PARAMETER IncludeLogs
    NotMandatory - includes detailed action logs in the output.
    .PARAMETER RestartDelay
    NotMandatory - the delay in seconds before restarting a service during recovery.
    .PARAMETER RecoveryAttempts
    NotMandatory - the number of recovery attempts during service recovery.
    .PARAMETER RecoveryDelay
    NotMandatory - the delay in seconds between recovery attempts.

    .EXAMPLE
    ServiceManager -ServiceName "wuauserv" -Action "Start"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the name of the service")]
        [string]$ServiceName,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the action to perform.")]
        [ValidateSet("Start", "Stop", "Restart", "Status", "Pause", "Continue", "EnableAutoStart", "DisableAutoStart", "SetRecovery")]
        [string]$Action,

        [Parameter(Mandatory = $false, HelpMessage = "Forcefully perform actions")]
        [switch]$Force,

        [Parameter(Mandatory = $false, HelpMessage = "Simulate the action without performing it")]
        [switch]$WhatIf,

        [Parameter(Mandatory = $false, HelpMessage = "Number of times to retry the action on failure")]
        [int]$RetryCount,

        [Parameter(Mandatory = $false, HelpMessage = "Delay in seconds between retry attempts")]
        [int]$RetryDelay,

        [Parameter(Mandatory = $false, HelpMessage = "Include detailed action logs")]
        [switch]$IncludeLogs,

        [Parameter(Mandatory = $false, HelpMessage = "Delay in seconds before restarting a service during recovery")]
        [int]$RestartDelay,

        [Parameter(Mandatory = $false, HelpMessage = "Number of recovery attempts during service recovery")]
        [int]$RecoveryAttempts,

        [Parameter(Mandatory = $false, HelpMessage = "Delay in seconds between recovery attempts")]
        [int]$RecoveryDelay
    )
    try {
        $Service = Get-Service -Name $ServiceName -ErrorAction Stop
        switch ($Action) {
            "Start" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would start service '$ServiceName'."
                }
                else {
                    $Service | Start-Service
                    Write-Output "Service '$ServiceName' has been started."
                }
            }
            "Stop" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would stop service '$ServiceName'."
                }
                else {
                    $Service | Stop-Service
                    Write-Output "Service '$ServiceName' has been stopped."
                }
            }
            "Restart" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would restart service '$ServiceName'."
                }
                else {
                    $Service | Restart-Service
                    Write-Output "Service '$ServiceName' has been restarted."
                }
            }
            "Status" {
                $Status = $Service.Status
                Write-Output "Service '$ServiceName' is currently $Status."
            }
            "Pause" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would pause service '$ServiceName'."
                }
                else {
                    $Service | Suspend-Service
                    Write-Output "Service '$ServiceName' has been paused."
                }
            }
            "Continue" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would continue service '$ServiceName'."
                }
                else {
                    $service | Resume-Service
                    Write-Output "Service '$ServiceName' has been continued."
                }
            }
            "EnableAutoStart" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would enable auto-start for service '$ServiceName'."
                }
                else {
                    Set-Service -Name $ServiceName -StartupType Automatic
                    Write-Output "Auto-start has been enabled for service '$ServiceName'."
                }
            }
            "DisableAutoStart" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would disable auto-start for service '$ServiceName'."
                }
                else {
                    Set-Service -Name $ServiceName -StartupType Disabled
                    Write-Output "Auto-start has been disabled for service '$ServiceName'."
                }
            }
            "SetRecovery" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would set recovery options for service '$ServiceName'."
                }
                else {
                    $RecoveryOptions = New-ServiceRecoveryOptions -RestartService -ResetPeriod $RestartDelay -DaysToRestart $RecoveryAttempts -RestartWait $RecoveryDelay
                    Set-Service -Name $ServiceName -Recovery $RecoveryOptions
                    Write-Output "Recovery options have been set for service '$ServiceName'."
                }
            }
        }
        if ($IncludeLogs) {
            $LogMessage = "Performed action: $Action on service '$ServiceName'"
            Write-Output $LogMessage
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
}