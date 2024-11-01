function Use-6to4Remover {
    <#
    .SYNOPSIS
    Downloads, extracts, and runs the 6to4 Adapter Remover tool to remove unwanted 6to4 adapters from the system.

    .DESCRIPTION
    The 6to4 Adapter Remover is used to remove redundant Microsoft 6to4 adapters from Device Manager, which may appear due to a Windows bug.

    .EXAMPLE
    Use-6to4Remover -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for the 6to4 Adapter Remover")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading 6to4 Adapter Remover")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/6to4-remover/6to4remover.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where 6to4 Adapter Remover will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\6to4Remover",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the 6to4 Adapter Remover application after extraction")]
        [switch]$StartApplication
    )
    $ZipFilePath = Join-Path $DownloadPath "6to4remover.zip"
    $ExtractPath = Join-Path $DownloadPath "6to4remover_v1.2"
    $Executable = Join-Path $ExtractPath "6to4remover.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading 6to4 Adapter Remover..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting 6to4 Adapter Remover..." -ForegroundColor Green
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
            throw "6to4 Adapter Remover executable not found in $ExtractPath"
        }
        Write-Verbose -Message "6to4 Adapter Remover executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting 6to4 Adapter Remover..." -ForegroundColor Green
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
        Write-Host "6to4 Adapter Remover operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
