function Restart-Explorer {
    <#
    .SYNOPSIS
    Restarts Windows Explorer or performs other related actions.

    .DESCRIPTION
    This function manages the Restart Explorer tool, which provides options to restart Windows Explorer, refresh it, or rebuild the icon cache. It supports command-line parameters for these actions.

    .EXAMPLE
    Restart-Explorer -Command Restart
    Restart-Explorer -Command Wait -WaitTime 5
    Restart-Explorer -Command Refresh
    Restart-Explorer -Command RebuildIconCache
    Restart-Explorer -Command Start

    .NOTES
    The command to execute with the Restart Explorer tool. Valid options are:
    - Restart: Restart Windows Explorer without opening any folders.
    - Wait: Wait a specified number of seconds before restarting Explorer.
    - Refresh: Refresh Windows Explorer.
    - RebuildIconCache: Rebuild the icon cache.
    - Start: Start the application.
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command to execute: Restart, Wait, Refresh, RebuildIconCache, Start.")]
        [ValidateSet("Restart", "Wait", "Refresh", "RebuildIconCache", "Start")]
        [string]$Command = "Restart",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the number of seconds to wait before restarting Explorer")]
        [int]$WaitTime = 0,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Restart Explorer tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/restart-explorer/Rexplorer_v1.7.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Restart Explorer tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\RestartExplorerTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "Rexplorer_v1.7.zip"
    $ExtractPath = Join-Path $DownloadPath "Rexplorer"
    $Executable = Join-Path $ExtractPath "Rexplorer_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Restart Explorer tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Restart Explorer tool..." -ForegroundColor Green
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
            throw "Restart Explorer executable not found at $ExtractPath"
        }
        Write-Verbose -Message "Restart Explorer executable located at: $($Executable)"
        switch ($Command) {
            "Restart" {
                Write-Host "Restarting Windows Explorer..." -ForegroundColor Green
                Start-Process -FilePath $Executable -ArgumentList "/R" -Wait
            }
            "Wait" {
                if ($WaitTime -le 0) {
                    throw "WaitTime must be greater than 0 for the Wait command."
                }
                Write-Host "Waiting for $WaitTime seconds before restarting Windows Explorer..." -ForegroundColor Green
                Start-Sleep -Seconds $WaitTime
                Write-Host "Restarting Windows Explorer..." -ForegroundColor Green
                Start-Process -FilePath $Executable -ArgumentList "/R" -Wait
            }
            "Refresh" {
                Write-Host "Refreshing Windows Explorer..." -ForegroundColor Green
                Start-Process -FilePath $Executable -ArgumentList "/F" -Wait
            }
            "RebuildIconCache" {
                Write-Host "Rebuilding icon cache..." -ForegroundColor Green
                Start-Process -FilePath $Executable -ArgumentList "/l" -Wait
                Write-Host "Restarting Windows Explorer..." -ForegroundColor Green
                Start-Process -FilePath $Executable -ArgumentList "/R" -Wait
            }
            "Start" {
                Write-Host "Starting the Restart Explorer application..." -ForegroundColor Green
                Start-Process -FilePath $Executable
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Restart Explorer operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
