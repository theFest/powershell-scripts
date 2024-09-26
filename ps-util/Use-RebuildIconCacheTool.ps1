function Use-RebuildIconCacheTool {
    <#
    .SYNOPSIS
    Downloads, extracts, and runs the Rebuild Shell Icon Cache tool to fix broken icons.

    .DESCRIPTION
    The Rebuild Shell Icon Cache tool allows users to refresh the Windows icon cache. This function downloads, extracts, and executes the tool with optional command-line arguments.

    .EXAMPLE
    Use-RebuildIconCacheTool -CommandLineArgs "/l /F" -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for the Rebuild Shell Icon Cache tool")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Rebuild Shell Icon Cache tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/rebuild-shell-icon-cache/ReIconCache.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Rebuild Shell Icon Cache tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\RebuildIconCacheTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Rebuild Shell Icon Cache application after extraction")]
        [switch]$StartApplication
    )
    $ZipFilePath = Join-Path $DownloadPath "ReIconCache.zip"
    $ExtractPath = Join-Path $DownloadPath "ReIconCache_v1.3"
    $Executable = Join-Path $ExtractPath "ReIconCache_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Rebuild Shell Icon Cache tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Rebuild Shell Icon Cache tool..." -ForegroundColor Green
        if (Test-Path -Path $ExtractPath) {
            Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction Stop
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFilePath, $DownloadPath)
        }
        catch {
            Write-Host "Extracting with Shell.Application..." -ForegroundColor Yellow
            $shell = New-Object -ComObject Shell.Application
            $zip = $shell.NameSpace($ZipFilePath)
            $destination = $shell.NameSpace($DownloadPath)
            $destination.CopyHere($zip.Items(), 4)
        }
        Write-Host "Files in extraction directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $DownloadPath -Recurse | ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Yellow
        }
        if (-Not (Test-Path -Path $Executable)) {
            throw "Rebuild Shell Icon Cache executable not found in $ExtractPath"
        }
        Write-Verbose -Message "Rebuild Shell Icon Cache executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Rebuild Shell Icon Cache tool..." -ForegroundColor Green
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
        Write-Host "Rebuild Shell Icon Cache tool operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
