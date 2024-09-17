function Edit-DesktopIni {
    <#
    .SYNOPSIS
    Manages the Desktop.ini Editor tool for editing and managing desktop.ini files.

    .DESCRIPTION
    This function uses the Desktop.ini Editor tool to edit desktop.ini files, set custom folder icons, and manage other folder attributes.

    .EXAMPLE
    Edit-DesktopIni -StartApplication
    Edit-DesktopIni -StartApplication -Command "/F=C:\Folder /I=C:\Other\Example.ini"
    Edit-DesktopIni -StartApplication -Command "/F=C:\Folder /S=.ShellClassInfo /L=IconResource=%SystemRoot%\system32\shell32.dll,13"
    Edit-DesktopIni -StartApplication -Command "/F=C:\Folder /D"
    Edit-DesktopIni -StartApplication -Command "/F=C:\Folder /S=.ShellClassInfo /L=LocalizedResourceName=FolderName"

    .NOTES
    The command to execute with the DesktopINI tool. Valid options are:
    - /F : Target folder path
    - /I : Ini file Overwrite Target folder ini file
    - /S : Target section in desktop.ini file
    - /L : Add line in target section
    - /D : Delete desktop.ini file in the target folder
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Desktop.ini Editor application in a GUI form")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Command-line parameters for the Desktop.ini Editor tool")]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Desktop.ini Editor tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/desktop-ini-editor/DeskEdit.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Desktop.ini Editor tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\DesktopIniEditorTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "DeskEdit.zip"
    $ExtractPath = Join-Path $DownloadPath "DeskEdit"
    $Executable = Join-Path $ExtractPath "DeskEdit.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Desktop.ini Editor tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Desktop.ini Editor tool..." -ForegroundColor Green
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
            throw "Desktop.ini Editor executable not found at $ExtractPath"
        }
        Write-Verbose -Message "Desktop.ini Editor executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Desktop.ini Editor application..." -ForegroundColor Green
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
        Write-Host "Desktop.ini Editor operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
