Function Wait-ProcessWithWindow {
    <#
    .SYNOPSIS
    This function waits for a process to start.
    
    .DESCRIPTION
    This function waits for a process and it's interactive window to start.
    
    .PARAMETER Time
    Mandatory - retry timeframe in seconds before script timeouts/quits.
    .PARAMETER Process
    Mandatory - process and it's interactive window that you want to wait for.
    .PARAMETER CheckInterval
    Mandatory - interval between every next check, default is 1 second.

    .EXAMPLE
    Wait-ProcessWithWindow -Time 120 -Process mspaint -CheckInterval 10

    .NOTES
    v0.1.1
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Time,

        [Parameter(Mandatory = $true)]
        [string]$Process,

        [Parameter(Mandatory = $false)]
        [string]$CheckInterval
    )
    $TimeSpan = New-TimeSpan -Seconds $Time
    $StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
    $StopWatch.Start()
    do {
        Write-Output -InputObject 'Checking if Process and/or MainWindow is running...'
        $WaitProcess = $(Get-Process -Name $Process -ErrorAction SilentlyContinue)
        if ($WaitProcess) {
            Write-Output -InputObject ('Process is running in background, PID {0}' -f $WaitProcess.Id)
        }
        elseif (!$WaitProcess) { 
            Write-Output -InputObject ('Process is not running!')
        }
        elseif (!$WaitProcess.Responding) {
            Write-Output -InputObject ('Process is not responding!')
        }
        Start-Sleep -Seconds $CheckInterval
    }
    until (($WaitProcess.MainWindowTitle) -or ($StopWatch.Elapsed -ge $TimeSpan))
    if ($WaitProcess) {
        $WaitProcess.Refresh()
        Write-Output -InputObject ('Process main window is now running, PID {0}' -f $WaitProcess.Id)
    }
    else {
        Write-Output -InputObject ('Process check has timed out')
    }
    $StopWatch.Stop()
    return $WaitProcess.Path
}