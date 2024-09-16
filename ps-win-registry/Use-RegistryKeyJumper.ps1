function Use-RegistryKeyJumper {
    <#
    .SYNOPSIS
    Downloads, extracts, and runs Registry Key Jumper to manage Windows registry key navigation.

    .DESCRIPTION
    Registry Key Jumper allows users to quickly navigate to registry keys in Windows. This function downloads, extracts, and runs the tool with optional registry key arguments.

    .EXAMPLE
    Use-RegistryKeyJumper -StartApplication
    Use-RegistryKeyJumper -RegistryKey "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "The registry key to jump to")]
        [string]$RegistryKey,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Registry Key Jumper tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/registry-key-jumper/RegJump.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Registry Key Jumper tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\RegistryKeyJumper",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Registry Key Jumper application after extraction")]
        [switch]$StartApplication
    )
    $ZipFilePath = Join-Path $DownloadPath "RegJump.zip"
    $ExtractPath = Join-Path $DownloadPath "RegJump"
    $Executable_x64 = Join-Path $ExtractPath "RegJump_x64.exe"
    $Executable_x86 = Join-Path $ExtractPath "RegJump.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Registry Key Jumper tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Registry Key Jumper tool..." -ForegroundColor Green
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
        $Executable = if ([Environment]::Is64BitOperatingSystem) {
            $Executable_x64
        }
        else {
            $Executable_x86
        }
        if (-Not (Test-Path -Path $Executable)) {
            throw "Registry Key Jumper executable not found in $ExtractPath"
        }
        Write-Verbose -Message "Registry Key Jumper executable located at: $($Executable)"
        if ($StartApplication -or $RegistryKey) {
            Write-Host "Starting Registry Key Jumper tool..." -ForegroundColor Green
            if ($RegistryKey) {
                Start-Process -FilePath $Executable -ArgumentList $RegistryKey
            }
            else {
                Start-Process -FilePath $Executable
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Registry Key Jumper tool operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
