function Use-NetworkProfileNameChanger {
    <#
    .SYNOPSIS
    Renames or deletes network profiles using the Network Profile Name Changer tool.

    .DESCRIPTION
    This function manages the Network Profile Name Changer tool, which allows users to rename or delete network profiles.

    .EXAMPLE
    Use-NetworkProfileNameChanger -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Network Profile Name Changer application")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Network Profile Name Changer tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/network-profile-name-changer/NetPnc.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Network Profile Name Changer tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\NetworkProfileNameChangerTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "NetPnc.zip"
    $ExtractPath = Join-Path $DownloadPath "NetPnc"
    $Executable = Join-Path $ExtractPath "NetPnc_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Network Profile Name Changer tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Network Profile Name Changer tool..." -ForegroundColor Green
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
            throw "Network Profile Name Changer executable not found at $ExtractPath"
        }
        Write-Verbose -Message "Network Profile Name Changer executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Network Profile Name Changer application..." -ForegroundColor Green
            Start-Process -FilePath $Executable -Wait
        }
        else {
            Write-Host "No action specified."
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Network Profile Name Changer operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
