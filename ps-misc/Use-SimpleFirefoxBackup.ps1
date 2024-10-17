function Use-SimpleFirefoxBackup {
    <#
    .SYNOPSIS
    Manages Firefox backups using the Simple Firefox Backup tool.

    .DESCRIPTION
    This function uses the Simple Firefox Backup tool to create or restore Firefox backups. It supports the `-Command` parameter to specify backup or restore actions and the `-StartApplication` parameter to launch the tool with specified commands.

    .EXAMPLE
    Use-SimpleFirefoxBackup -StartApplication
    Use-SimpleFirefoxBackup -StartApplication -Command "/C"
    Use-SimpleFirefoxBackup -StartApplication -Command "/C C:\BackupFolder"
    Use-SimpleFirefoxBackup -StartApplication -Command "/C Firefox_20240907_174942"
    Use-SimpleFirefoxBackup -StartApplication -Command "/R"
    Use-SimpleFirefoxBackup -StartApplication -Command "/R C:\BackupFolder"
    Use-SimpleFirefoxBackup -StartApplication -Command "/R Firefox_20240907_174942"

    .NOTES
    The command to execute with the FF backup tool. Valid options are:
    - /R : Restore backup
    - /C : Create backup
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Simple Firefox Backup application")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Command-line parameters for the Simple Firefox Backup tool")]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Simple Firefox Backup tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/simple-firefox-backup/fBackup.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Simple Firefox Backup tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\SimpleFirefoxBackupTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "fBackup.zip"
    $ExtractPath = Join-Path $DownloadPath "fBackup"
    $Executable = Join-Path $ExtractPath "fBackup_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Simple Firefox Backup tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Simple Firefox Backup tool..." -ForegroundColor Green
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
            throw "Simple Firefox Backup executable not found at $ExtractPath"
        }
        Write-Verbose -Message "Simple Firefox Backup executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Simple Firefox Backup application..." -ForegroundColor Green
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
        Write-Host "Simple Firefox Backup operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
