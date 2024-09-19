function Hide-DesktopIcons {
    <#
    .SYNOPSIS
    Manages the Show Desktop Icons tool for showing or hiding common desktop icons.

    .DESCRIPTION
    This function uses the Show Desktop Icons tool to manage common desktop icons such as Computer, User’s Files, Network, Recycle Bin, Control Panel, and Internet Explorer.

    .EXAMPLE
    Hide-DesktopIcons -StartApplication
    Hide-DesktopIcons -StartApplication -Command "/S C"
    Hide-DesktopIcons -StartApplication -Command "/H C"
    Hide-DesktopIcons -StartApplication -Command "/S CUNR"
    Hide-DesktopIcons -StartApplication -Command "/H CUNR"
    
    .NOTES
    The command to execute with the ShowDesktopIcons tool:
    - Main Commands:
        - /S : Show desktop icons
        - /H : Hide desktop icons
    - lcon Commands:
        - C : Computer lcon
        - U : Users Files lcon
        - N : Network lcon
        - R : Recycle Bin lcon
        - P : Control Panel lcon
        - I : Internet Explorer lcon
        - E : Microsoft Edge
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Show Desktop Icons application in a GUI mode")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Command-line parameters for the Show Desktop Icons tool")]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Show Desktop Icons tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/show-desktop-icons/sDeskIcon.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Show Desktop Icons tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\ShowDesktopIconsTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "sDeskIcon.zip"
    $ExtractPath = Join-Path $DownloadPath "sDeskIcon"
    $Executable = Join-Path $ExtractPath "sDeskIcon_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Show Desktop Icons tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Show Desktop Icons tool..." -ForegroundColor Green
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
            throw "Show Desktop Icons executable not found at $ExtractPath"
        }
        Write-Verbose -Message "Show Desktop Icons executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Show Desktop Icons application..." -ForegroundColor Green
            if ($Command) {
                Start-Process -FilePath $Executable -ArgumentList $Command -Wait
            }
            else {
                Start-Process -FilePath $Executable -Wait
            }
        }
        else {
            Write-Host "No action specified. Use -StartApplication to launch the tool with commands."
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Show Desktop Icons operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
