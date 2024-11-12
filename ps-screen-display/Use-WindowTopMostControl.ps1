function Use-WindowTopMostControl {
    <#
    .SYNOPSIS
    Downloads, extracts, and launches Windows TopMost Control, a tool for making windows always on top.

    .DESCRIPTION
    Windows TopMost Control is a free, portable application that allows you to set any window as always on top.

    .EXAMPLE
    Use-WindowTopMostControl -CommandLineArgs "/S Untitled - Notepad" -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for Windows TopMost Control")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Windows TopMost Control")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/window-topmost-control/TopMost.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Windows TopMost Control will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\WindowTopMostControl",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Windows TopMost Control application after extraction")]
        [switch]$StartApplication
    )
    $ZipFilePath = Join-Path $DownloadPath "TopMost.zip"
    $ExtractPath = Join-Path $DownloadPath "TopMost"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Windows TopMost Control..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Windows TopMost Control..." -ForegroundColor Green
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
        $Executable = Get-ChildItem -Path $ExtractPath -Recurse -Filter "TopMost_x64.exe" | Select-Object -First 1
        if (-Not $Executable) {
            throw "Windows TopMost Control executable not found in $ExtractPath"
        }
        Write-Verbose -Message "Windows TopMost Control extracted to: $($Executable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting Windows TopMost Control..." -ForegroundColor Green
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
        Write-Host "Windows TopMost Control operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
