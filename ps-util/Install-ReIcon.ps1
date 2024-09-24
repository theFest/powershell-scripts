function Install-ReIcon {
    <#
    .SYNOPSIS
    Executes operations using the ReIcon tool to save or restore desktop icon layouts.

    .DESCRIPTION
    This function downloads and executes ReIcon to save or restore desktop icon layouts.

    .EXAMPLE
    Install-ReIcon -Command '/S'
    Install-ReIcon -Command '/R' -File 'C:\Path\To\Layout.ini'
    Install-ReIcon -Command '/S' -File 'C:\Path\To\NewLayout.ini' -LayoutName 'New Layout'
    Install-ReIcon -Command '/R' -File 'C:\Path\To\Layout.ini' -LayoutID 'abc'

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the command to execute with ReIcon.exe")]
        [ValidateSet('/S', '/R')]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "File path for saving or restoring desktop icon layout")]
        [string]$File,

        [Parameter(Mandatory = $false, HelpMessage = "Desktop icon layout ID or order")]
        [string]$LayoutID,

        [Parameter(Mandatory = $false, HelpMessage = "Name for the desktop icon layout")]
        [string]$LayoutName,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the ReIcon tool")]
        [uri]$ReIconDownloadUrl = "https://www.sordum.org/files/download/restore-desktop-icon-layouts/ReIcon.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the ReIcon tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\ReIcon",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveReIcon,

        [Parameter(Mandatory = $false, HelpMessage = "Start the ReIcon application after extraction")]
        [switch]$StartApplication
    )
    $ReIconZipPath = Join-Path $DownloadPath "ReIcon.zip"
    $ReIconExtractPath = Join-Path $DownloadPath "ReIcon"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path $ReIconZipPath)) {
            Write-Host "Downloading ReIcon tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $ReIconDownloadUrl -OutFile $ReIconZipPath -UseBasicParsing -Verbose
            if ((Get-Item $ReIconZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting ReIcon tool..." -ForegroundColor Green
        if (Test-Path -Path $ReIconExtractPath) {
            Remove-Item -Path $ReIconExtractPath -Recurse -Force
        }
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ReIconZipPath, $DownloadPath)
        }
        catch {
            throw "Failed to extract the ZIP file. It may be corrupt or incomplete."
        }
        $ReIconExecutable = Get-ChildItem -Path $ReIconExtractPath -Recurse -Filter "ReIcon_x64.exe" | Select-Object -First 1
        if (-Not $ReIconExecutable) {
            $ReIconExecutable = Get-ChildItem -Path $ReIconExtractPath -Recurse -Filter "ReIcon_x86.exe" | Select-Object -First 1
        }
        if (-Not $ReIconExecutable) {
            throw "ReIcon_x64.exe or ReIcon_x86.exe not found in $ReIconExtractPath"
        }
        $Arguments = $Command
        if ($File) {
            $Arguments += " $File"
        }
        if ($LayoutID) {
            $Arguments += " /dD $LayoutID"
        }
        if ($LayoutName) {
            $Arguments += " /dL $LayoutName"
        }
        Write-Verbose -Message "Starting ReIcon with arguments: $Arguments"
        if ($StartApplication) {
            Start-Process -FilePath $ReIconExecutable.FullName
        }
        else {
            Start-Process -FilePath $ReIconExecutable.FullName -ArgumentList $Arguments -WindowStyle Hidden -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "ReIcon operation '$Command' completed." -ForegroundColor Cyan
        if ($RemoveReIcon) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
