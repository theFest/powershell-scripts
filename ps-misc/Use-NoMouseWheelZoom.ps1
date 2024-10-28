function Use-NoMouseWheelZoom {
    <#
    .SYNOPSIS
    Manages the No Mouse Wheel Zoom tool to disable zooming with the mouse wheel in various applications.

    .DESCRIPTION
    This function uses the No Mouse Wheel Zoom tool to prevent accidental zooming by disabling the mouse wheel zoom feature.

    .EXAMPLE
    Use-NoMouseWheelZoom -StartApplication
    Use-NoMouseWheelZoom -Pause           - n/a
    Use-NoMouseWheelZoom -BlockAllWindows - n/a
    Use-NoMouseWheelZoom -Autostart       - n/a

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the No Mouse Wheel Zoom application")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Pause No Mouse Wheel Zoom")]
        [switch]$Pause,

        [Parameter(Mandatory = $false, HelpMessage = "Block zoom in all windows")]
        [switch]$BlockAllWindows,

        [Parameter(Mandatory = $false, HelpMessage = "Enable autostart on Windows startup")]
        [switch]$Autostart,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading No Mouse Wheel Zoom tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/no-mouse-wheel-zoom/MWNoZoom.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where No Mouse Wheel Zoom tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\NoMouseWheelZoom",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "MWNoZoom.zip"
    $ExtractPath = Join-Path $DownloadPath "MWNoZoom"
    $Executable = Join-Path $ExtractPath "MWNoZoom\MWNoZoom_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading No Mouse Wheel Zoom tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting No Mouse Wheel Zoom tool..." -ForegroundColor Green
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
            throw "No Mouse Wheel Zoom executable not found at $ExtractPath"
        }
        Write-Verbose -Message "No Mouse Wheel Zoom executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting No Mouse Wheel Zoom application..." -ForegroundColor Green
            Start-Process -FilePath $Executable -Wait
        }
        if ($Pause) {
            Write-Host "Pausing No Mouse Wheel Zoom..." -ForegroundColor Green
            Start-Process -FilePath $Executable -ArgumentList "-Pause" -Wait
        }
        if ($BlockAllWindows) {
            Write-Host "Blocking zoom in all windows..." -ForegroundColor Green
            Start-Process -FilePath $Executable -ArgumentList "-BlockAllWindows" -Wait
        }
        if ($Autostart) {
            Write-Host "Enabling autostart on Windows startup..." -ForegroundColor Green
            Start-Process -FilePath $Executable -ArgumentList "-Autostart" -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "No Mouse Wheel Zoom operation completed." -ForegroundColor Cyan
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
