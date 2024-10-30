function Use-SendWindowsKey {
    <#
    .SYNOPSIS
    Manages the Send Windows Key tool to simulate pressing Windows key shortcuts.

    .DESCRIPTION
    This function uses the Send Windows Key tool to simulate pressing Windows key combinations to perform various tasks.

    .EXAMPLE
    Use-SendWindowsKey -StartApplication
    Use-SendWindowsKey -StartApplication -Command "#R"
    Use-SendWindowsKey -StartApplication -Command "#E"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Send Windows Key application in web browser")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Command-line parameters for the Send Windows Key tool")]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Send Windows Key tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/send-windows-key/SendWKey.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Send Windows Key tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\SendWindowsKey",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "SendWKey.zip"
    $ExtractPath = Join-Path $DownloadPath "SendWKey"
    $Executable = Join-Path $ExtractPath "SendWKey_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Send Windows Key tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Send Windows Key tool..." -ForegroundColor Green
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
        $Executable = Join-Path $ExtractPath "SendWKey\SendWKey_x64.exe"
        if (-Not (Test-Path -Path $Executable)) {
            throw "Send Windows Key executable not found at $Executable"
        }
        Write-Verbose -Message "Send Windows Key executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Send Windows Key application..." -ForegroundColor Green
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
        Write-Host "Send Windows Key operation completed." -ForegroundColor Cyan
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
