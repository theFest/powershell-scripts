Function MeasureNetSpeed {
    <#
    .SYNOPSIS
    Measure network speed using Speedtest CLI and optionally display estimated time remaining.

    .DESCRIPTION
    This function allows you to measure the network speed using Speedtest CLI.
    You can specify the number of iterations, source IP, destination IP, and output format.
    The function can display estimated time remaining for all iterations if the ShowETA switch is used.

    .PARAMETER SpeedTestIterations
    NotMandatory - specifies the number of times the Speedtest will be performed. Default is 2.
    .PARAMETER SourceIP
    NotMandatory - specifies the source IP address to use for the Speedtest.
    .PARAMETER DestinationIP
    NotMandatory - specifies the destination IP address for the Speedtest.
    .PARAMETER CsvFilePath
    NotMandatory - specifies the path for saving the Speedtest results in CSV format. Default path is "$env:USERPROFILE\Desktop\Speedtest_Results.csv".
    .PARAMETER OutputFormat
    NotMandatory - specifies the output format for displaying the results. Valid values are "Table" and "CSV". Default is "Table".
    .PARAMETER ShowETA
    NotMandatory - parameter to display the estimated time remaining for all iterations.
    .PARAMETER IncludeIterationDetails
    NotMandatory - parameter to include detailed results for each iteration.

    .EXAMPLE
    MeasureNetSpeed -ShowETA -IncludeIterationDetails -OutputFormat CSV

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SpeedTestIterations = 2,

        [Parameter(Mandatory = $false)]
        [string]$SourceIP = "",

        [Parameter(Mandatory = $false)]
        [string]$DestinationIP = "",

        [Parameter(Mandatory = $false)]
        [string]$CsvFilePath = "$env:USERPROFILE\Desktop\Speedtest_Results.csv",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Table", "CSV")]
        [string]$OutputFormat = "Table",

        [Parameter(Mandatory = $false)]
        [switch]$ShowETA,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeIterationDetails
    )
    BEGIN {
        Write-Verbose -Message "Checking if Chocolatey is installed and install it if not..."
        if (-not (Get-Command "choco" -ErrorAction SilentlyContinue)) {
            Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
            Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        }
        Write-Verbose -Message "Checking if Speedtest CLI is installed and install it if not..."
        if (-not (Get-Command "speedtest-cli" -ErrorAction SilentlyContinue)) {
            Write-Host "Installing Speedtest CLI..." -ForegroundColor Cyan
            choco install speedtest-cli -y
        }
        $StartTime = Get-Date
        $SpeedTestResults = @()
    }
    PROCESS {
        $Iteration = 1
        while ($Iteration -le $SpeedTestIterations) {
            Write-Host "Speedtest Iteration $Iteration"
            $SpeedTestParams = @()
            if ($SourceIP) { 
                $SpeedTestParams += "--source $SourceIP" 
            }
            if ($DestinationIP) { 
                $SpeedTestParams += "--server $DestinationIP" 
            }
            $Result = & speedtest-cli --json @SpeedTestParams
            if ($Result) {
                $DownloadSpeed = $Result | ConvertFrom-Json | Select-Object -ExpandProperty download
                $UploadSpeed = $Result | ConvertFrom-Json | Select-Object -ExpandProperty upload
                if ($DownloadSpeed -and $UploadSpeed) {
                    $SpeedTestResults += [PSCustomObject]@{
                        Iteration     = $Iteration
                        DownloadSpeed = $DownloadSpeed
                        UploadSpeed   = $UploadSpeed
                    }
                }
            }
            else {
                Write-Warning "Speedtest CLI failed. Unable to retrieve network speeds."
            }
            $Iteration++
            if ($ShowETA -and $SpeedTestIterations -gt 1) {
                $CurrentIteration = $Iteration - 1
                $TimePerIteration = (Get-Date).Subtract($StartTime).TotalSeconds / $CurrentIteration
                $EstimatedTimeRemaining = ($SpeedTestIterations - $CurrentIteration) * $TimePerIteration
                $TimeLeft = [timespan]::FromSeconds($EstimatedTimeRemaining)
                Write-Host "Estimated Time Left for all iterations:`t $TimeLeft"
            }
        }
    }
    END {
        if ($OutputFormat -eq "Table" -and $IncludeIterationDetails -and $SpeedTestResults.Count -gt 0) {
            Write-Host "Speedtest Iteration Details:"
            $SpeedTestResults
        }
        if ($OutputFormat -eq "CSV" -and $IncludeIterationDetails -and $SpeedTestResults.Count -gt 0) {
            $SpeedTestResults | Export-Csv -Path $CsvFilePath -NoTypeInformation
            Write-Host "Speedtest Results saved to $CsvFilePath."
        }
        if ($OutputFormat -eq "Table" -and $SpeedTestResults.Count -gt 0) {
            $AvgDownloadSpeed = ($SpeedTestResults | Measure-Object -Property DownloadSpeed -Average).Average
            $AvgUploadSpeed = ($SpeedTestResults | Measure-Object -Property UploadSpeed -Average).Average
            Write-Host "Average Download Speed:`t $AvgDownloadSpeed Mbps"
            Write-Host "Average Upload Speed:`t $AvgUploadSpeed Mbps"
        }
    }
}
