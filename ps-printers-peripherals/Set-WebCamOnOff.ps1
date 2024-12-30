function Set-WebCamOnOff {
    <#
    .SYNOPSIS
    Downloads, extracts, and launches WebCam On-Off for managing webcam and microphone access.

    .DESCRIPTION
    This function downloads and extracts WebCam On-Off, then starts the application. You can specify command-line arguments to enable or disable the webcam, or preview it.

    .EXAMPLE
    Set-WebCamOnOff -StartApplication
    Set-WebCamOnOff -CommandLineArgs "/D" -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for WebCam On-Off")]
        [ValidateSet("/E", "/D", "/P")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading WebCam On-Off")]
        [uri]$WebCamDownloadUrl = "https://www.sordum.org/files/download/webcam-on-off/WebcamOnOff.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where WebCam On-Off will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\WebCam-On-Off",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveWebCam,

        [Parameter(Mandatory = $false, HelpMessage = "Start the WebCam On-Off application after extraction")]
        [switch]$StartApplication
    )
    $WebCamZipPath = Join-Path $DownloadPath "WebcamOnOff.zip"
    $WebCamExtractPath = Join-Path $DownloadPath "WebcamOnOff_v1.4"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $WebCamZipPath)) {
            Write-Host "Downloading WebCam On-Off..." -ForegroundColor Green
            Invoke-WebRequest -Uri $WebCamDownloadUrl -OutFile $WebCamZipPath -UseBasicParsing -Verbose
            if ((Get-Item $WebCamZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting WebCam On-Off..." -ForegroundColor Green
        if (Test-Path -Path $WebCamExtractPath) {
            Remove-Item -Path $WebCamExtractPath -Recurse -Force -ErrorAction Stop
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($WebCamZipPath, $DownloadPath)
        }
        catch {
            Write-Host "Extracting with Shell.Application..." -ForegroundColor Yellow
            $Shell = New-Object -ComObject Shell.Application
            $Zip = $Shell.NameSpace($WebCamZipPath)
            $Destination = $Shell.NameSpace($DownloadPath)
            $Destination.CopyHere($zip.Items(), 4)
        }
        Write-Host "Files in extraction directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $DownloadPath -Recurse | ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Yellow
        }
        $WebCamExecutable = Get-ChildItem -Path $WebCamExtractPath -Recurse -Filter "WebCam.exe" | Select-Object -First 1
        if (-Not $WebCamExecutable) {
            throw "WebCam.exe not found in $WebCamExtractPath"
        }
        Write-Verbose -Message "WebCam On-Off extracted to: $($WebCamExecutable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting WebCam On-Off..." -ForegroundColor Green
            if ($CommandLineArgs) {
                Start-Process -FilePath $WebCamExecutable.FullName -ArgumentList $CommandLineArgs
            }
            else {
                Start-Process -FilePath $WebCamExecutable.FullName
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "WebCam On-Off operation completed." -ForegroundColor Cyan
        if ($RemoveWebCam) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
