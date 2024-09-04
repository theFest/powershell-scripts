function Show-RouterDefaultPassword {
    <#
    .SYNOPSIS
    Downloads, extracts, and launches Router Default Password, a tool for displaying default router passwords.

    .DESCRIPTION
    Router Default Password is a free, portable application that helps you find the default router username and password.

    .EXAMPLE
    Show-RouterDefaultPassword -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for Router Default Password")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Router Default Password")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/router-default-passwords/RouterDP.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Router Default Password will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\RouterDefaultPassword",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Router Default Password application after extraction")]
        [switch]$StartApplication
    )
    $ZipFilePath = Join-Path $DownloadPath "RouterDP.zip"
    $ExtractPath = Join-Path $DownloadPath "RouterDP"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Router Default Password..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Router Default Password..." -ForegroundColor Green
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
        $Executable = Get-ChildItem -Path $ExtractPath -Recurse -Filter "RouterDP.exe" | Select-Object -First 1
        if (-Not $Executable) {
            throw "Router Default Password executable not found in $ExtractPath"
        }
        Write-Verbose -Message "Router Default Password extracted to: $($Executable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting Router Default Password..." -ForegroundColor Green
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
        Write-Host "Router Default Password operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
