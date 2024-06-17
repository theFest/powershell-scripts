function Get-NtpTimeOffset {
    <#
    .SYNOPSIS
    Queries an NTP server for time synchronization information and exports results to CSV.

    .DESCRIPTION
    This function queries a specified NTP server to retrieve time synchronization information. It optionally exports the results to a CSV file. It uses w32tm utility for querying and expects valid connectivity to the NTP server.

    .EXAMPLE
    Get-NtpTimeOffset -NtpServer '0.us.pool.ntp.org' -ExportResults "$env:USERPROFILE\Desktop\NtpResults.csv"

    .NOTES
    v0.5.4
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "NTP server to query for time synchronization")]
        [ValidateSet(
            "time.nist.gov",
            "time.windows.com",
            "0.us.pool.ntp.org",
            "1.us.pool.ntp.org",
            "2.us.pool.ntp.org",
            "3.us.pool.ntp.org",
            "time.google.com",
            "pool.ntp.org",
            "ntp.ubuntu.com",
            "ntp1.inrim.it",
            "time.apple.com",
            "time.cloudflare.com",
            "time.facebook.com",
            "time.amazon.com",
            "time.akamai.com",
            "time.intel.com",
            "time.microsoft.com",
            "time.oracle.com",
            "time.samsung.com",
            "time.twitter.com",
            "time.yahoo.com",
            "time.netflix.com"
        )]
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
        $QueryStatus = $null
        $QueryOffset = $null
        try {
            Write-Verbose -Message "Validating connectivity to NTP server..."
            $PingResult = Test-Connection -ComputerName $NtpServer -Count 1 -ErrorAction Stop
            if (-not $PingResult) {
                throw "Failed to connect to $NtpServer. Ping test returned no response."
            }
        }
        catch {
            $errorMessage = "Failed to connect to $NtpServer. $_"
            Write-Error $errorMessage
            return
        }
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
