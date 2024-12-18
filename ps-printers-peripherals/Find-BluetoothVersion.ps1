function Find-BluetoothVersion {
    <#
    .SYNOPSIS
    Downloads, extracts, and launches Bluetooth Version Finder, a tool to identify your Bluetooth version quickly.

    .DESCRIPTION
    Bluetooth Version Finder is a free, portable tool that helps you identify the Bluetooth version on your system without manually checking through the Device Manager.
    Script automates the process of downloading, extracting, and running the Bluetooth Version Finder. You can also clean up temporary files after use and provide command-line arguments to the application.

    .EXAMPLE
    Find-BluetoothVersion -StartApplication
    Find-BluetoothVersion -CommandLineArgs "/P" -StartApplication
    Find-BluetoothVersion -RemoveBluetoothVersionFinder

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for Bluetooth Version Finder")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Bluetooth Version Finder")]
        [uri]$BluetoothVersionFinderDownloadUrl = "https://www.sordum.org/files/download/bluetooth-version-finder/btVersion.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Bluetooth Version Finder will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\BluetoothVersionFinder",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveBluetoothVersionFinder,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Bluetooth Version Finder application after extraction")]
        [switch]$StartApplication
    )
    $BluetoothVersionFinderZipPath = Join-Path $DownloadPath "btVersion.zip"
    $BluetoothVersionFinderExtractPath = Join-Path $DownloadPath "btVersion"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $BluetoothVersionFinderZipPath)) {
            Write-Host "Downloading Bluetooth Version Finder..." -ForegroundColor Green
            Invoke-WebRequest -Uri $BluetoothVersionFinderDownloadUrl -OutFile $BluetoothVersionFinderZipPath -UseBasicParsing -Verbose
            if ((Get-Item $BluetoothVersionFinderZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Bluetooth Version Finder..." -ForegroundColor Green
        if (Test-Path -Path $BluetoothVersionFinderExtractPath) {
            Remove-Item -Path $BluetoothVersionFinderExtractPath -Recurse -Force -ErrorAction Stop
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($BluetoothVersionFinderZipPath, $DownloadPath)
        }
        catch {
            Write-Host "Extracting with Shell.Application..." -ForegroundColor Yellow
            $Shell = New-Object -ComObject Shell.Application
            $Zip = $Shell.NameSpace($BluetoothVersionFinderZipPath)
            $Destination = $Shell.NameSpace($DownloadPath)
            $Destination.CopyHere($Zip.Items(), 4)
        }
        Write-Host "Files in extraction directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $DownloadPath -Recurse | ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Yellow
        }
        $BluetoothVersionFinderExecutable = Get-ChildItem -Path $DownloadPath -Recurse -Filter "btVersion_x64.exe" | Select-Object -First 1
        if (-Not $BluetoothVersionFinderExecutable) {
            throw "Bluetooth Version Finder executable not found in $DownloadPath"
        }
        Write-Verbose -Message "Bluetooth Version Finder extracted to: $($BluetoothVersionFinderExecutable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting Bluetooth Version Finder..." -ForegroundColor Green
            if ($CommandLineArgs) {
                Start-Process -FilePath $BluetoothVersionFinderExecutable.FullName -ArgumentList $CommandLineArgs
            }
            else {
                Start-Process -FilePath $BluetoothVersionFinderExecutable.FullName
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Bluetooth Version Finder operation completed." -ForegroundColor Cyan
        if ($RemoveBluetoothVersionFinder) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
