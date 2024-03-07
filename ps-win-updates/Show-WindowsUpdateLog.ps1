Function Show-WindowsUpdateLog {
    <#
    .SYNOPSIS
    Retrieves Windows Update logs from specified paths.

    .DESCRIPTION
    This function retrieves Windows Update logs from default and custom log paths. Users can specify additional custom log paths using the CustomLogPaths parameter.

    .PARAMETER CustomLogPaths
    Specifies additional custom log paths to be included in the search.

    .EXAMPLE
    Show-WindowsUpdateLog

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [string[]]
        $CustomLogPaths = @()
    )
    $DefaultLogPaths = @(
        "$env:SystemRoot\WindowsUpdate.log",
        "$env:SystemRoot\SoftwareDistribution\ReportingEvents.log",
        "$env:SystemRoot\Logs\CBS\CBS.log"
        # Add more default log paths as needed
    )
    $UpdateLogPaths = $DefaultLogPaths + $CustomLogPaths
    $FoundLogs = @()
    foreach ($LogPath in $UpdateLogPaths) {
        if (Test-Path -Path $LogPath) {
            try {
                $LogContent = Get-Content -Path $LogPath -ErrorAction Stop
                $FoundLogs += $LogContent
            }
            catch {
                Write-Host "Error reading log at ${LogPath}: $_" -ForegroundColor DarkRed
            }
        }
        else {
            Write-Host "Log not found at: $LogPath" -ForegroundColor DarkGreen
        }
    }
    if ($FoundLogs.Count -gt 0) {
        return $FoundLogs
    }
    else {
        Write-Warning -Message "No Windows Update logs found!"
    }
}
