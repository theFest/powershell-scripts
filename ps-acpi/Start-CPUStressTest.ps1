#Requires -Version 3.0 -Modules CimCmdlets
Function Start-CPUStressTest {
    <#
    .SYNOPSIS
    Start a CPU stress test to evaluate system performance.
    
    .DESCRIPTION
    This function initiates a CPU stress test to evaluate performance of the system under high CPU load. 
    It utilizes PowerShell jobs to generate CPU load, monitoring CPU usage throughout the test duration and stopping with or without confirmation.
    
    .PARAMETER HighLoad
    Intensify CPU load by utilizing twice the number of logical processors available on the system.
    .PARAMETER ForceStop
    Directs the execution without user confirmation, leading to the immediate deletion of any existing CPU workload jobs.
    .PARAMETER TestDuration
    Defines the duration, in seconds, for which the CPU stress test should be conducted.
    
    .EXAMPLE
    Start-CPUStressTest -Verbose
    Start-CPUStressTest -TestDuration 30 -HighLoad -ForceStop
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Double the number of logical processors available on the system")]
        [switch]$HighLoad,

        [Parameter(Mandatory = $false, HelpMessage = "Execute without user confirmation, deleting any existing CPU workload jobs")]
        [switch]$ForceStop,

        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Duration of the CPU stress test")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$TestDuration = 30
    )
    BEGIN {
        if ($Host.Name -ne 'ConsoleHost') {
            Write-Warning -Message "This function can only be run in the PowerShell Console!"
            break
        }
        $StartTime = Get-Date
        Write-Host "Script started at: $(Get-Date)" -ForegroundColor DarkCyan
        $TotalThreads = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors
        $Threads = if ($HighLoad) { $TotalThreads * 2 } else { $TotalThreads }
        $EndTime = if ($TestDuration) { $StartTime.AddSeconds($TestDuration) } else { [datetime]::MaxValue }
        $StopTest = $false
    }
    PROCESS {
        $ClearActiveCPUJobs = {
            param (
                [switch]$ForceStop
            )
            $ActiveCPUJobList = Get-Job -Name 'CPUWorkload_*' -ErrorAction Continue
            if ($ActiveCPUJobList) {
                if ($ForceStop -or $PSCmdlet.ShouldContinue("Are you certain you wish to stop and delete all 'CPUWorkload' jobs?", "Please confirm your choice: Yes / No / Suspend")) {
                    Write-Verbose -Message "Clearing running CPUWorkload jobs, please wait..."
                    $ActiveCPUJobList | Stop-Job -ErrorAction Continue
                    $ActiveCPUJobList | Remove-Job -Force -ErrorAction Continue
                }
            }
        }
        $InitiateCPUWorkload = {
            param (
                [int]$Threads
            )
            Write-Verbose -Message "Starting to generate load, based on the system capabilities..."
            foreach ($Loop in 1 .. $Threads) {
                $null = Start-Job -Name ('CPUWorkload_' + $Loop) -ScriptBlock {
                    [float]$Result = 1
                    while ($true) {
                        [float]$RandomMultiplier = Get-Random -Minimum 1 -Maximum 999999999
                        $Result = $Result * $RandomMultiplier
                    }
                }
            }
        }
        Write-Verbose -Message "Clear running 'CPUWorkload' jobs if 'ForceStop' is used or user confirms..."
        & $ClearActiveCPUJobs -Force:$ForceStop
        Write-Verbose -Message "Start 'CPUWorkload' based on system capabilities and 'HighLoad' switch..."
        & $InitiateCPUWorkload -Threads $Threads
        Write-Host "Press (ESC/ENTER) to stop gracefully or (CTRL+C) to abort:" -ForegroundColor Magenta
        $ElapsedTime = 0
        while ((Get-Date) -lt $EndTime -and !$StopTest) {
            $Load = Get-Counter '\Processor(_Total)\% Processor Time' | Select-Object -ExpandProperty CounterSamples | Select-Object -ExpandProperty CookedValue
            $TimeRemaining = ($EndTime - (Get-Date)).TotalSeconds
            $Time = Get-Date -Format "HH:mm:ss"
            Write-Host "Time=$Time <~~> CPU=$($Load.ToString('F2'))% <~~> ETA=$($TimeRemaining.ToString('F1'))/sec" -ForegroundColor Cyan
            Start-Sleep -Seconds 1
            Write-Verbose -Message "Checking if (ESC/ENTER) or (CTRL+C) is pressed..."
            if ([System.Console]::KeyAvailable) {
                $Key = [System.Console]::ReadKey($true)
                if ($Key.Key -eq "ENTER" -or $Key.Key -eq "ESC") {
                    $StopTest = $true
                    Write-Host "Keypress detected, stopping CPU stress test, please wait..." -ForegroundColor Yellow
                    & $ClearActiveCPUJobs -Force:$ForceStop
                }
            }
            $ElapsedTime++
        }
    }
    END {
        if ((Get-Date) -ge $EndTime) {
            Write-Host "Test duration reached, CPU stress test finished, exiting!" -ForegroundColor Cyan
            & $ClearActiveCPUJobs -Force:$ForceStop
        }
        $EndTime = Get-Date
        $ElapsedTime = New-TimeSpan -Start $StartTime -End $EndTime
        Write-Host "CPU stress test ended at: $(Get-Date) | Total time taken: $($ElapsedTime.TotalSeconds) seconds" -ForegroundColor DarkCyan
    }
}
