function Use-RATool {
    <#
    .SYNOPSIS
    Downloads and executes the Removable Access Tool.

    .DESCRIPTION
    This function downloads and executes RATool.exe to enable or disable access to removable drives. Since RATool does not support command-line arguments, you need to manually interact with the tool after extraction.

    .EXAMPLE
    Use-RATool -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the RATool")]
        [uri]$RAToolDownloadUrl = "https://www.sordum.org/files/download/ratool/Ratool.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the RATool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\RATool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveRATool,

        [Parameter(Mandatory = $false, HelpMessage = "Start the RATool application after extraction")]
        [switch]$StartApplication
    )
    $RAToolZipPath = Join-Path $DownloadPath "RATool.zip"
    $RAToolExtractPath = Join-Path $DownloadPath "Ratool_v1.4"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path $RAToolZipPath)) {
            Write-Host "Downloading RATool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $RAToolDownloadUrl -OutFile $RAToolZipPath -UseBasicParsing -Verbose
            if ((Get-Item $RAToolZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting RATool..." -ForegroundColor Green
        if (Test-Path -Path $RAToolExtractPath) {
            Remove-Item -Path $RAToolExtractPath -Recurse -Force
        }
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($RAToolZipPath, $DownloadPath)
        }
        catch {
            throw "Failed to extract the ZIP file. It may be corrupt or incomplete."
        }
        $RAToolExecutable = Get-ChildItem -Path $RAToolExtractPath -Recurse -Filter "Ratool_x64.exe" | Select-Object -First 1
        if (-Not $RAToolExecutable) {
            throw "Ratool_x64.exe not found in $RAToolExtractPath"
        }
        Write-Verbose -Message "RATool extracted to: $($RAToolExecutable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting RATool..." -ForegroundColor Green
            Start-Process -FilePath $RAToolExecutable.FullName
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "RATool operation completed." -ForegroundColor Cyan
        if ($RemoveRATool) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
