function Install-Win11ClassicMenu {
    <#
    .SYNOPSIS
    Executes operations using the Windows 11 Classic Context Menu tool.

    .DESCRIPTION
    This function downloads and executes W11ClassicMenu to enable or disable the Windows 11 classic context menu style.

    .EXAMPLE
    Install-Win11ClassicMenu -Command '/C'
    Install-Win11ClassicMenu -Command '/D'
    Install-Win11ClassicMenu -Command '/C' -RestartExplorer

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the command to execute with W11ClassicMenu.exe")]
        [ValidateSet('/C', '/D')]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the Windows 11 Classic Context Menu tool")]
        [uri]$Win11ClassicMenuDownloadUrl = "https://www.sordum.org/files/download/win11-classic-context-menu/W11ClassicMenu.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the Windows 11 Classic Context Menu tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\Win11ClassicMenu",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveWin11ClassicMenu,

        [Parameter(Mandatory = $false, HelpMessage = "Restart Windows Explorer after applying the context menu changes")]
        [switch]$RestartExplorer,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Windows 11 Classic Context Menu application after extraction")]
        [switch]$StartApplication
    )
    $Win11ClassicMenuZipPath = Join-Path $DownloadPath "W11ClassicMenu.zip"
    $Win11ClassicMenuExtractPath = Join-Path $DownloadPath "W11ClassicMenu"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path $Win11ClassicMenuZipPath)) {
            Write-Host "Downloading Windows 11 Classic Context Menu tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $Win11ClassicMenuDownloadUrl -OutFile $Win11ClassicMenuZipPath -UseBasicParsing -Verbose
            if ((Get-Item $Win11ClassicMenuZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Windows 11 Classic Context Menu tool..." -ForegroundColor Green
        if (Test-Path -Path $Win11ClassicMenuExtractPath) {
            Remove-Item -Path $Win11ClassicMenuExtractPath -Recurse -Force
        }
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($Win11ClassicMenuZipPath, $DownloadPath)
        }
        catch {
            throw "Failed to extract the ZIP file. It may be corrupt or incomplete."
        }
        $Win11ClassicMenuExecutable = Join-Path $Win11ClassicMenuExtractPath "W11ClassicMenu.exe"
        if (-Not (Test-Path -Path $Win11ClassicMenuExecutable)) {
            throw "W11ClassicMenu.exe not found in $Win11ClassicMenuExtractPath"
        }
        $Arguments = $Command
        if ($RestartExplorer) {
            $Arguments += " /R"
        }
        Write-Verbose -Message "Starting Windows 11 Classic Context Menu with arguments: $Arguments"
        if ($StartApplication) {
            Start-Process -FilePath $Win11ClassicMenuExecutable -ArgumentList $Arguments
        }
        else {
            Start-Process -FilePath $Win11ClassicMenuExecutable -ArgumentList $Arguments -WindowStyle Hidden -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Windows 11 Classic Context Menu operation '$Command' completed." -ForegroundColor Cyan
        if ($RemoveWin11ClassicMenu) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
