Function Invoke-ServiceManager {
    <#
    .SYNOPSIS
    Manages Windows services, allowing various actions such as starting, stopping, restarting, and configuring service properties.

    .DESCRIPTION
    This function provides a range of functionalities to manage Windows services, including starting, stopping, restarting, pausing, continuing, enabling auto-start, disabling auto-start, setting recovery options, retrieving service information, and more.

    .PARAMETER ServiceName
    Specifies the name of the service to manage.
    .PARAMETER Action
    Action to perform, valid actions include: Start, Stop, Restart, Status, Pause, Continue, EnableAutoStart, DisableAutoStart, SetRecovery, GetDescription, GetDependencies, GetLogOnAccount, SetLogOnAccount, GetDisplayName, SetDisplayName, GetStartupType, GetServiceAccountInfo, ListRunningServices, SetRecoveryActions.
    .PARAMETER Force
    Forces the action to be performed without prompting for confirmation.
    .PARAMETER WhatIf
    Simulates the action without actually performing it.
    .PARAMETER RetryCount
    Specifies the number of times to retry the action on failure.
    .PARAMETER RetryDelay
    Specifies the delay in seconds between retry attempts.
    .PARAMETER IncludeLogs
    Specifies whether to include detailed action logs.
    .PARAMETER RestartDelay
    Specifies the delay in seconds before restarting a service during recovery.
    .PARAMETER RecoveryAttempts
    Specifies the number of recovery attempts during service recovery.
    .PARAMETER RecoveryDelay
    Specifies the delay in seconds between recovery attempts.
    .PARAMETER LogOnAccount
    Specifies the account under which the service runs.
    .PARAMETER DisplayName
    Specifies the display name of the service.
    .PARAMETER RecoveryActions
    Specifies specific recovery actions for the service.
    .PARAMETER Command
    Specifies the command to execute during recovery.

    .EXAMPLE
    Invoke-ServiceManager -ServiceName "wuauserv" -Action Start
    Invoke-ServiceManager -ServiceName "wuauserv" -Action SetLogOnAccount -LogOnAccount "NT AUTHORITY\LocalService"
    Invoke-ServiceManager -ServiceName "wuauserv" -Action GetStartupType
    Invoke-ServiceManager -ServiceName "wuauserv" -Action GetServiceAccountInfo
    Invoke-ServiceManager -ServiceName "wuauserv" -Action SetRecoveryActions -RecoveryActions "RestartService" -Command "Restart-Service -Name 'wuauserv'"

    .NOTES
    v0.0.9
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the name of the service")]
        [string]$ServiceName,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the action to perform.")]
        [ValidateSet("Start", "Stop", "Restart", "Status", "Pause", "Continue", "EnableAutoStart", "DisableAutoStart", "SetRecovery", "GetDescription", "GetDependencies", `
                "GetLogOnAccount", "SetLogOnAccount", "GetDisplayName", "SetDisplayName", "GetStartupType", "GetServiceAccountInfo", "ListAllServices", "SetRecoveryActions", "ListRunningServices")]
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
        [int]$RecoveryDelay,

        [Parameter(Mandatory = $false, HelpMessage = "Account under which the service runs")]
        [string]$LogOnAccount,

        [Parameter(Mandatory = $false, HelpMessage = "Display name of the service")]
        [string]$DisplayName,

        [Parameter(Mandatory = $false, HelpMessage = "Specific recovery actions for the service")]
        [string]$RecoveryActions,

        [Parameter(Mandatory = $false, HelpMessage = "Command to execute during recovery")]
        [string]$Command
    )
    $LogFilePath = "$env:TEMP\ServiceManager.log"
    try {
        $Service = Get-Service -Name $ServiceName -ErrorAction Stop
        switch ($Action) {
            "Start" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would start service '$ServiceName'"
                }
                else {
                    $Service | Start-Service -Verbose
                    Write-Output "Service '$ServiceName' has been started."
                }
            }
            "Stop" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would stop service '$ServiceName'"
                }
                else {
                    $Service | Stop-Service -Verbose
                    Write-Output "Service '$ServiceName' has been stopped."
                }
            }
            "Restart" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would restart service '$ServiceName'"
                }
                else {
                    $Service | Restart-Service -Verbose
                    Write-Output "Service '$ServiceName' has been restarted."
                }
            }
            "Status" {
                $Status = $Service.Status
                Write-Output "Service '$ServiceName' is currently $Status."
            }
            "Pause" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would pause service '$ServiceName'"
                }
                else {
                    $Service | Suspend-Service -Verbose
                    Write-Output "Service '$ServiceName' has been paused."
                }
            }
            "Continue" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would continue service '$ServiceName'"
                }
                else {
                    $Service | Resume-Service -Verbose
                    Write-Output "Service '$ServiceName' has been continued."
                }
            }
            "EnableAutoStart" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would enable auto-start for service '$ServiceName'"
                }
                else {
                    Set-Service -Name $ServiceName -StartupType Automatic -Verbose
                    Write-Output "Auto-start has been enabled for service '$ServiceName'"
                }
            }
            "DisableAutoStart" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would disable auto-start for service '$ServiceName'"
                }
                else {
                    Set-Service -Name $ServiceName -StartupType Disabled -Verbose
                    Write-Output "Auto-start has been disabled for service '$ServiceName'"
                }
            }
            "SetRecovery" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would set recovery options for service '$ServiceName'"
                }
                else {
                    $RecoveryOptions = New-ServiceRecoveryOptions -RestartService -ResetPeriod $RestartDelay -DaysToRestart $RecoveryAttempts -RestartWait $RecoveryDelay
                    Set-Service -Name $ServiceName -Recovery $RecoveryOptions -Verbose
                    Write-Output "Recovery options have been set for service '$ServiceName'"
                }
            }
            "GetDescription" {
                $Description = $Service.Description
                Write-Output "Description of service '$ServiceName': $Description"
            }
            "GetDependencies" {
                $Dependencies = $Service.DependentServices
                $DependencyNames = $Dependencies | ForEach-Object { $_.DisplayName }
                Write-Output "Dependencies of service '$ServiceName': $($DependencyNames -join ', ')"
            }
            "GetLogOnAccount" {
                $Account = Get-WmiObject Win32_Service | Where-Object { $_.Name -eq $ServiceName } | Select-Object -ExpandProperty StartName
                Write-Output "Service '$ServiceName' runs under account: $Account"
            }
            "SetLogOnAccount" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would set log-on account for service '$ServiceName' to '$LogOnAccount'"
                }
                else {
                    $Service | Set-ServiceLogOnAccount -Account $LogOnAccount -Verbose
                    Write-Output "Log-on account for service '$ServiceName' has been set to '$LogOnAccount'"
                }
            }
            "GetDisplayName" {
                $DisplayName = $Service.DisplayName
                Write-Output "Display name of service '$ServiceName': $DisplayName"
            }
            "SetDisplayName" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would set display name for service '$ServiceName' to '$DisplayName'"
                }
                else {
                    $Service | Set-Service -DisplayName $DisplayName -Verbose
                    Write-Output "Display name for service '$ServiceName' has been set to '$DisplayName'"
                }
            }
            "GetStartupType" {
                $StartupType = $Service.StartType
                Write-Output "Startup type of service '$ServiceName': $StartupType"
            }
            "GetServiceAccountInfo" {
                $AccountInfo = Get-WmiObject Win32_Service | Where-Object { $_.Name -eq $ServiceName }
                $AccountName = $AccountInfo.StartName
                $AccountDomain = $AccountInfo.StartName.Split("\")[0]
                $AccountSID = $AccountInfo.StartNameSid
                Write-Output "Account information for service '$ServiceName':"
                Write-Output "Account Name: $AccountName"
                Write-Output "Account Domain: $AccountDomain"
                Write-Output "Account SID: $AccountSID"
            }
            "ListRunningServices" {
                $RunningServices = Get-Service | Where-Object { $_.Status -eq 'Running' }
                $RunningServiceInfo = $RunningServices | Select-Object DisplayName, Status
                Write-Output "List of running services:"
                $RunningServiceInfo | Format-Table -AutoSize
            }
            "SetRecoveryActions" {
                if ($WhatIf) {
                    Write-Output "Simulating: Would set recovery actions for service '$ServiceName'"
                }
                else {
                    $RecoveryOptions = New-ServiceRecoveryOptions -Action $RecoveryActions -Command $Command
                    Set-Service -Name $ServiceName -Recovery $RecoveryOptions -Verbose
                    Write-Output "Recovery actions have been set for service '$ServiceName'."
                }
            }
        }
        if ($IncludeLogs) {
            $LogMessage = "Performed action: $Action on service '$ServiceName'"
            Write-Output -InputObject $LogMessage
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
        $ErrorMessage | Out-File -Append -FilePath $LogFilePath
    }
}
