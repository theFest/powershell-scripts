function Use-DriveLetterChanger {
    <#
    .SYNOPSIS
    Downloads, extracts, and launches Drive Letter Changer, a tool for assigning specific drive letters to storage devices.

    .DESCRIPTION
    Drive Letter Changer is a portable freeware tool that simplifies the process of assigning a specific drive letter to a hard drive or external storage device.

    .EXAMPLE
    Use-DriveLetterChanger -StartApplication
    Use-DriveLetterChanger -StartApplication -CommandLineArgs "D: E:"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for Drive Letter Changer, e.g. 'D: E:", "D: E: Force", "-Drive Label E:", "-Drive Label E: Force'")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Drive Letter Changer")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/drive-letter-changer/dChanger.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Drive Letter Changer will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\DriveLetterChanger",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Drive Letter Changer application after extraction")]
        [switch]$StartApplication
    )
    $ZipFilePath = Join-Path $DownloadPath "dChanger.zip"
    $ExtractPath = Join-Path $DownloadPath "DriveLetterChanger"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Drive Letter Changer..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Drive Letter Changer..." -ForegroundColor Green
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
        $Executable = Get-ChildItem -Path $DownloadPath -Recurse -Filter "dChanger.exe" | Select-Object -First 1
        if (-Not $Executable) {
            throw "Drive Letter Changer executable not found in $DownloadPath"
        }
        Write-Verbose -Message "Drive Letter Changer extracted to: $($Executable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting Drive Letter Changer..." -ForegroundColor Green
            if ($CommandLineArgs) {
                Start-Process -FilePath $Executable.FullName -ArgumentList $CommandLineArgs
            }
            else {
                Start-Process -FilePath $Executable.FullName
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Drive Letter Changer operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
