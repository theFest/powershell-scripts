function Backup-StartMenuLayout {
    <#
    .SYNOPSIS
    Backs up, restores, or resets the Start Menu layout using the "Backup Start Menu Layout" tool.

    .DESCRIPTION
    This function uses Backup Start Menu Layout tool, which helps to back up, restore, or reset the Start Menu layout on Windows 10 and 11. You can either launch the tool's GUI or use specific command-line parameters for operations.

    .EXAMPLE
    Backup-StartMenuLayout -StartApplication
    Backup-StartMenuLayout -Command Create -BackupPath C:\BackupSML -LayoutName "my_layout"
    Backup-StartMenuLayout -Command Restore -BackupPath C:\BackupSML
    Backup-StartMenuLayout -Command Reset

    .NOTES
    The command to run with the Backup Start Menu Layout tool. Valid options are:
    - Create: Creates a backup of the Start Menu layout.
    - Restore: Restores a saved Start Menu layout.
    - Reset: Resets the Start Menu layout to default.
    - None: Use this to start the application without parameters.
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify the command to execute: Create, Restore, Reset, None.")]
        [ValidateSet("Create", "Restore", "Reset", "None")]
        [string]$Command = "None",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the path for backups or restores.")]
        [string]$BackupPath = "",

        [Parameter(Mandatory = $false, HelpMessage = "Specify a custom name for the layout backup.")]
        [string]$LayoutName = "",

        [Parameter(Mandatory = $false, HelpMessage = "Start the Backup Start Menu Layout tool GUI.")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Backup Start Menu Layout tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/backup-start-menu-layout/BackupSML.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Backup Start Menu Layout tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\BackupSMLTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "BackupSML.zip"
    $ExtractPath = Join-Path $DownloadPath "BackupSML"
    $Executable = Join-Path $ExtractPath "BackupSML_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Backup Start Menu Layout tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Backup Start Menu Layout tool..." -ForegroundColor Green
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
            throw "Backup Start Menu Layout executable not found in $ExtractPath"
        }
        Write-Verbose -Message "Backup Start Menu Layout executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Launching Backup Start Menu Layout GUI..." -ForegroundColor Green
            Start-Process -FilePath $Executable -Wait
        }
        else {
            $CmdParameter = switch ($Command) {
                "Create" {
                    if ($BackupPath -ne "" -and $LayoutName -ne "") {
                        "/C $BackupPath /N:$LayoutName"
                    }
                    elseif ($BackupPath -ne "") {
                        "/C $BackupPath"
                    }
                    else {
                        "/C"
                    }
                }
                "Restore" {
                    if ($BackupPath -ne "") {
                        "/R $BackupPath"
                    }
                    else {
                        "/R"
                    }
                }
                "Reset" { "/D" }
                "None" { "" }
            }
            Write-Host "Executing Backup Start Menu Layout command: $CmdParameter" -ForegroundColor Green
            if ($CmdParameter -ne "") {
                Start-Process -FilePath $Executable -ArgumentList $CmdParameter -Wait
            }
            else {
                Write-Host "No command specified, use -StartApplication to launch the GUI or provide a valid command."
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Backup Start Menu Layout operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
