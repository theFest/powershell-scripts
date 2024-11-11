function Disable-URL {
    <#
    .SYNOPSIS
    Starts the URL Disabler application.

    .DESCRIPTION
    This function manages the URL Disabler tool, which allows users to block specific URLs for Google Chrome, Firefox, and Chromium Edge. It supports starting the application and optionally removing temporary files after use.

    .EXAMPLE
    Disable-URL -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Start the URL Disabler application")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading URL Disabler tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/url-disabler/UrlDisabler.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where URL Disabler tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\UrlDisablerTool"
    )
    $ZipFilePath = Join-Path $DownloadPath "UrlDisabler.zip"
    $ExtractPath = Join-Path $DownloadPath "UrlDisabler"
    $Executable = Join-Path $ExtractPath "UrlDisabler.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading URL Disabler tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting URL Disabler tool..." -ForegroundColor Green
        if (Test-Path -Path $ExtractPath) {
            Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction Stop
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFilePath, $DownloadPath)
        }
        catch {
            Write-Host "Extracting with Shell.Application..." -ForegroundColor Yellow
            $Shell = New-Object -ComObject Shell.Application
            $Zip = $Shell.NameSpace($ZipFilePath)
            $Destination = $Shell.NameSpace($DownloadPath)
            $Destination.CopyHere($Zip.Items(), 4)
        }
        Write-Host "Files in extraction directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $DownloadPath -Recurse | ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Yellow
        }
        if (-Not (Test-Path -Path $Executable)) {
            throw "URL Disabler executable not found at $ExtractPath"
        }
        Write-Verbose -Message "URL Disabler executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting URL Disabler..." -ForegroundColor Green
            Start-Process -FilePath $Executable -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "URL Disabler operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
