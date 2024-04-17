Function New-WindowsDefenderScan {
    <#
    .SYNOPSIS
    Starts a Windows Defender scan with the specified scan type or stops an ongoing scan.

    .DESCRIPTION
    This function starts a Windows Defender scan based on the specified scan type. It supports Quick Scan, Full Scan, and Custom Scan. Additionally, it can stop an ongoing scan if the scan type is set to "StopScan".

    .PARAMETER ScanType
    Type of scan to perform, values are QuickScan, FullScan, Custom, or StopScan to cancel an ongoing scan.
    .PARAMETER AsJob
    Runs the scan as a background job. If used, function returns immediately without waiting for the scan to complete.
    .PARAMETER Wait
    If specified and AsJob is used, waits for the scan to complete before returning.
    .PARAMETER Path
    Specifies the path for a Custom Scan, required if ScanType is set to Custom.

    .EXAMPLE
    New-WindowsDefenderScan -ScanType QuickScan -AsJob -Wait
    New-WindowsDefenderScan -ScanType FullScan -AsJob -Wait
    New-WindowsDefenderScan -ScanType Custom -Path "C:\Temp" -Wait
    New-WindowsDefenderScan -ScanType StopScan

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("QuickScan", "FullScan", "Custom", "StopScan")]
        [string]$ScanType,

        [Parameter(Mandatory = $false)]
        [switch]$AsJob,

        [Parameter(Mandatory = $false)]
        [switch]$Wait,

        [Parameter(Mandatory = $false)]
        [string]$Path
    )
    $StartTime = Get-Date
    if ($ScanType -eq "Custom" -and (!(Test-Path -Path $Path))) {
        Write-Warning -Message "Custom scan requires declared path to exist, check your path!"
        return
    }
    try {
        if ($ScanType -eq "StopScan") {
            if ($AsJob) {
                $Job = Start-Job -ScriptBlock {
                    Write-Host "Stopping Windows Defender scan, please wait..." -ForegroundColor DarkCyan
                    Start-Process -FilePath "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -ArgumentList "-Scan -Cancel" -Wait -WindowStyle Hidden
                    Write-Host "Windows Defender scan should be stopped" -ForegroundColor DarkCyan
                }
                Write-Verbose -Message "StopScan job started in the background. Job ID: $($Job.Id)"
                if ($Wait) {
                    Write-Host "Waiting for the StopScan job to complete, might take a while..." -ForegroundColor DarkCyan
                    $null = Wait-Job -Job $Job
                    Receive-Job -Job $Job
                }
            }
            else {
                Write-Host "Stopping Windows Defender scan, please wait..." -ForegroundColor DarkCyan
                Start-Process -FilePath "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -ArgumentList "-Scan -Cancel" -Wait -WindowStyle Hidden
            }
        }
        else {
            $DefenderService = Get-Service -Name WinDefend -ErrorAction Stop
            if ($DefenderService.Status -eq "Running") {
                if ($AsJob) {
                    $Job = Start-Job -ScriptBlock {
                        param ($ScanType, $Path)
                        $ScanResult = if ($ScanType -eq "Custom") {
                            Start-MpScan -ScanType $ScanType -ScanPath $Path
                        }
                        else {
                            Start-MpScan -ScanType $ScanType.ToLower()
                        }
                        if ($ScanResult.ThreatsDetected -gt 0) {
                            Write-Host "Threats detected: $($ScanResult.ThreatsDetected)" -ForegroundColor DarkMagenta
                        }
                        else {
                            Write-Host "No threats detected" -ForegroundColor Green
                        }
                    } -ArgumentList $ScanType, $Path
                    Write-Verbose -Message "$ScanType scan started in the background. Job ID: $($Job.Id)"
                    if ($Wait) {
                        Write-Host "Waiting for the $ScanType scan to complete..." -ForegroundColor DarkCyan
                        $null = Wait-Job -Job $Job
                        Receive-Job -Job $Job
                    }
                }
                else {
                    if ($ScanType -eq "Custom" -and -not $Path) {
                        Write-Warning -Message "Custom scan requires a path, please specify the path using the -Path parameter!"
                        return
                    }
                    $ScanResult = if ($ScanType -eq "Custom") {
                        Start-MpScan -ScanType $ScanType -ScanPath $Path
                    }
                    else {
                        Start-MpScan -ScanType $ScanType.ToLower()
                    }
                    if ($ScanResult.ThreatsDetected -gt 0) {
                        Write-Host "Threats detected: $($ScanResult.ThreatsDetected)" -ForegroundColor DarkMagenta
                    }
                    else {
                        Write-Host "No threats detected" -ForegroundColor Green
                    }
                }
            }
            else {
                Write-Warning -Message "Windows Defender is not enabled. Cannot perform $ScanType scan!"
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred while starting $ScanType scan: $_"
    }
    finally {
        if (Get-Job -Name * | Where-Object { $_.State -eq 'Completed' }) {
            Remove-Job -Name * -Verbose
        }
        $ScanDuration = (Get-Date).Subtract($StartTime).ToString("hh\:mm\:ss\.fff")
        Write-Host "Total scan duration: $ScanDuration" -ForegroundColor Cyan
    }
}
