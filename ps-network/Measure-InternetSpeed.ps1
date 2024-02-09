Function Measure-InternetSpeed {
    <#
    .SYNOPSIS
    Measure the internet speed using Speedtest CLI.

    .DESCRIPTION
    This function measures the internet speed using Speedtest CLI and provides the option to save the results to a file.

    .PARAMETER DownloadPath
    Path where the Speedtest CLI zip file will be downloaded, default is $env:TEMP\speedtest.zip.
    .PARAMETER SpeedtestURL
    URL to download the Speedtest CLI zip file, default is the official Speedtest CLI download URL.
    .PARAMETER OutputFile
    Path to save the speed test results, default is $env:TEMP\speedtest_results.json.
    .PARAMETER ShowProgress
    Indicates whether to display progress while running the speed test.
    .PARAMETER ShowServerList
    Indicates whether to display the list of nearest servers.
    .PARAMETER ServerId
    ID of a specific server to use for the speed test.
    .PARAMETER Interface
    Network interface to use for the speed test.
    .PARAMETER IpAddress
    IP address to bind to when connecting to servers.
    .PARAMETER ServerHost
    Host of a specific server to use for the speed test.
    .PARAMETER Unit
    Unit for displaying speeds. Values: bps, kbps, Mbps, Gbps, B/s, kB/s, MB/s, GB/s, kibps, Mibps, Gibps, kiB/s, MiB/s, GiB/s, auto-binary-bits, auto-binary-bytes, auto-decimal-bits, auto-decimal-bytes.
    .PARAMETER Format
    Specifies the output format for the speed test results, values: human-readable, csv, tsv, json, jsonl, json-pretty, default is json.
    .PARAMETER AddToPath
    Add the extracted directory containing speedtest.exe to the system PATH environment variable.
    .PARAMETER Detailed
    Save detailed results or only the last result to the output file.

    .EXAMPLE
    Measure-InternetSpeed -ShowProgress -OutputFile "C:\Temp\speedtest_results.json" -Detailed

    .NOTES
    v0.1.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$DownloadPath = "$env:TEMP\speedtest.zip",

        [Parameter(Mandatory = $false)]
        [string]$SpeedtestURL = "https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-win64.zip",

        [Parameter(Mandatory = $false)]
        [string]$OutputFile = "$env:TEMP\speedtest_results.json",

        [Parameter(Mandatory = $false)]
        [switch]$ShowProgress,

        [Parameter(Mandatory = $false)]
        [switch]$ShowServerList,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 99999)]
        [int]$ServerId,

        [Parameter(Mandatory = $false)]
        [string]$Interface,

        [Parameter(Mandatory = $false)]
        [string]$IpAddress,

        [Parameter(Mandatory = $false)]
        [string]$ServerHost,

        [Parameter(Mandatory = $false)]
        [ValidateSet("bps", "kbps", "Mbps", "Gbps", "B/s", "kB/s", "MB/s", "GB/s", "kibps", "Mibps", "Gibps", "kiB/s", "MiB/s", "GiB/s", "auto-binary-bits", "auto-binary-bytes", "auto-decimal-bits", "auto-decimal-bytes")]
        [string]$Unit = "Mbps",

        [Parameter(Mandatory = $false)]
        [ValidateSet("human-readable", "csv", "tsv", "json", "jsonl", "json-pretty")]
        [string]$Format = "json",

        [Parameter(Mandatory = $false)]
        [switch]$AddToPath,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    Write-Host "Downloading Speedtest CLI..."
    Invoke-WebRequest -Uri $SpeedtestURL -OutFile $DownloadPath
    Write-Host "Extracting Speedtest CLI..."
    Expand-Archive -Path $DownloadPath -DestinationPath "$env:TEMP\speedtest" -Force
    $SpeedTestExe = Join-Path -Path "$env:TEMP\speedtest" -ChildPath "speedtest.exe"
    if ($AddToPath) {
        $env:PATH += ";$env:TEMP\speedtest"
        Write-Host "Added '"$env:TEMP\speedtest"' to the PATH environment variable"
    }
    $Arguments = @()
    if ($ShowServerList) {
        $Arguments += "--servers"
    }
    if ($ServerId) {
        $Arguments += "--server-id=$ServerId"
    }
    if ($Interface) {
        $Arguments += "--interface=$Interface"
    }
    if ($IpAddress) {
        $Arguments += "--ip=$IpAddress"
    }
    if ($ServerHost) {
        $Arguments += "--host=$ServerHost"
    }
    if ($ShowProgress) {
        $Arguments += "--progress=yes"
    }
    $Arguments += "--format=$Format"
    $Arguments += "--unit=$Unit"
    Write-Host "Running Speedtest..."
    $SpeedTestResult = & $SpeedTestExe @Arguments
    if ($Format -ne "json") {
        $SpeedTestResult = $SpeedTestResult | ConvertFrom-Json
    }
    if ($OutputFile) {
        if ($Detailed) {
            $SpeedTestResult | Out-File -FilePath $OutputFile -Force
            Write-Host "Detailed results saved to $OutputFile" -ForegroundColor Cyan
        }
        else {
            $ShortResult = $SpeedTestResult | ConvertFrom-Json | Select-Object -Last 1 | ConvertTo-Json -Depth 100
            $ShortResult | Out-File -FilePath $OutputFile -Force
            Write-Host "Last result saved to $OutputFile" -ForegroundColor DarkCyan
        }
    }
    else {
        $SpeedTestResult
    }
}
