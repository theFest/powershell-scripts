Function SimpleWeatherReport {
    <#
    .SYNOPSIS
    Retrieves the current weather report or a forecast for a specified city.

    .DESCRIPTION
    This function fetches weather information for a specified city using the wttr, weather report can be displayed in the console or saved to a file.

    .PARAMETER City
    Mandatory - city for which the weather report should be retrieved, feel free to populate.
    .PARAMETER Provider
    NotMandatory - specifies the weather provider to use, both are API-less.
    .PARAMETER ReportType
    NotMandatory - type of weather report to retrieve.
    .PARAMETER Units
    NotMandatory - units of measurement to use.
    .PARAMETER Encoding
    NotMandatory - choose encoding to use for the output file.
    .PARAMETER OutputFile
    NotMandatory - output file to which the weather report should be saved.

    .EXAMPLE
    SimpleWeatherReport -City Zagreb -Provider wttr -Units imperial -Verbose
    "$env:USERPROFILE\Desktop\Weather_Report.csv" | SimpleWeatherReport -City Zagreb -Units imperial -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("Zagreb", "Paris", "Berlin", "Rome", "Madrid", "London", `
                "Barcelona", "Amsterdam", "Brussels", "Stockholm", "Los Angeles")]
        [string]$City,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("wttrin", "wttr")]
        [string]$Provider = "wttrin",

        [Parameter(Mandatory = $false)]
        [ValidateSet("current", "hourly", "daily")]
        [string]$ReportType = "current",

        [Parameter(Mandatory = $false)]
        [ValidateSet("metric", "imperial")]
        [string]$Units = "metric",

        [Parameter(Mandatory = $false)]
        [ValidateSet("ascii", "bigendianunicode", "default", "oem", "string", `
                "unicode", "unknown", "utf32", "utf7", "utf8")]
        [string]$Encoding = "unicode",

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$OutputFile
    )
    Write-Verbose -Message "Starting"
    $Url = $null
    switch ($Provider) {
        "wttrin" {
            $Url = "https://wttr.in/$City?format=j1"
        }
        "wttr" {
            $Url = "https://wttr.in/$City?format=%C+%t"
        }
        default {
            Write-Error "Invalid provider: $Provider" ; return
        }
    }
    Write-Verbose -Message "Querying for weather, please wait"
    try {
        $Result = Invoke-RestMethod $Url
        if ($OutputFile) {
            $Result | Out-File $OutputFile -Encoding $Encoding -Force
        }
        else {
            $Result | Format-Table -AutoSize
            Write-Verbose -Message $Result
        }
    }
    catch {
        Write-Error "Error accessing $Provider API: $($_.Exception.Message)"
    }
    finally {
        Write-Host "Finished, goodbye :)" -ForegroundColor DarkBlue
    }
}
