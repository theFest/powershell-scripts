function Use-DiskPartitionStyle {
    <#
    .SYNOPSIS
    Downloads, extracts, and launches Show Disk Partition Style, a tool for displaying disk partition styles.

    .DESCRIPTION
    Disk Partition Style is a free, portable application that shows the partition style of disks connected to your system.

    .EXAMPLE
    Use-DiskPartitionStyle -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for Show Disk Partition Style")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Show Disk Partition Style")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/show-disk-partition-style/DPStyle.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Show Disk Partition Style will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\ShowDiskPartitionStyle",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Show Disk Partition Style application after extraction")]
        [switch]$StartApplication
    )
    $ZipFilePath = Join-Path $DownloadPath "DPStyle.zip"
    $ExtractPath = Join-Path $DownloadPath "DPStyle"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Show Disk Partition Style..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Show Disk Partition Style..." -ForegroundColor Green
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
            $Destination.CopyHere($zip.Items(), 4)
        }
        Write-Host "Files in extraction directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $DownloadPath -Recurse | ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Yellow
        }
        $Executable = Get-ChildItem -Path $ExtractPath -Recurse -Filter "DPStyle_x64.exe" | Select-Object -First 1
        if (-Not $Executable) {
            $Executable = Get-ChildItem -Path $ExtractPath -Recurse -Filter "DPStyle.exe" | Select-Object -First 1
        }
        if (-Not $Executable) {
            throw "Show Disk Partition Style executable not found in $ExtractPath"
        }
        Write-Verbose -Message "Show Disk Partition Style extracted to: $($Executable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting Show Disk Partition Style..." -ForegroundColor Green
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
        Write-Host "Show Disk Partition Style operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
