function Use-DnsJumper {
    <#
    .SYNOPSIS
    Configures DNS settings using the DnsJumper tool.

    .DESCRIPTION
    This function downloads and executes DnsJumper to manage DNS settings, including applying default DNS servers, backing up/restoring DNS configurations, and flushing the DNS cache. Credits to Sordum.

    .EXAMPLE
    Use-DnsJumper
    Use-DnsJumper -DnsOperation '/B /F' -CustomDns '8.8.8.8,8.8.4.4' -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "'/D' --> Apply default DNS | '/B' --> Backup DNS | '/R' --> Restore DNS | '/F' --> Flush DNS cache | '/T' --> Test and apply fastest DNS")]
        [string]$DnsOperation = "/D",

        [Parameter(Mandatory = $false, HelpMessage = "Custom DNS servers to apply, comma-separated (e.g., '8.8.8.8,8.8.4.4')")]
        [string]$CustomDns = "",

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the DnsJumper tool")]
        [uri]$DnsJumperDownloadUrl = "https://www.sordum.org/files/downloads.php?dns-jumper",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the DnsJumper tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\DnsJumper",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveDnsJumper
    )
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        $DnsJumperZipPath = Join-Path $DownloadPath "DnsJumper.zip"
        if (!(Test-Path -Path $DnsJumperZipPath)) {
            Write-Host "Downloading DnsJumper tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DnsJumperDownloadUrl -OutFile $DnsJumperZipPath -UseBasicParsing -Verbose
        }
        $DnsJumperExtractPath = Join-Path $DownloadPath "DnsJumper"
        Write-Host "Extracting DnsJumper tool..." -ForegroundColor Green
        Expand-Archive -Path $DnsJumperZipPath -DestinationPath $DnsJumperExtractPath -Force -Verbose
        $DnsJumperExecutable = Get-ChildItem -Path $DnsJumperExtractPath -Recurse -Filter "DnsJumper.exe" | Select-Object -First 1
        if (-Not $DnsJumperExecutable) {
            throw "DnsJumper.exe not found in $DnsJumperExtractPath"
        }
        $Arguments = if ($CustomDns) { "$DnsOperation $CustomDns" } else { $DnsOperation }
        Write-Verbose -Message "Starting DnsJumper with arguments: $Arguments"
        Start-Process -FilePath "$env:TEMP\DnsJumper\DnsJumper\DnsJumper\DnsJumper.exe"
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "DNS operation '$DnsOperation' completed." -ForegroundColor Cyan
    }
    if ($RemoveDnsJumper) {
        Write-Warning -Message "Cleaning up, removing the temporary folder..."
        Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
    }
}
