function Remove-TempFiles {
    <#
    .SYNOPSIS
    Downloads, extracts, and launches Temp Cleaner, a tool for cleaning up temporary files.

    .DESCRIPTION
    Temp Cleaner is a portable utility that deletes unused files in the %Temp% and %SystemRoot%\Temp folders.

    .EXAMPLE
    Remove-TempFiles -CommandLineArgs "/s" -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for Temp Cleaner")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Temp Cleaner")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/temp-cleaner/TempCleaner.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Temp Cleaner will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\TempCleaner",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Temp Cleaner application after extraction")]
        [switch]$StartApplication
    )
    $ZipFilePath = Join-Path $DownloadPath "TempCleaner.zip"
    $ExtractPath = Join-Path $DownloadPath "TempCleaner"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Temp Cleaner..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Temp Cleaner..." -ForegroundColor Green
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
        $Executable = Get-ChildItem -Path $ExtractPath -Recurse -Filter "TempCleaner.exe" | Select-Object -First 1
        if (-Not $Executable) {
            throw "Temp Cleaner executable not found in $ExtractPath"
        }
        Write-Verbose -Message "Temp Cleaner extracted to: $($Executable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting Temp Cleaner..." -ForegroundColor Green
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
        Write-Host "Temp Cleaner operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
