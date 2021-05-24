Function WaitProcess {
    <#
    .SYNOPSIS
    This function waits for a process to start.
    
    .DESCRIPTION
    This function waits for a process and it's interactive window to start.
    
    .PARAMETER Time
    Mandatory - retry timeframe in seconds before script quits.
    .PARAMETER Process
    Mandatory - process and it's interactive window that you want to wait for, finally returns path.

    .EXAMPLE
    WaitProcess -Time 120 -Process regedit
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Time,

        [Parameter(Mandatory = $true)]
        [string]$Process
    )
    $TimeSpan = New-TimeSpan -Seconds $Time
    $StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch
    $StopWatch.Start()
    do {
        Write-Output -InputObject 'Checking if process|main window is running...'
        $WaitProcess = $(Get-Process -Name $Process -ErrorAction SilentlyContinue)
        if ($WaitProcess) {
            Write-Output -InputObject ('Process is running in background, PID {0}' -f $WaitProcess.Id)
        }
        elseif (!$WaitProcess) { 
            Write-Output -InputObject ('Process is not running.')
        }
        elseif (!$WaitProcess.Responding) {
            Write-Output -InputObject ('Process is not responding.')
        }
        Start-Sleep -Seconds 5
    }
    until (($WaitProcess.MainWindowTitle) -or ($StopWatch.Elapsed -ge $TimeSpan))
    if ($WaitProcess) {
        $WaitProcess.Refresh()
        Write-Output -InputObject ('Process main window is now running, PID {0}' -f $WaitProcess.Id)
    }
    $StopWatch.Stop()
    return $WaitProcess.Path
}