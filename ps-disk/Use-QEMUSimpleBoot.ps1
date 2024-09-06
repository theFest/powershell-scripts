function Use-QEMUSimpleBoot {
    <#
    .SYNOPSIS
    Downloads, extracts, and launches QEMU Simple Boot for testing ISO, IMA, or IMG files.

    .DESCRIPTION
    This function downloads and extracts QEMU Simple Boot, then starts the application. Users need to manually drag and drop files or use the UI to select and test image files.

    .EXAMPLE
    Use-QEMUSimpleBoot -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading QEMU Simple Boot")]
        [uri]$QEMUDownloadUrl = "https://www.sordum.org/files/qemu-simple-boot/qsiboot_v1.3.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where QEMU Simple Boot will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\QEMU-Simple-Boot",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveQEMU,

        [Parameter(Mandatory = $false, HelpMessage = "Start the QEMU Simple Boot application after extraction")]
        [switch]$StartApplication
    )
    $QEMUZipPath = Join-Path $DownloadPath "qsiboot_v1.3.zip"
    $QEMUExtractPath = Join-Path $DownloadPath "qsib_v1.3"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path $QEMUZipPath)) {
            Write-Host "Downloading QEMU Simple Boot..." -ForegroundColor Green
            Invoke-WebRequest -Uri $QEMUDownloadUrl -OutFile $QEMUZipPath -UseBasicParsing -Verbose
            if ((Get-Item $QEMUZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting QEMU Simple Boot..." -ForegroundColor Green
        if (Test-Path -Path $QEMUExtractPath) {
            Remove-Item -Path $QEMUExtractPath -Recurse -Force
        }
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($QEMUZipPath, $DownloadPath)
        }
        catch {
            throw "Failed to extract the ZIP file. It may be corrupt or incomplete."
        }
        $QEMUExecutable = Get-ChildItem -Path $QEMUExtractPath -Recurse -Filter "Qsib.exe" | Select-Object -First 1
        if (-Not $QEMUExecutable) {
            throw "Qsib.exe not found in $QEMUExtractPath"
        }
        Write-Verbose -Message "QEMU Simple Boot extracted to: $($QEMUExecutable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting QEMU Simple Boot..." -ForegroundColor Green
            Start-Process -FilePath $QEMUExecutable.FullName
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "QEMU Simple Boot operation completed." -ForegroundColor Cyan
        if ($RemoveQEMU) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
