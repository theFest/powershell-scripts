function Hide-FromUninstallList {
    <#
    .SYNOPSIS
    Downloads, extracts, and runs the Hide From Uninstall List tool to manage program visibility in the Add/Remove Programs list.

    .DESCRIPTION
    The Hide From Uninstall List tool allows you to hide entries in the Add/Remove Programs list, either to improve privacy or to clean up entries left behind after software removal.

    .EXAMPLE
    Hide-FromUninstallList -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for the Hide From Uninstall List")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Hide From Uninstall List")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/hide-from-uninstall-list/HideUL.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Hide From Uninstall List will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\HideFromUninstallList",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Hide From Uninstall List application after extraction")]
        [switch]$StartApplication
    )
    $ZipFilePath = Join-Path $DownloadPath "HideUL.zip"
    $ExtractPath = Join-Path $DownloadPath "HideUL"
    $Executable = Join-Path $ExtractPath "HideUL.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Hide From Uninstall List..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Hide From Uninstall List..." -ForegroundColor Green
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
            throw "Hide From Uninstall List executable not found in $ExtractPath"
        }
        Write-Verbose -Message "Hide From Uninstall List executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Hide From Uninstall List..." -ForegroundColor Green
            if ($CommandLineArgs) {
                Start-Process -FilePath $Executable -ArgumentList $CommandLineArgs
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
        Write-Host "Hide From Uninstall List operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
