function Block-AppRun {
    <#
    .SYNOPSIS
    Downloads, extracts, and launches Simple Run Blocker (SRB), a tool for blocking or whitelisting applications.

    .DESCRIPTION
    Simple Run Blocker is a portable utility that allows you to block specific applications from running on your computer or block all applications except for those on a whitelist.

    .EXAMPLE
    Block-AppRun -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for Simple Run Blocker")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Simple Run Blocker")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/simple-run-blocker/RunBlock.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Simple Run Blocker will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\SimpleRunBlocker",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Simple Run Blocker application after extraction")]
        [switch]$StartApplication
    )
    $ZipFilePath = Join-Path $DownloadPath "RunBlock.zip"
    $ExtractPath = Join-Path $DownloadPath "RunBlock"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Simple Run Blocker..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Simple Run Blocker..." -ForegroundColor Green
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
        $Executable = Get-ChildItem -Path $ExtractPath -Recurse -Filter "RunBlock.exe" | Select-Object -First 1
        if (-Not $Executable) {
            throw "Simple Run Blocker executable not found in $ExtractPath"
        }
        Write-Verbose -Message "Simple Run Blocker extracted to: $($Executable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting Simple Run Blocker..." -ForegroundColor Green
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
        Write-Host "Simple Run Blocker operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
