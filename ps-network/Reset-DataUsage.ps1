function Reset-DataUsage {
    <#
    .SYNOPSIS
    Manages the Reset Data Usage tool to reset or backup network data usage statistics.

    .DESCRIPTION
    This function uses the Reset Data Usage tool to reset or backup network data usage statistics in Windows.

    .EXAMPLE
    Reset-DataUsage -StartApplication
    Reset-DataUsage -StartApplication -Command "/R"
    Reset-DataUsage -StartApplication -Command "/B"
    Reset-DataUsage -StartApplication -Command "/L"
    Reset-DataUsage -StartApplication -Command "/R /B"
    Reset-DataUsage -StartApplication -Command "/R /B /L"

    .NOTES
    The command to execute with the ResetDataUsage tool. Valid options are:
    - /R : Reset data usage
    - /B : Backup data usage
    - /L : Launch data usage
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Reset Data Usage application in GUI mode")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Command-line parameters for the Reset Data Usage tool")]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Reset Data Usage tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/small-tools/ResetDu.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Reset Data Usage tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\ResetDataUsageTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "ResetDu.zip"
    $ExtractPath = Join-Path $DownloadPath "ResetDu"
    $Executable = Join-Path $ExtractPath "ResetDu_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Reset Data Usage tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Reset Data Usage tool..." -ForegroundColor Green
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
            throw "Reset Data Usage executable not found at $ExtractPath"
        }
        Write-Verbose -Message "Reset Data Usage executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Reset Data Usage application..." -ForegroundColor Green
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
        Write-Host "Reset Data Usage operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
