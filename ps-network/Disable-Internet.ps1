function Disable-Internet {
    <#
    .SYNOPSIS
    Downloads, extracts, and launches Net Disabler, a tool for temporarily disabling internet connectivity.

    .DESCRIPTION
    Net Disabler is a portable utility that allows you to disable the internet using various methods, such as disabling the network adapter, blocking with DNS, Proxy, or Firewall.

    .EXAMPLE
    Disable-Internet -StartApplication
    Disable-Internet -CommandLineArgs "/Q"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for Net Disabler")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Net Disabler")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/net-disabler/NetDisabler.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Net Disabler will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\NetDisabler",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Net Disabler application after extraction")]
        [switch]$StartApplication
    )
    $ZipFilePath = Join-Path $DownloadPath "NetDisabler.zip"
    $ExtractPath = Join-Path $DownloadPath "NetDisabler"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Net Disabler..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Net Disabler..." -ForegroundColor Green
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
        $Executable = Get-ChildItem -Path $ExtractPath -Recurse -Filter "NetDisabler.exe" | Select-Object -First 1
        if (-Not $Executable) {
            throw "Net Disabler executable not found in $ExtractPath"
        }
        Write-Verbose -Message "Net Disabler extracted to: $($Executable.FullName)"
        if ($StartApplication) {
            Write-Host "Starting Net Disabler..." -ForegroundColor Green
            if ($CommandLineArgs) {
                Start-Process -FilePath $Executable.FullName -ArgumentList $CommandLineArgs
            }
            else {
                Start-Process -FilePath $Executable.FullName
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Net Disabler operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
