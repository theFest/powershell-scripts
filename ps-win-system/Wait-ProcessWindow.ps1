Function Wait-ProcessWindow {
    <#
    .SYNOPSIS
    Waits for the main window of a specified process to open within a specified timeout period.

    .DESCRIPTION
    This function waits for the main window of a specified process to open within a specified timeout period. It continuously checks whether the process is running and if its main window is open. Optionally, it can terminate the process if the main window does not open within the specified timeout.

    .PARAMETER ProcessName
    Name of the process to monitor for its main window. You can specify multiple process names.
    .PARAMETER Timeout
    Maximum time, in seconds, to wait for the process main window to open.
    .PARAMETER CheckInterval
    Interval, in seconds, between each check for the process main window. Default is 1 second.
    .PARAMETER WaitForWindow
    Wait for the process main window to open. If not specified, the function waits for the process to start but does not wait for its main window to open.
    .PARAMETER KillOnTimeout
    Terminate the process if its main window does not open within the specified timeout period.
    .PARAMETER LogFile
    Path to a log file where execution details will be logged.

    .EXAMPLE
    Wait-ProcessWindow -ProcessName "notepad" -Timeout 60 -WaitForWindow

    .NOTES
    v0.2.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the name of the process to monitor")]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $_ -match '^[\w.-]+$' })]
        [string[]]$ProcessName,
    
        [Parameter(Mandatory = $true, HelpMessage = "Maximum time, in seconds, to wait for the process main window to open")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$Timeout,
    
        [Parameter(Mandatory = $false, HelpMessage = "Interval, in seconds, between each check for the process main window. Default is 1 second")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$CheckInterval = 1,
    
        [Parameter(Mandatory = $false, HelpMessage = "Wait for the process main window to open. If not specified, the function waits for the process to start but does not wait for its main window to open")]
        [switch]$WaitForWindow,
    
        [Parameter(Mandatory = $false, HelpMessage = "Terminate the process if its main window does not open within the specified timeout period")]
        [switch]$KillOnTimeout,
    
        [Parameter(Mandatory = $false, HelpMessage = "Path to a log file where execution details will be logged")]
        [ValidateNotNullOrEmpty()]
        [string]$LogFile
    )
    BEGIN {
        if ($LogFile) {
            $script:LogStream = [System.IO.StreamWriter]::new($LogFile, $true)
        }
    }
    PROCESS {
        foreach ($Name in $ProcessName) {
            $Process = Get-Process -Name $Name -ErrorAction SilentlyContinue
            if (!$Process) {
                Write-Warning -Message "Process '$Name' is not currently running"
                continue
            }
            $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            do {
                if ($Process.HasExited) {
                    Write-Output "Process '$Name' has exited"
                    break
                }
                if ($WaitForWindow -and !$Process.MainWindowHandle) {
                    Write-Verbose "Waiting for main window of process '$Name' to open..."
                }
                Start-Sleep -Seconds $CheckInterval
            }
            while (($WaitForWindow -and !$Process.MainWindowHandle) -and ($Stopwatch.Elapsed.TotalSeconds -lt $Timeout))
            $Stopwatch.Stop()
            if ($Process.MainWindowHandle) {
                Write-Output "Process '$Name' main window is now open."
                if ($LogFile) {
                    $script:LogStream.WriteLine("[{0}] Process '{1}' main window is now open." -f (Get-Date), $Name)
                }
                Write-Output -InputObject $Process
            }
            else {
                $Message = "Process '$Name' did not open its main window within the specified timeout of $Timeout seconds"
                if ($KillOnTimeout) {
                    $Process.Kill()
                    $Message += " Process terminated."
                }
                Write-Output -InputObject $Message
                if ($LogFile) {
                    $script:LogStream.WriteLine("[{0}] {1}" -f (Get-Date), $Message)
                }
            }
        }
    }
    END {
        if ($LogFile) {
            $script:LogStream.Close()
        }
    }
}
