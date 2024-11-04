function Use-WiFiFilterTool {
    <#
    .SYNOPSIS
    Launches the Wi-Fi Filter Tool application.

    .DESCRIPTION
    This function starts the Wi-Fi Filter Tool, which allows users to manage Wi-Fi network filters through a graphical user interface. 

    .EXAMPLE
    Use-WiFiFilterTool -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Wi-Fi Filter Tool application in a GUI mode")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Wi-Fi Filter Tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\WiFiFilterTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "WifiFilter.zip"
    $ExtractPath = Join-Path $DownloadPath "WifiFilter"
    $Executable = Join-Path $ExtractPath "WifiFilter_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Wi-Fi Filter Tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri "https://www.sordum.org/files/download/wi-fi-filter-tool/WifiFilter.zip" -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Wi-Fi Filter Tool..." -ForegroundColor Green
        if (Test-Path -Path $ExtractPath) {
            Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction Stop
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFilePath, $ExtractPath)
        }
        catch {
            Write-Host "Extracting with Shell.Application..." -ForegroundColor Yellow
            $Shell = New-Object -ComObject Shell.Application
            $Zip = $Shell.NameSpace($ZipFilePath)
            $Destination = $Shell.NameSpace($ExtractPath)
            $Destination.CopyHere($Zip.Items(), 4)
        }
        if (-not (Test-Path -Path $Executable)) {
            $ExtractedSubfolder = Get-ChildItem -Path $ExtractPath | Where-Object { $_.PSIsContainer } | Select-Object -First 1
            if ($ExtractedSubfolder) {
                $Executable = Join-Path $ExtractedSubfolder.FullName "WifiFilter_x64.exe"
            }
        }
        Write-Host "Files in extraction directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $ExtractPath -Recurse | ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Yellow
        }
        if (-Not (Test-Path -Path $Executable)) {
            throw "Wi-Fi Filter Tool executable not found at $Executable"
        }
        if ($StartApplication) {
            Write-Host "Starting Wi-Fi Filter Tool application..." -ForegroundColor Green
            Start-Process -FilePath $Executable -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Wi-Fi Filter Tool operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            try {
                Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
            }
            catch {
                Write-Warning -Message "Failed to remove temporary files: $_"
            }
        }
    }
}
