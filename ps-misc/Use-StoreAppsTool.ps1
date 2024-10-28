function Use-StoreAppsTool {
    <#
    .SYNOPSIS
    Manages the Store Apps Tool to handle Microsoft Store applications.

    .DESCRIPTION
    This function uses the Store Apps Tool to manage and execute Microsoft Store applications. It allows you to add Store apps to the context menu, copy execution commands, and more.

    .EXAMPLE
    Use-StoreAppsTool -StartApplication
    Use-StoreAppsTool -AddToContextMenu -AppName "Microsoft.WindowsAlarms" - n/a
    Use-StoreAppsTool -CopyCommand -AppName "Microsoft.WindowsAlarms"      - n/a

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Store Apps Tool GUI application")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Add Store app to desktop context menu")]
        [switch]$AddToContextMenu,

        [Parameter(Mandatory = $false, HelpMessage = "Copy the execution command for the app")]
        [switch]$CopyCommand,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the file for importing or exporting settings")]
        [string]$FilePath,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Store Apps Tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\StoreAppsTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "StoreAT.zip"
    $ExtractPath = Join-Path $DownloadPath "StoreAT"
    $Executable = Join-Path $ExtractPath "StoreAT\StoreAT_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }

        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Store Apps Tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri "https://www.sordum.org/files/download/store-apps-tool/StoreAT.zip" -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Store Apps Tool..." -ForegroundColor Green
        if (Test-Path -Path $ExtractPath) {
            Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction Stop
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFilePath, $ExtractPath)
        }
        catch {
            Write-Host "Extracting with Shell.Application..." -ForegroundColor Yellow
            if (-not (Test-Path -Path $ZipFilePath)) {
                throw "The ZIP file was not found at $ZipFilePath"
            }
            if (-not (Test-Path -Path $ExtractPath)) {
                throw "The extraction path was not found or created"
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
            throw "Store Apps Tool executable not found at $Executable"
        }
        Write-Verbose -Message "Store Apps Tool executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Store Apps Tool application..." -ForegroundColor Green
            Start-Process -FilePath $Executable -Wait
        }
        if ($AddToContextMenu -and $FilePath) {
            Write-Host "Adding app to desktop context menu..." -ForegroundColor Green
            Start-Process -FilePath $Executable -ArgumentList "/AddContextMenu $FilePath" -Wait
        }
        if ($CopyCommand -and $FilePath) {
            Write-Host "Copying execution command for app..." -ForegroundColor Green
            Start-Process -FilePath $Executable -ArgumentList "/CopyCommand $FilePath" -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Store Apps Tool operation completed." -ForegroundColor Cyan
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
