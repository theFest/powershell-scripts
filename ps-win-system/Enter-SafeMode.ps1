function Enter-SafeMode {
    <#
    .SYNOPSIS
    Launches Safe Mode or applies various Safe Mode settings using the Safe Mode Launcher tool.

    .DESCRIPTION
    This function manages the Safe Mode Launcher tool, which provides options to start Windows in Safe Mode, adjust boot menu settings, and more. It supports command-line parameters for these actions.

    .EXAMPLE
    Enter-SafeMode -Command Normal
    Enter-SafeMode -Command Minimal -Silent -Reboot
    Enter-SafeMode -BootMenu On
    Enter-SafeMode -F8StartupKey On

    .NOTES
    The command to execute with the Safe Mode Launcher tool. Valid options are:
    - Normal: Start Windows normally.
    - Minimal: Safe Mode.
    - Network: Safe Mode with Networking.
    - MinimalCMD: Safe Mode with Command Prompt.
    - DsRepair: Safe Mode with Active Directory Repair.
    - Troubleshoot: Start Troubleshoot.
    - Reboot: Restart Windows.
    - Silent: Don't Show Message.
    BootMenu shows or hides the boot menu at system startup. Valid options are:
    - On: Shows the boot menu.
    - Off: Hides the boot menu.
    F8StartupKey activates or disables the F8 keyboard shortcut at system startup. Valid options are:
    - On: Activates the F8 key.
    - Off: Disables the F8 key.
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify the command to execute: Normal, Minimal, Network, MinimalCMD, DsRepair, Troubleshoot, Reboot, Silent.")]
        [ValidateSet("Normal", "Minimal", "Network", "MinimalCMD", "DsRepair", "Troubleshoot", "Reboot", "Silent")]
        [string]$Command = "Normal",

        [Parameter(Mandatory = $false, HelpMessage = "Show or hide the boot menu at system startup")]
        [ValidateSet("On", "Off")]
        [string]$BootMenu,

        [Parameter(Mandatory = $false, HelpMessage = "Activate or disable the F8 keyboard shortcut at system startup")]
        [ValidateSet("On", "Off")]
        [string]$F8StartupKey,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Safe Mode Launcher tool.")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/safe-mode-launcher/SafeMode.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Safe Mode Launcher tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\SafeModeTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "SafeMode.zip"
    $ExtractPath = Join-Path $DownloadPath "SafeMode"
    $Executable = Join-Path $ExtractPath "SafeMode_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Safe Mode Launcher tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Safe Mode Launcher tool..." -ForegroundColor Green
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
            throw "Safe Mode Launcher executable not found at $ExtractPath"
        }
        Write-Verbose -Message "Safe Mode Launcher executable located at: $($Executable)"
        $Arguments = @()
        if ($Command) {
            $Arguments += "/$Command"
        }
        if ($BootMenu) {
            $Arguments += "/BootMenu:$BootMenu"
        }
        if ($F8StartupKey) {
            $Arguments += "/F8StartupKey:$F8StartupKey"
        }
        if ($Arguments.Count -gt 0) {
            Write-Host "Executing Safe Mode Launcher with arguments: $($Arguments -join ' ')" -ForegroundColor Green
            Start-Process -FilePath $Executable -ArgumentList ($Arguments -join ' ') -Wait
        }
        else {
            Write-Host "No valid command specified."
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Safe Mode Launcher operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
