Function Disable-WindowsUpdate {
    <#
    .SYNOPSIS
    Disables Windows Update and protects it using the Windows Update disabler (WUB).

    .DESCRIPTION
    This function downloads and executes the Windows Update disabler (WUB) to disable Windows Update and protect it from being re-enabled. Credits to Sordum.

    .PARAMETER UpdateOperation
    Operation to perform on Windows Update, accepts "/D" for Disable, "/E" for Enable, and "/D /P" for Disable & Protect.
    .PARAMETER WubDownloadUrl
    URL for downloading the Windows Update disabler (WUB), default URL: https://www.sordum.org/files/downloads.php?st-windows-update-blocker.
    .PARAMETER WubVersion
    Specifies the version of the Windows Update disabler (WUB) to download, default version: 1.8.
    .PARAMETER DownloadPath
    Path to the directory where the WUB will be downloaded and extracted, default path: $env:TEMP\WU_Disable.
    .PARAMETER RemoveWUB
    If present, removes the temporary folder after the operation.
    .PARAMETER Restart
    If present, restarts the computer after the operation.

    .EXAMPLE
    Disable-WindowsUpdate -UpdateOperation '/D /P' -Restart

    .NOTES
    v0.4.9
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "'/D' --> Disable | '/E' --> Enable | '/D /P' --> Disable & Protect")]
        [ValidateSet("/D", "/E", "/D /P")]
        [string]$UpdateOperation = "/D /P",

        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "URL for downloading the Windows Update disabler (WUB)")]
        [uri]$WubDownloadUrl = "https://www.sordum.org/files/downloads.php?st-windows-update-blocker",

        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Version of the Windows Update disabler (WUB) to download")]
        [string]$WubVersion = "1.8",

        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Path to the directory where the WUB will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\WU_Disable",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveWUB,

        [Parameter(Mandatory = $false, HelpMessage = "Restart the computer after the operation")]
        [switch]$Restart
    )
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        $WubZipPath = Join-Path $DownloadPath "Wub_v$WubVersion.zip"
        if (!(Test-Path -Path $WubZipPath)) {
            Write-Host "Downloading Windows Update disabler..." -ForegroundColor Green
            Invoke-WebRequest -Uri $WubDownloadUrl -OutFile $WubZipPath -UseBasicParsing -Verbose
        }
        $WubExtractPath = Join-Path $DownloadPath "Wub"
        Write-Host "Extracting Windows Update disabler..." -ForegroundColor Green
        Expand-Archive -Path $WubZipPath -DestinationPath $WubExtractPath -Force -Verbose
        Clear-Host
        Write-Verbose -Message "Downloaded and expanded, starting Wub to $UpdateOperation updates..."
        Start-Process cmd -ArgumentList "/c $($WubExtractPath)\Wub_x64.exe $UpdateOperation" -WindowStyle Minimized -Wait
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        $servicesStatus = Get-Service -Name 'wuauserv', 'WaaSMedicSvc' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status
        $statusMessage = if ($servicesStatus -eq 'Stopped') { "disabled" } else { "enabled" }
        Write-Host "Windows Update services $statusMessage" -ForegroundColor Cyan
    }
    if ($RemoveWUB) {
        Write-Warning -Message "Cleaning up, removing the temporary folder..."
        Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
    }
    if ($Restart) {
        Write-Warning -Message "Restarting computer..."
        Restart-Computer -Force
    }
}
