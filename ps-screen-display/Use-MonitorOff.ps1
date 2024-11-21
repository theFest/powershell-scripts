function Use-MonitorOff {
    <#
    .SYNOPSIS
    Controls the monitor and system features using the Sordum Monitor Off tool.

    .DESCRIPTION
    This function manages the Sordum Monitor Off tool, which allows users to turn off the monitor, block input devices, mute sound, and more. It supports the `-StartApplication` parameter to launch the tool with specific commands.

    .EXAMPLE
    Use-MonitorOff -StartApplication
    Use-MonitorOff -StartApplication -Command "/OFF"
    Use-MonitorOff -StartApplication -Command "/OFF /KEYBOARD"
    Use-MonitorOff -StartApplication -Command "/OFF /MOUSE"
    Use-MonitorOff -StartApplication -Command "/OFF /MOUSE /S"
    Use-MonitorOff -StartApplication -Command "/OFF /LOCK /S"
    Use-MonitorOff -StartApplication -Command "/ON"
    Use-MonitorOff -StartApplication -Command "/CONFIG"
    Use-MonitorOff -StartApplication -Command "/OFF /LOCK /KEYBOARD /MOUSE /S"

    .NOTES
    The command to execute with the Monitor OFF tool. Valid options are:
    - /OFF            : Turn off Display
    - /ON             : Turn on Display
    - /L , /LOCK      : Lock current user account when screen turns off
    - /K , /KEYBOARD  : Block keyboard when screen turns off
    - /M , /MOUSE     : Block mouse when screen turns off
    - /S , /MUTE      : Mute sound when screen turns off
    - /C , /CONFIG    : Configuration options
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the 'Sordum Monitor Off' application")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Command-line parameters for the Sordum Monitor Off tool")]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Sordum Monitor Off tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/sordum-monitor-off/MonitorOff.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Sordum Monitor Off tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\SordumMonitorOffTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "MonitorOff.zip"
    $ExtractPath = Join-Path $DownloadPath "MonitorOff"
    $Executable = Join-Path $ExtractPath "MonitorOff_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Sordum Monitor Off tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Sordum Monitor Off tool..." -ForegroundColor Green
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
            throw "Sordum Monitor Off executable not found at $ExtractPath"
        }
        Write-Verbose -Message "Sordum Monitor Off executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Sordum Monitor Off application..." -ForegroundColor Green
            if ($Command) {
                Start-Process -FilePath $Executable -ArgumentList $Command -Wait
            }
            else {
                Write-Error -Message "No command specified. Please provide a command-line parameter using -Command."
            }
        }
        else {
            Write-Host "No action specified. Use -StartApplication to start the application with specified commands."
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Sordum Monitor Off operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
