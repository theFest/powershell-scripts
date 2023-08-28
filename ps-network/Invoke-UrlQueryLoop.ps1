Function Invoke-UrlQueryLoop {
    <#
    .SYNOPSIS
    Query a URL for status and information in a loop.

    .DESCRIPTION
    Simple function for querying status and other information from a URL, with results exported to CSV and the ability to specify timeout and duration.

    .PARAMETER Url
    Mandatory - Input the destination URL.
    .PARAMETER DurationTime
    NotMandatory - Duration time value.
    .PARAMETER DurationUnit
    NotMandatory - Unit of duration time (seconds, minutes, hours). Default is seconds.
    .PARAMETER TimeoutSec
    NotMandatory - Declare query timeout.
    .PARAMETER UserAgent
    NotMandatory - Define user agent if needed.
    .PARAMETER Interval
    NotMandatory - Time between each query.
    .PARAMETER ExportToCsv
    NotMandatory - Use this switch together with ExportToCsvPath to export custom object.

    .EXAMPLE
    Invoke-UrlQueryLoop -Url 'https://www.powershellgallery.com/' -ExportToCsv $env:USERPROFILE\Desktop\QueryURL.csv -DurationTime 30 -DurationUnit Seconds
    Invoke-UrlQueryLoop -Url 'https://www.powershellgallery.com/' -ExportToCsv $env:USERPROFILE\Desktop\QueryURL.csv -DurationTime 1 -DurationUnit Hours -Interval 120

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [int]$DurationTime = 60,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Seconds", "Minutes", "Hours")]
        [string]$DurationUnit = "Seconds",

        [Parameter(Mandatory = $false)]
        [string]$UserAgent,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSec,

        [Parameter(Mandatory = $false)]
        [int]$Interval = 1,

        [Parameter(Mandatory = $false)]
        [string]$ExportToCsv
    )
    BEGIN {
        $StartTime = Get-Date
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $durationTimeInSeconds = switch ($DurationUnit) {
            "Minutes" { $DurationTime * 60 }
            "Hours" { $DurationTime * 3600 }
            default { $DurationTime }
        }  
        $EndTime = (Get-Date).AddSeconds($durationTimeInSeconds)
    }
    PROCESS {
        $Query = Invoke-WebRequest -Uri $Url -UserAgent $UserAgent -TimeoutSec $TimeoutSec
        try {
            do {
                $Query | Out-Null
                Start-Sleep -Seconds $Interval
                $QueryObject = [PSCustomObject]@{
                    "Time"       = Get-Date
                    "StatusCode" = $Query.StatusCode
                    "ServerType" = $Query.BaseResponse.Server
                    "Port"       = $Query.BaseResponse.ResponseUri.Port
                }
                $QueryObject | Export-Csv -Path $ExportToCsv -NoTypeInformation -Append
            } until ((Get-Date) -gt $EndTime)
        }
        catch {
            $_.Exception.Response.StatusCode.Value__
            break
        }
        return $QueryObject
    }
    END {
        $Query.Dispose()
        Write-Output "Time taken to query requested URL: $Url $((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")"
    }
}
