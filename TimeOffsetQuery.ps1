Function TimeOffsetQuery {
    <#
    .SYNOPSIS
    Query time offset.
    
    .DESCRIPTION
    Query time drift using 'w32tm', the Windows native way. Error check and timeout features are included.
    
    .PARAMETER NtpServer
    Mandatory - declare NTP to queired, modify set to your needs.
    .PARAMETER Samples
    NotMandatory - count samples, then stop. Up to 720 samples is declared, default is 3.
    .PARAMETER Period
    NotMandatory - time between samples, in seconds. The default value is set to 2 seconds.
    .PARAMETER ExportResults
    NotMandatory - you can export offset results to csv file, define path like "$env:TEMP\TimeOffsetQuery.csv".
    
    .EXAMPLE
    TimeOffsetQuery -NtpServer 0.us.pool.ntp.org
    
    .NOTES
    v1 -->https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-r2-and-2012/ff799054(v=ws.11)
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet('time.nist.gov', 'time.windows.com', '0.us.pool.ntp.org', '1.us.pool.ntp.org', '2.us.pool.ntp.org', '3.us.pool.ntp.org')]
        [string]$NtpServer,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 720)]
        [int]$Samples = 3,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 3600)]
        [int]$Period = 2,

        [Parameter(Mandatory = $false)]
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
            ## go through the 5 samples to find a response with timeoffset.
            for ($i = 3; $i -lt 8; $i++) {
                if (-not $FoundTime) {
                    if ($W32Query[$i] -match ", ([-+]\d+\.\d+)s") {
                        $Offset = [long]$matches[1] ; $FoundTime = $true
                        $QueryStatus = "Online" ; $QueryOffset = $Offset 
                    } 
                }
            }
            ## if no time samples were found, check for error.
            if (-not $FoundTime) {
                if ($W32Query[1..3] -match "error") {
                    ## 0x800705B4 is not advertising/responding.
                    $QueryStatus = "NTP not responding" ; $QueryOffset = "n/a"
                }
                else {
                    $QueryStatus = $W32Query[3]
                }
            }
        }
        $QueryObject = [PSCustomObject]@{
            'NtpServer'   = $NtpServer
            'Status'      = $QueryStatus
            'Offset'      = $QueryOffset
            'GetDateTime' = Get-Date -Format "MM/dd/yyyy|HH:mm"
        }
    }
    END {
        if ($ExportResults) {
            $QueryObject | Export-Csv -Path $ExportResults -NoTypeInformation
        }
        $QueryObject
        Write-Host "Total time duration $NtpServer NTP server: $((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")" -ForegroundColor Cyan
    }
}