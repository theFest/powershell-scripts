function Wait-ProcessWindow {
    <#
    .SYNOPSIS
    Waits for the main window of a specified process to open within a specified timeout period.

    .DESCRIPTION
    This function monitors the specified process(es) and waits for their main window to open. It allows setting a maximum timeout period and an interval between checks for the window. 
    Optionally, it can terminate the process if its main window does not open within the specified timeout. Execution details can be logged to a specified log file.

    .EXAMPLE
    Wait-ProcessWindow -ProcessName "notepad" -Timeout 30 -WaitForWindow

    .NOTES
    v0.4.2
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
    
        [Parameter(Mandatory = $false, HelpMessage = "Interval, in seconds, between each check for the process main window, default is 1 second")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$CheckInterval = 1,
    
        [Parameter(Mandatory = $false, HelpMessage = "Wait for the process main window to open")]
        [switch]$WaitForWindow,
    
        [Parameter(Mandatory = $false, HelpMessage = "Terminate the process if its main window does not open within the specified timeout period")]
        [switch]$KillOnTimeout,
    
        [Parameter(Mandatory = $false, HelpMessage = "Path to a log file where execution details will be logged")]
        [ValidateNotNullOrEmpty()]
        [string]$LogFile
    )
    BEGIN {
        if ($LogFile) {
            try {
                $script:LogStream = [System.IO.StreamWriter]::new($LogFile, $true)
            }
            catch {
                Write-Error "Failed to open log file: $_"
                return
            }
        }
        $script:Log = {
            param ($message)
            if ($LogFile) {
                $script:LogStream.WriteLine("[{0}] {1}" -f (Get-Date), $message)
                $script:LogStream.Flush()
            }
        }
    }
    PROCESS {
        foreach ($Name in $ProcessName) {
            $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $WindowOpened = $false
            while ($Stopwatch.Elapsed.TotalSeconds -lt $Timeout) {
                try {
                    $Process = Get-Process -Name $Name -ErrorAction SilentlyContinue
                    if (!$Process) {
                        Write-Verbose "Waiting for process '$Name' to start..."
                        & $script:Log "Waiting for process '$Name' to start..."
                    }
                    elseif ($Process.HasExited) {
                        Write-Output "Process '$Name' has exited"
                        & $script:Log "Process '$Name' has exited"
                        break
                    }
                    elseif ($WaitForWindow -and $Process.MainWindowHandle -ne 0) {
                        $ElapsedTime = [math]::Round($Stopwatch.Elapsed.TotalSeconds, 2)
                        $Message = "Process '$Name' main window is now open after $ElapsedTime seconds."
                        Write-Output $Message
                        & $script:Log $Message
                        Write-Output -InputObject $Process
                        $WindowOpened = $true
                        break
                    }
                    elseif (-not $WaitForWindow) {
                        break
                    }
                    Start-Sleep -Seconds $CheckInterval
                }
                catch {
                    Write-Error "Error while monitoring process '$Name': $_"
                    & $script:Log "Error while monitoring process '$Name': $_"
                    break
                }
            }
            if ($WindowOpened) {
                break
            }
            if (-not $WindowOpened -and $Process -and !$Process.HasExited) {
                $ElapsedTime = [math]::Round($Stopwatch.Elapsed.TotalSeconds, 2)
                $Message = "Process '$Name' did not open its main window within the specified timeout of $Timeout seconds. Waited for $ElapsedTime seconds."
                if ($KillOnTimeout) {
                    try {
                        $Process.Kill()
                        $Message += " Process terminated."
                    }
                    catch {
                        $Message += " Failed to terminate process: $_"
                    }
                }
                Write-Output $Message
                & $script:Log $Message
            }
        }
    }
    END {
        if ($LogFile) {
            $script:LogStream.Close()
        }
    }
}
