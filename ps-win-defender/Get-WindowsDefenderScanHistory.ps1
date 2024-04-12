Function Get-WindowsDefenderScanHistory {
    <#
    .SYNOPSIS
    Retrieves Windows Defender scan history.

    .DESCRIPTION
    This function retrieves the history of Windows Defender scans, including details such as process name, action success, remediation time, initial detection time, and threat status error code.

    .PARAMETER StartTime
    Start time for filtering scan history. Only scans after this time will be included in the result.
    .PARAMETER EndTime
    End time for filtering scan history. Only scans before this time will be included in the result.

    .EXAMPLE
    Get-WindowsDefenderScanHistory -Verbose
    Get-WindowsDefenderScanHistory -StartTime "2024-03-01" -EndTime "2024-03-10"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [datetime]$StartTime,
        
        [Parameter(Mandatory = $false)]
        [datetime]$EndTime
    )
    try {
        Write-Verbose -Message "Fetching Windows Defender scan history..."
        $ScanHistory = Get-MpThreatDetection -ErrorAction Stop
        if ($ScanHistory) {
            Write-Verbose -Message "Windows Defender scan history retrieved successfully"
            $FilteredHistory = $ScanHistory
            if ($StartTime) {
                $FilteredHistory = $FilteredHistory | Where-Object { $_.InitialDetectionTime -ge $StartTime }
            }
            if ($EndTime) {
                $FilteredHistory = $FilteredHistory | Where-Object { $_.InitialDetectionTime -le $EndTime }
            }
            if ($FilteredHistory.Count -gt 0) {
                Write-Host "Windows Defender Scan History:" -ForegroundColor Yellow -NoNewline
                $FilteredHistory | ForEach-Object {
                    [PSCustomObject]@{
                        ProcessName           = $_.ProcessName
                        ActionSuccess         = $_.ActionSuccess
                        RemediationTime       = $_.RemediationTime
                        InitialDetectionTime  = $_.InitialDetectionTime
                        ThreatStatusErrorCode = $_.ThreatStatusErrorCode
                    }
                }
            }
            else {
                Write-Host "No Windows Defender scan history found within the specified time range" -ForegroundColor DarkCyan
            }
        }
        else {
            Write-Host "No Windows Defender scan history found." -ForegroundColor DarkCyan
        }
    }
    catch {
        Write-Error -Message "Error occurred while fetching Windows Defender scan history: $_!"
    }
    finally {
        Write-Verbose -Message "Windows Defender scan history retrieval completed"
    }
}
