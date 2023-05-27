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
    .PARAMETER Days
    NotMandatory - number of days to retrieve weather information for when the report type is set to daily.
    .PARAMETER Lang
    NotMandatory - language for the weather report when the report type is set to daily.
    .PARAMETER OutputFile
    NotMandatory - output file to which the weather report should be saved.
    .PARAMETER ShowInBrowser
    NotMandatory - if specified, opens the weather report URL in the default web browser.

    .EXAMPLE
    SimpleWeatherReport -City Amsterdam -Provider wttrin -ShowInBrowser -Verbose
    SimpleWeatherReport -City Rome -Provider wttr -Units imperial -Verbose
    "$env:USERPROFILE\Desktop\Weather_Report.csv" | SimpleWeatherReport -City London -Provider wttr

    .NOTES
    v0.0.2
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

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 365)]
        [int]$Days = 1,

        [Parameter(Mandatory = $false)]
        [ValidateSet("en", "fr", "de", "it", "ja", "pt", "ru", "tr", "ar", "zh")]
        [string]$Lang = "en",

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $false)]
        [switch]$ShowInBrowser
    )
    $Url = $null ; Clear-Host
    Write-Verbose -Message "Starting..."
    switch ($Provider) {
        "wttrin" {
            $Url = "https://wttr.in/$City"
        }
        "wttr" {
            $Url = "https://wttr.in/$City?format=%C+%t"
        }
        default {
            Write-Error "Invalid provider: $Provider"
            return
        }
    }
    Write-Verbose -Message "Adding report type and units to the URL"
    if ($Provider -eq "wttrin") {
        $Url += "?$ReportType"
        if ($Units -eq "imperial") {
            $Url += "I"
        }
    }
    Write-Verbose -Message "Adding number of days and language to the URL"
    if ($ReportType -eq "daily") {
        $Url += "&n=$Days&lang=$Lang"
    }
    Write-Host "Querying for weather, please wait..." -ForegroundColor Cyan
    try {
        $Result = Invoke-RestMethod $Url
        if ($ShowInBrowser) {
            Write-Output "Opening report in the default browser"
            Start-Process $Url -Wait
        }
        if ($OutputFile) {
            $Result | Out-File $OutputFile -Encoding $Encoding -Force
        }
    }
    catch {
        Write-Error "Error accessing $Provider API: $($_.Exception.Message)"
    }
    finally {
        Write-Verbose -Message $Result | Format-Table -AutoSize
        Write-Host "Finished, goodbye :)" -ForegroundColor DarkCyan
    }
}
