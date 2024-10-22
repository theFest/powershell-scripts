function Use-Bpuzzle {
    <#
    .SYNOPSIS
    Launches the Bpuzzle game to play a sliding puzzle game with an image of your choice.

    .DESCRIPTION
    This function downloads, extracts, and starts the Bpuzzle tool, which lets you play a sliding puzzle game by arranging pieces of an image.

    .EXAMPLE
    Use-Bpuzzle -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Bpuzzle game application in a GUI mode")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the Bpuzzle tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\Bpuzzle",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "bPuzzle.zip"
    $ExtractPath = Join-Path $DownloadPath "bPuzzle"
    $Executable = Join-Path $ExtractPath "bPuzzle\bPuzzle_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Bpuzzle tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri "https://www.sordum.org/files/download/bpuzzle/bPuzzle.zip" -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Bpuzzle tool..." -ForegroundColor Green
        if (Test-Path -Path $ExtractPath) {
            Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction Stop
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFilePath, $ExtractPath)
        }
        catch {
            Write-Host "Extracting with Shell.Application..." -ForegroundColor Yellow
            $Shell = New-Object -ComObject Shell.Application
            $Zip = $Shell.NameSpace($ZipFilePath)
            $Destination = $Shell.NameSpace($ExtractPath)
            $Destination.CopyHere($Zip.Items(), 4)
        }
        Write-Host "Files in extraction directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $ExtractPath -Recurse | ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Yellow
        }
        if (-Not (Test-Path -Path $Executable)) {
            throw "Bpuzzle executable not found at $Executable"
        }
        if ($StartApplication) {
            Write-Host "Starting Bpuzzle application..." -ForegroundColor Green
            Start-Process -FilePath $Executable -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Bpuzzle operation completed." -ForegroundColor Cyan
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
