function Use-MouseSettingsChanger {
    <#
    .SYNOPSIS
    Manages the Mouse Settings Changer tool to adjust mouse settings without opening the Mouse Properties dialog box.

    .DESCRIPTION
    This function uses the Mouse Settings Changer tool to modify mouse settings such as primary button, speed, pointer precision, and scroll settings. The tool operates without a GUI and supports various command-line parameters.

    .EXAMPLE
    Use-MouseSettingsChanger -StartApplication -Command "/PrimaryButton:Left"
    Use-MouseSettingsChanger -StartApplication -Command "/Speed:10"

    .NOTES
    The command to execute with the MouseSettingsChanger tool:
    - Mouse Primary Button: Left                      [ Left - Right ]
    - Mouse Speed: 10                                 [ 1 - 20 ]
    - Enhance Pointer Precision: Enable               [ Enable - Disable ]
    - Mouse Vertical Scroll: 3                        [ 1 - 100 ]
    - Mouse Horizontal Scroll: 3                      [ 1 - 100 ]

    Examples Commands:
    - MouseSC_x64.exe /PrimaryButton:Left
    - MouseSC_x64.exe /PrimaryButton:Right
    - MouseSC_x64.exe /Speed:10
    - MouseSC_x64.exe /PointerPrecision:Enable
    - MouseSC_x64.exe /PointerPrecision:Disable
    - MouseSC_x64.exe /VerticalScroll:3
    - MouseSC_x64.exe /VerticalScroll:-1
    - MouseSC_x64.exe /HorizontalScroll:3
    - MouseSC_x64.exe /Query /PrimaryButton
    - MouseSC_x64.exe /Query /Speed
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Mouse Settings Changer application in cunjuction with command")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Command-line parameters for the Mouse Settings Changer tool")]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Mouse Settings Changer tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/mouse-settings-changer/MouseSC.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Mouse Settings Changer tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\MouseSettingsChanger",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "MouseSC.zip"
    $ExtractPath = Join-Path $DownloadPath "MouseSC"
    $Executable = Join-Path $ExtractPath "MouseSC\MouseSC_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Mouse Settings Changer tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Mouse Settings Changer tool..." -ForegroundColor Green
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
            throw "Mouse Settings Changer executable not found at $Executable"
        }
        Write-Verbose -Message "Mouse Settings Changer executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Mouse Settings Changer application..." -ForegroundColor Green
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
        Write-Host "Mouse Settings Changer operation completed." -ForegroundColor Cyan
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
