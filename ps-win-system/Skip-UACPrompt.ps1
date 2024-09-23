function Skip-UACPrompt {
    <#
    .SYNOPSIS
    Manages the Skip UAC Prompt tool to bypass UAC prompts for applications.

    .DESCRIPTION
    This function uses the Skip UAC Prompt tool to configure applications to run with elevated privileges without triggering UAC prompts.

    .EXAMPLE
    Skip-UACPrompt -StartApplication
    Skip-UACPrompt -ImportList -FilePath "C:\Path\To\Backup.ini"
    Skip-UACPrompt -ExportList -FilePath "C:\Path\To\Export.ini"
    Skip-UACPrompt -CreateShortcut -FilePath "C:\Path\To\Application.exe"

    .NOTES
    Options for SkipUACPrompt tool are:
    - /l : Imports the file list
    - /E : Exports the file list
    - /ID : Runs the file (ID required)
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Skip UAC Prompt application")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Import a list of applications from a file")]
        [switch]$ImportList,

        [Parameter(Mandatory = $false, HelpMessage = "Export the current list of applications to a file")]
        [switch]$ExportList,

        [Parameter(Mandatory = $false, HelpMessage = "Create a shortcut for the application")]
        [switch]$CreateShortcut,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the file for importing or exporting")]
        [string]$FilePath,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Skip UAC Prompt tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\SkipUACPrompt",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "SkipUAC.zip"
    $ExtractPath = Join-Path $DownloadPath "SkipUAC"
    $Executable = Join-Path $ExtractPath "SkipUAC\SkipUAC_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Skip UAC Prompt tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri "https://www.sordum.org/files/download/skip-uac-prompt/SkipUAC.zip" -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Skip UAC Prompt tool..." -ForegroundColor Green
        if (Test-Path -Path $ExtractPath) {
            Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction Stop
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFilePath, $ExtractPath)
        }
        catch {
            Write-Host "Extracting with Shell.Application..." -ForegroundColor Yellow
            if (-not (Test-Path -Path $ZipFilePath)) {
                throw "The ZIP file was not found at $ZipFilePath"
            }
            if (-not (Test-Path -Path $ExtractPath)) {
                throw "The extraction path was not found or created"
            }
            $Shell = New-Object -ComObject Shell.Application
            $Zip = $Shell.NameSpace($ZipFilePath)
            if ($null -eq $Zip) {
                throw "Failed to initialize Shell.NameSpace for ZIP file"
            }
            $Destination = $Shell.NameSpace($ExtractPath)
            if ($null -eq $Destination) {
                throw "Failed to initialize Shell.NameSpace for destination path"
            }
            $Destination.CopyHere($Zip.Items(), 4)
        }
        Write-Host "Files in extraction directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $ExtractPath -Recurse | ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Yellow
        }
        if (-Not (Test-Path -Path $Executable)) {
            throw "Skip UAC Prompt executable not found at $ExtractPath"
        }
        Write-Verbose -Message "Skip UAC Prompt executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Skip UAC Prompt application..." -ForegroundColor Green
            Start-Process -FilePath $Executable -Wait
        }
        if ($ImportList -and $FilePath) {
            Write-Host "Importing application list from file..." -ForegroundColor Green
            Start-Process -FilePath $Executable -ArgumentList "/l $FilePath" -Wait
        }
        if ($ExportList -and $FilePath) {
            Write-Host "Exporting application list to file..." -ForegroundColor Green
            Start-Process -FilePath $Executable -ArgumentList "/E $FilePath" -Wait
        }
        if ($CreateShortcut -and $FilePath) {
            Write-Host "Creating shortcut for application..." -ForegroundColor Green
            Start-Process -FilePath $Executable -ArgumentList "/ID $FilePath" -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Skip UAC Prompt operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            try {
                Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
            }
            catch {
                Write-Warning -Message "Failed to remove temporary files: $_"
            }
        }
    }
}
