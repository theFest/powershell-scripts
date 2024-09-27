function Block-Keys {
    <#
    .SYNOPSIS
    Downloads, extracts, and launches KeyFreeze, a tool to block the keyboard and mouse without locking the screen.

    .DESCRIPTION
    KeyFreeze is a free Windows application that allows you to block the keyboard and mouse while keeping the screen unlocked.
    This is useful for preventing unintended input while allowing your kids or others to safely interact with your system without locking the screen.

    .EXAMPLE
    Block-Keys -CommandLineArgs "" -StartApplication
    Block-Keys -RemoveKeyFreeze

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for KeyFreeze")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading KeyFreeze")]
        [uri]$KeyFreezeDownloadUrl = "https://www.sordum.org/files/bluelife-keyfreeze/KeyFreeze.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where KeyFreeze will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\KeyFreeze",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveKeyFreeze,

        [Parameter(Mandatory = $false, HelpMessage = "Start the KeyFreeze application after extraction")]
        [switch]$StartApplication
    )
    $KeyFreezeZipPath = Join-Path $DownloadPath "KeyFreeze.zip"
    $KeyFreezeExtractPath = Join-Path $DownloadPath "KeyFreeze"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $KeyFreezeZipPath)) {
            Write-Host "Downloading KeyFreeze..." -ForegroundColor Green
            Invoke-WebRequest -Uri $KeyFreezeDownloadUrl -OutFile $KeyFreezeZipPath -UseBasicParsing -Verbose
            if ((Get-Item $KeyFreezeZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting KeyFreeze..." -ForegroundColor Green
        if (Test-Path -Path $KeyFreezeExtractPath) {
            Remove-Item -Path $KeyFreezeExtractPath -Recurse -Force -ErrorAction Stop
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($KeyFreezeZipPath, $DownloadPath)
        }
        catch {
            Write-Host "Extracting with Shell.Application..." -ForegroundColor Yellow
            $Shell = New-Object -ComObject Shell.Application
            $Zip = $Shell.NameSpace($KeyFreezeZipPath)
            $Destination = $Shell.NameSpace($DownloadPath)
            $Destination.CopyHere($Zip.Items(), 4)
        }
        Write-Host "Files in extraction directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $DownloadPath -Recurse | ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Yellow
        }
        $KeyFreezeExecutable = Get-ChildItem -Path $KeyFreezeExtractPath -Recurse -Filter "KeyFreeze.exe" | Select-Object -First 1
        if (-Not $KeyFreezeExecutable) {
            throw "KeyFreeze executable not found in $KeyFreezeExtractPath"
        }
        Write-Verbose -Message "KeyFreeze extracted to: $($KeyFreezeExecutable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting KeyFreeze..." -ForegroundColor Green
            if ($CommandLineArgs) {
                Start-Process -FilePath $KeyFreezeExecutable.FullName -ArgumentList $CommandLineArgs
            }
            else {
                Start-Process -FilePath $KeyFreezeExecutable.FullName
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "KeyFreeze operation completed." -ForegroundColor Cyan
        if ($RemoveKeyFreeze) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
