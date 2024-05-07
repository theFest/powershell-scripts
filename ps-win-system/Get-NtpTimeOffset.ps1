Function Get-NtpTimeOffset {
    <#
    .SYNOPSIS
    Queries an NTP server for time synchronization and returns the offset.

    .DESCRIPTION
    This function queries an NTP server to obtain time synchronization information, calculates the time offset between the local system time and the NTP server time.

    .PARAMETER NtpServer
    NTP server to query for time synchronization, available options are 'time.nist.gov', 'time.windows.com', '0.us.pool.ntp.org', '1.us.pool.ntp.org', '2.us.pool.ntp.org', and '3.us.pool.ntp.org'.
    .PARAMETER Samples
    Number of time samples to collect for time synchronization, default value is 3. Valid range: 1-720.
    .PARAMETER Period
    Time interval (in seconds) between samples, default value is 2 seconds. Valid range: 1-3600.
    .PARAMETER ExportResults
    Specifies the path to export the results to a CSV file.

    .EXAMPLE
    Get-NtpTimeOffset -NtpServer '0.us.pool.ntp.org' -ExportResults "$env:USERPROFILE\Desktop\NtpResults.csv"

    .NOTES
    v0.3.8
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "NTP server to query for time synchronization")]
        [ValidateSet("time.nist.gov", "time.windows.com", "0.us.pool.ntp.org", "1.us.pool.ntp.org", "2.us.pool.ntp.org", "3.us.pool.ntp.org")]
        [Alias("n")]
        [string]$NtpServer,

        [Parameter(Mandatory = $false, HelpMessage = "Number of time samples to collect for time synchronization")]
        [ValidateRange(1, 720)]
        [Alias("s")]
        [int]$Samples = 3,

        [Parameter(Mandatory = $false, HelpMessage = "Time interval (in seconds) between samples")]
        [ValidateRange(1, 3600)]
        [Alias("p")]
        [int]$Period = 2,

        [Parameter(Mandatory = $false, HelpMessage = "Path to export results to a CSV file")]
        [Alias("e")]
        [string]$ExportResults
    )
    BEGIN {
        $StartTime = Get-Date
        Write-Host "Querying NTP server: $NtpServer" -ForegroundColor Yellow
    }
    PROCESS {
        $W32Query = w32tm /StripChart /Computer:$NtpServer /DataOnly /Samples:$Samples /Period:$Period /ipprotocol:4
        if (-not ($W32Query -is [array])) {
            $QueryStatus = "Offline" ; $QueryOffset = "n/a"
        }
        else {
            $FoundTime = $false
            Write-Verbose -Message "Go through the 5 samples to find a response with timeoffset"
            for ($i = 3; $i -lt 8; $i++) {
                if (-not $FoundTime) {
                    if ($W32Query[$i] -match ", ([-+]\d+\.\d+)s") {
                        $Offset = [long]$matches[1] ; $FoundTime = $true
                        $QueryStatus = "Online" ; $QueryOffset = $Offset 
                    } 
                }
            }
            Write-Verbose -Message "If no time samples were found, check for error"
            if (-not $FoundTime) {
                if ($W32Query[1..3] -match "error") {
                    Write-Verbose -Message "0x800705B4 is not advertising/responding"
                    $QueryStatus = "NTP not responding" ; $QueryOffset = "n/a"
                }
                else {
                    $QueryStatus = $W32Query[3]
                }
            }
        }
        $QueryObject = [PSCustomObject]@{
            "NtpServer"   = $NtpServer
            "Status"      = $QueryStatus
            "Offset"      = $QueryOffset
            "GetDateTime" = Get-Date -Format "MM/dd/yyyy|HH:mm"
        }
    }
    END {
        if ($ExportResults) {
            $QueryObject | Export-Csv -Path $ExportResults -NoTypeInformation
        }
        $QueryObject
        $TotalTime = (Get-Date).Subtract($StartTime).Duration() -replace ".{8}$"
        Write-Host "Total time duration querying $NtpServer NTP server: $TotalTime" -ForegroundColor Cyan
    }
}
