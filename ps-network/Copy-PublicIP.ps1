function Copy-PublicIP {
    <#
    .SYNOPSIS
    Manages the Copy Public IP tool to get and copy your public IP address.

    .DESCRIPTION
    This function uses the Copy Public IP tool to copy, print, or display your public IP address.

    .EXAMPLE
    Copy-PublicIP -StartApplication -Command "/C"
    Copy-PublicIP -StartApplication -Command "/P"
    Copy-PublicIP -StartApplication -Command "/M"
    Copy-PublicIP -StartApplication -Command "/C /P"

    .NOTES
    The command to execute with the CopyPublicIP tool. Valid options are:
    - /C : Copy public IP address to clipboard
    - /M : Show popup message
    - /P : Print public IP address to Console
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Copy Public IP application")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Command-line parameters for the Copy Public IP tool")]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Copy Public IP tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/copy-public-ip/CopyIP.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Copy Public IP tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\CopyPublicIPTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "CopyIP.zip"
    $ExtractPath = Join-Path $DownloadPath "CopyIP"
    $Executable = Join-Path $ExtractPath "CopyIP.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Copy Public IP tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Copy Public IP tool..." -ForegroundColor Green
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
            throw "Copy Public IP executable not found at $ExtractPath"
        }
        Write-Verbose -Message "Copy Public IP executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Copy Public IP application..." -ForegroundColor Green
            if ($Command) {
                Start-Process -FilePath $Executable -ArgumentList $Command -Wait
            }
            else {
                Start-Process -FilePath $Executable -Wait
            }
        }
        else {
            Write-Host "No action specified. Use -StartApplication to launch the tool with commands."
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Copy Public IP operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
