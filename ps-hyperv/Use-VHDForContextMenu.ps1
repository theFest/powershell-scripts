function Use-VHDForContextMenu {
    <#
    .SYNOPSIS
    Manages the VHD For Context Menu tool for attaching and detaching VHD, VHDX, and ISO files via context menus.

    .DESCRIPTION
    This function uses the VHD For Context Menu tool to add options to the file context menu or sendto menu for attaching and detaching VHD, VHDX, and ISO files. It supports various command-line parameters for different operations.

    .EXAMPLE
    Use-VHDForContextMenu -StartApplication
    Use-VHDForContextMenu -Command "/A C:\test.vhd"
    Use-VHDForContextMenu -Command "/R C:\test.vhd"
    Use-VHDForContextMenu -Command "/D C:\test.vhd"

    .NOTES
    The command to execute with the VHDForContextMenu tool, options are:
    - /A : Attach file
    - /R : Attach file read-only
    - /D : Detach file
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the VHD For Context Menu GUI application")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Command-line parameters for the VHD For Context Menu tool")]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading VHD For Context Menu tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/small-tools/VhdToMenu.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where VHD For Context Menu tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "VhdToMenu.zip"
    $ExtractPath = $DownloadPath
    $Executable = Join-Path $ExtractPath "VhdToMenu.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading VHD For Context Menu tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting VHD For Context Menu tool..." -ForegroundColor Green
        if (Test-Path -Path $ExtractPath) {
            try {
                Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction Stop
            }
            catch {
                Write-Warning -Message "Failed to remove existing extraction path. It might be in use."
            }
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFilePath, $ExtractPath)
        }
        catch {
            Write-Host "Standard extraction failed. Trying Shell.Application..." -ForegroundColor Yellow
            if (-not (Test-Path -Path $ZipFilePath)) {
                throw "The ZIP file was not found at $ZipFilePath"
            }
            $Shell = New-Object -ComObject Shell.Application
            $Zip = $Shell.NameSpace($ZipFilePath)
            if ($null -eq $Zip) {
                throw "Failed to initialize Shell.NameSpace for ZIP file"
            }
            $Destination = $Shell.NameSpace($ExtractPath)
            if ($null -eq $Destination) {
                throw "Failed to initialize Shell.NameSpace for destination path"
            }
            $Destination.CopyHere($Zip.Items(), 4)
        }
        Write-Host "Files in extraction directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $ExtractPath -Recurse | ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Yellow
        }
        if (-Not (Test-Path -Path $Executable)) {
            throw "VHD For Context Menu executable not found at $ExtractPath"
        }
        Write-Verbose -Message "VHD For Context Menu executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting VHD For Context Menu application..." -ForegroundColor Green
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
        Write-Host "VHD For Context Menu operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            try {
                Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
            }
            catch {
                Write-Warning -Message "Failed to remove temporary files: $_"
            }
        }
    }
}
