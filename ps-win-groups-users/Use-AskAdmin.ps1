function Use-AskAdmin {
    <#
    .SYNOPSIS
    Downloads, extracts, and manages the AskAdmin application.

    .DESCRIPTION
    This function downloads and extracts AskAdmin. After extraction, it can start the tool to block or unblock applications, files, and folders manually.

    .EXAMPLE
    Use-AskAdmin -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading AskAdmin")]
        [uri]$AskAdminDownloadUrl = "https://www.sordum.org/files/download/ask-admin/AskAdmin.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where AskAdmin will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\AskAdmin",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveAskAdmin,

        [Parameter(Mandatory = $false, HelpMessage = "Start the AskAdmin application after extraction")]
        [switch]$StartApplication
    )
    $AskAdminZipPath = Join-Path $DownloadPath "AskAdmin.zip"
    $AskAdminExtractPath = Join-Path $DownloadPath "AskAdmin"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path $AskAdminZipPath)) {
            Write-Host "Downloading AskAdmin..." -ForegroundColor Green
            Invoke-WebRequest -Uri $AskAdminDownloadUrl -OutFile $AskAdminZipPath -UseBasicParsing -Verbose
            if ((Get-Item $AskAdminZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting AskAdmin..." -ForegroundColor Green
        if (Test-Path -Path $AskAdminExtractPath) {
            Remove-Item -Path $AskAdminExtractPath -Recurse -Force
        }
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($AskAdminZipPath, $DownloadPath)
        }
        catch {
            throw "Failed to extract the ZIP file. It may be corrupt or incomplete."
        }
        $AskAdminExecutable = Get-ChildItem -Path $AskAdminExtractPath -Recurse -Filter "AskAdmin.exe" | Select-Object -First 1
        if (-Not $AskAdminExecutable) {
            throw "AskAdmin.exe not found in $AskAdminExtractPath"
        }
        Write-Verbose -Message "AskAdmin extracted to: $($AskAdminExecutable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting AskAdmin..." -ForegroundColor Green
            Start-Process -FilePath $AskAdminExecutable.FullName
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "AskAdmin operation completed." -ForegroundColor Cyan
        if ($RemoveAskAdmin) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
