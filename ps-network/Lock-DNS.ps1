function Lock-DNS {
    <#
    .SYNOPSIS
    Installs or uninstalls the DNS Lock service to keep DNS settings constant.

    .DESCRIPTION
    This function manages the DNS Lock tool, which prevents malware or other software from changing your DNS settings. It allows you to install or uninstall the service that locks your DNS configuration.

    .EXAMPLE
    Lock-DNS -StartApplication
    Lock-DNS -Command Install -DnsAddresses "8.8.8.8,8.8.4.4"
    Lock-DNS -Command Install -DnsAddresses "2001:4860:4860::8888,2001:4860:4860::8844"
    Lock-DNS -Command Uninstall

    .NOTES
    The command to execute with DNS Lock tool. Valid options are:
    - Install: Install the DNS Lock service with specified DNS addresses.
    - Uninstall: Uninstall the DNS Lock service.
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify the command to execute: Install, Uninstall, None")]
        [ValidateSet("Install", "Uninstall", "None")]
        [string]$Command = "None",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the DNS addresses to lock, comma-separated")]
        [string]$DnsAddresses = "",

        [Parameter(Mandatory = $false, HelpMessage = "Start the DNS Lock GUI")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading DNS Lock tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/dns-lock/DNS-Lock.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where DNS Lock tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\DnsLockTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "DNS-Lock.zip"
    $ExtractPath = Join-Path $DownloadPath "DNS-Lock"
    $Executable = Join-Path $ExtractPath "DNS-Lock_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading DNS Lock tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting DNS Lock tool..." -ForegroundColor Green
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
            throw "DNS Lock executable not found in $ExtractPath"
        }
        Write-Verbose -Message "DNS Lock executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Launching DNS Lock GUI..." -ForegroundColor Green
            Start-Process -FilePath $Executable -Wait
        }
        else {
            $cmdParameter = switch ($Command) {
                "Install" {
                    if ($DnsAddresses -ne "") {
                        "/I $DnsAddresses"
                    }
                    else {
                        throw "DNS addresses must be specified for installation."
                    }
                }
                "Uninstall" { "/U" }
                "None" { "" }
            }
            Write-Host "Executing DNS Lock command: $cmdParameter" -ForegroundColor Green
            if ($cmdParameter -ne "") {
                Start-Process -FilePath $Executable -ArgumentList $cmdParameter -Wait
            }
            else {
                Write-Host "No command specified, use -StartApplication to launch the GUI or provide a valid command."
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "DNS Lock operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
