function Send-ToMenuEditor {
    <#
    .SYNOPSIS
    Downloads, extracts, and runs the SendTo Menu Editor tool to manage the Windows 'Send To' menu.

    .DESCRIPTION
    The SendTo Menu Editor allows users to manage the shortcuts present in the Windows "Send To" menu. This function downloads, extracts, and runs the editor with optional command-line arguments.

    .EXAMPLE
    Send-ToMenuEditor -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for the SendTo Menu Editor tool")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading SendTo Menu Editor tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/sendto-menu-editor/SendToEditor.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where SendTo Menu Editor tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\SendToMenuEditor",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the SendTo Menu Editor application after extraction")]
        [switch]$StartApplication
    )
    $ZipFilePath = Join-Path $DownloadPath "SendToEditor.zip"
    $ExtractPath = Join-Path $DownloadPath "SendToEditor"
    $Executable_x64 = Join-Path $ExtractPath "SendToEditor_x64.exe"
    $Executable_x86 = Join-Path $ExtractPath "SendToEditor.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading SendTo Menu Editor tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting SendTo Menu Editor tool..." -ForegroundColor Green
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
        $Executable = if ([Environment]::Is64BitOperatingSystem) {
            $Executable_x64
        }
        else {
            $Executable_x86
        }
        if (-Not (Test-Path -Path $Executable)) {
            throw "SendTo Menu Editor executable not found in $ExtractPath"
        }
        Write-Verbose -Message "SendTo Menu Editor executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting SendTo Menu Editor tool..." -ForegroundColor Green
            if ($CommandLineArgs) {
                Start-Process -FilePath $Executable -ArgumentList $CommandLineArgs
            }
            else {
                Start-Process -FilePath $Executable
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "SendTo Menu Editor tool operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
