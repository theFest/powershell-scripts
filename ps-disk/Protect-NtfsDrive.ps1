function Protect-NtfsDrive {
    <#
    .SYNOPSIS
    Downloads, extracts, and launches NTFS Drive Protection, a tool for protecting NTFS-formatted removable drives from malware by preventing unauthorized changes.

    .DESCRIPTION
    Helps safeguard your NTFS-formatted removable drives from malware by preventing the creation of unauthorized files, such as autorun.inf, which could compromise your system. Allows you to protect or unprotect NTFS drives, create unprotected folders, and use drag-and-drop functionality to manage file and folder protection.

    .EXAMPLE
    Protect-NtfsDrive -CommandLineArgs "E:\" -StartApplication
    Protect-NtfsDrive -RemoveNtfsDriveProtection

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for NTFS Drive Protection")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading NTFS Drive Protection")]
        [uri]$NtfsDriveProtectionDownloadUrl = "https://www.sordum.org/files/ntfs-drive-protection/Ntfs_drive_prot.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where NTFS Drive Protection will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\NtfsDriveProtection",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveNtfsDriveProtection,

        [Parameter(Mandatory = $false, HelpMessage = "Start the NTFS Drive Protection application after extraction")]
        [switch]$StartApplication
    )
    $NtfsDriveProtectionZipPath = Join-Path $DownloadPath "Ntfs_drive_prot.zip"
    $NtfsDriveProtectionExtractPath = Join-Path $DownloadPath "Ntfs_drive_protection"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $NtfsDriveProtectionZipPath)) {
            Write-Host "Downloading NTFS Drive Protection..." -ForegroundColor Green
            Invoke-WebRequest -Uri $NtfsDriveProtectionDownloadUrl -OutFile $NtfsDriveProtectionZipPath -UseBasicParsing -Verbose
            if ((Get-Item $NtfsDriveProtectionZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting NTFS Drive Protection..." -ForegroundColor Green
        if (Test-Path -Path $NtfsDriveProtectionExtractPath) {
            Remove-Item -Path $NtfsDriveProtectionExtractPath -Recurse -Force -ErrorAction Stop
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($NtfsDriveProtectionZipPath, $DownloadPath)
        }
        catch {
            Write-Host "Extracting with Shell.Application..." -ForegroundColor Yellow
            $Shell = New-Object -ComObject Shell.Application
            $Zip = $Shell.NameSpace($NtfsDriveProtectionZipPath)
            $Destination = $Shell.NameSpace($DownloadPath)
            $Destination.CopyHere($Zip.Items(), 4)
        }
        Write-Host "Files in extraction directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $DownloadPath -Recurse | ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Yellow
        }
        $NtfsDriveProtectionExecutable = Get-ChildItem -Path $NtfsDriveProtectionExtractPath -Recurse -Filter "DriveProtect_x64.exe" | Select-Object -First 1
        if (-Not $NtfsDriveProtectionExecutable) {
            throw "NTFS Drive Protection executable not found in $NtfsDriveProtectionExtractPath"
        }
        Write-Verbose -Message "NTFS Drive Protection extracted to: $($NtfsDriveProtectionExecutable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting NTFS Drive Protection..." -ForegroundColor Green
            if ($CommandLineArgs) {
                Start-Process -FilePath $NtfsDriveProtectionExecutable.FullName -ArgumentList $CommandLineArgs
            }
            else {
                Start-Process -FilePath $NtfsDriveProtectionExecutable.FullName
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "NTFS Drive Protection operation completed." -ForegroundColor Cyan
        if ($RemoveNtfsDriveProtection) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
