function Repair-PrintSpooler {
    <#
    .SYNOPSIS
    Downloads, extracts, and launches Fix Print Spooler, a tool for managing and troubleshooting print spooler issues.

    .DESCRIPTION
    Fix Print Spooler is a free, portable application that helps resolve print spooler issues by resetting and clearing the print spooler queue.
    This script automates the process of downloading, extracting, and running the Fix Print Spooler tool. It also provides options to clean up temporary files after use and pass command-line arguments to the application.

    .EXAMPLE
    Repair-PrintSpooler -StartApplication
    Repair-PrintSpooler -CommandLineArgs "/F" -StartApplication
    Repair-PrintSpooler -RemoveFixPrintSpooler

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for Fix Print Spooler")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Fix Print Spooler")]
        [uri]$FixPrintSpoolerDownloadUrl = "https://www.sordum.org/files/download/fix-print-spooler/FixPrintSpooler.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Fix Print Spooler will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\FixPrintSpooler",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFixPrintSpooler,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Fix Print Spooler application after extraction")]
        [switch]$StartApplication
    )
    $FixPrintSpoolerZipPath = Join-Path $DownloadPath "FixPrintSpooler.zip"
    $FixPrintSpoolerExtractPath = Join-Path $DownloadPath "FixPrintSpooler_v1.3"
    $FixPrintSpoolerExecutableName = "FixSpooler_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $FixPrintSpoolerZipPath)) {
            Write-Host "Downloading Fix Print Spooler..." -ForegroundColor Green
            Invoke-WebRequest -Uri $FixPrintSpoolerDownloadUrl -OutFile $FixPrintSpoolerZipPath -UseBasicParsing -Verbose
            if ((Get-Item $FixPrintSpoolerZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Fix Print Spooler..." -ForegroundColor Green
        if (Test-Path -Path $FixPrintSpoolerExtractPath) {
            Remove-Item -Path $FixPrintSpoolerExtractPath -Recurse -Force -ErrorAction Stop
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($FixPrintSpoolerZipPath, $DownloadPath)
        }
        catch {
            Write-Host "Extracting with Shell.Application..." -ForegroundColor Yellow
            $Shell = New-Object -ComObject Shell.Application
            $Zip = $Shell.NameSpace($FixPrintSpoolerZipPath)
            $Destination = $Shell.NameSpace($DownloadPath)
            $Destination.CopyHere($zip.Items(), 4)
        }
        Write-Host "Files in extraction directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $DownloadPath -Recurse | ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Yellow
        }
        $FixPrintSpoolerExecutablePath = Get-ChildItem -Path $FixPrintSpoolerExtractPath -Recurse -Filter $FixPrintSpoolerExecutableName | Select-Object -First 1
        if (-Not $FixPrintSpoolerExecutablePath) {
            throw "Fix Print Spooler executable '$FixPrintSpoolerExecutableName' not found in $FixPrintSpoolerExtractPath"
        }
        Write-Verbose -Message "Fix Print Spooler extracted to: $($FixPrintSpoolerExecutablePath.FullName)"
        if ($StartApplication) {
            Write-Host "Starting Fix Print Spooler..." -ForegroundColor Green
            if ($CommandLineArgs) {
                Start-Process -FilePath $FixPrintSpoolerExecutablePath.FullName -ArgumentList $CommandLineArgs
            }
            else {
                Start-Process -FilePath $FixPrintSpoolerExecutablePath.FullName
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Fix Print Spooler operation completed." -ForegroundColor Cyan
        if ($RemoveFixPrintSpooler) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
