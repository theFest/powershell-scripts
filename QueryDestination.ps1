Function QueryDestination {
    <#
    .SYNOPSIS
    Query url for status and information in a loop.
    
    .DESCRIPTION
    Simple function for querying status and other information from url, with results exported to csv and ability to timeout and declare duration.
    
    .PARAMETER Url
    Mandatory - input your destination url.
    .PARAMETER DurationTime
    NotMandatory - duration time in seconds.   
    .PARAMETER TimeoutSec
    NotMandatory - declare query timeout.
    .PARAMETER UserAgent
    NotMandatory - define secret if needed.    
    .PARAMETER Interval
    NotMandatory - time between each query. 
    .PARAMETER ExportToCsv
    NotMandatory - use this switch together with ExportToCsvPath to export custom object.   
    
    .EXAMPLE
    QueryDestination -Url 'https://www.powershellgallery.com/' -ExportToCsv $env:USERPROFILE\Desktop\QueryURL.csv -DurationTime 30             ##-->30queries
    QueryDestination -Url 'https://www.powershellgallery.com/' -ExportToCsv $env:USERPROFILE\Desktop\QueryURL.csv -DurationTime 60 -Interval 2 ##-->30queries
    
    .NOTES
    v1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [int]$DurationTime = 60,

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
        [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls, ssl3"
    }
    PROCESS {
        $TimeOut = New-TimeSpan -Seconds $DurationTime
        $EndTime = (Get-Date).Add($TimeOut)
        $Query = Invoke-WebRequest -Uri $Url -UserAgent $UserAgent -TimeoutSec $TimeoutSec
        try {
            do { 
                $Query | Out-Null 
                Start-Sleep -Seconds $Interval
                $QueryObject = [PSCustomObject]@{
                    'Time'       = Get-Date
                    'StatusCode' = $Query.StatusCode
                    'ServerType' = $Query.BaseResponse.Server
                    'Port'       = $Query.BaseResponse.ResponseUri.Port
                }
                $QueryObject | Export-Csv -Path $ExportToCsv -NoTypeInformation -Append        
            }
            until ((Get-Date) -gt $EndTime)
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