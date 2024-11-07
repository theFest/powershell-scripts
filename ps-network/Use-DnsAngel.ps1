function Use-DnsAngel {
    <#
    .SYNOPSIS
    Downloads, extracts, and manages the DnsAngel application.

    .DESCRIPTION
    This function downloads and extracts DnsAngel. After extraction, it can start the tool to change DNS settings.

    .EXAMPLE
    Use-DnsAngel -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the DnsAngel")]
        [uri]$DnsAngelDownloadUrl = "https://www.sordum.org/files/download/dns-angel/DnsAngel.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the DnsAngel will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\DnsAngel",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveDnsAngel,

        [Parameter(Mandatory = $false, HelpMessage = "Start the DnsAngel application after extraction")]
        [switch]$StartApplication
    )
    $DnsAngelZipPath = Join-Path $DownloadPath "DnsAngel.zip"
    $DnsAngelExtractPath = Join-Path $DownloadPath "DnsAngel"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path $DnsAngelZipPath)) {
            Write-Host "Downloading DnsAngel..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DnsAngelDownloadUrl -OutFile $DnsAngelZipPath -UseBasicParsing -Verbose
            if ((Get-Item $DnsAngelZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting DnsAngel..." -ForegroundColor Green
        if (Test-Path -Path $DnsAngelExtractPath) {
            Remove-Item -Path $DnsAngelExtractPath -Recurse -Force
        }
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($DnsAngelZipPath, $DownloadPath)
        }
        catch {
            throw "Failed to extract the ZIP file. It may be corrupt or incomplete."
        }
        $DnsAngelExecutable = Get-ChildItem -Path $DnsAngelExtractPath -Recurse -Filter "DnsAngel.exe" | Select-Object -First 1
        if (-Not $DnsAngelExecutable) {
            throw "DnsAngel.exe not found in $DnsAngelExtractPath"
        }
        Write-Verbose -Message "DnsAngel extracted to: $($DnsAngelExecutable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting DnsAngel..." -ForegroundColor Green
            Start-Process -FilePath $DnsAngelExecutable.FullName
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "DnsAngel operation completed." -ForegroundColor Cyan
        if ($RemoveDnsAngel) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
