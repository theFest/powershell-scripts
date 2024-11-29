function Use-DefenderExclusionTool {
    <#
    .SYNOPSIS
    Downloads, extracts, and runs the Defender Exclusion Tool to manage exclusions in Microsoft Defender Antivirus.

    .DESCRIPTION
    The Defender Exclusion Tool allows users to add or remove files, folders, file types, or processes from the Microsoft Defender Antivirus exclusion list.

    .EXAMPLE
    Use-DefenderExclusionTool -StartApplication

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for the Defender Exclusion Tool")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Defender Exclusion Tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/defender-exclusion-tool/ExcTool.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Defender Exclusion Tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\DefenderExclusionTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Defender Exclusion Tool application after extraction")]
        [switch]$StartApplication
    )
    $ZipFilePath = Join-Path $DownloadPath "ExcTool.zip"
    $ExtractPath = Join-Path $DownloadPath "ExcTool_v1.3"
    $Executable = Join-Path $ExtractPath "ExcTool.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Defender Exclusion Tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Defender Exclusion Tool..." -ForegroundColor Green
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
            throw "Defender Exclusion Tool executable not found in $ExtractPath"
        }
        Write-Verbose -Message "Defender Exclusion Tool executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Defender Exclusion Tool..." -ForegroundColor Green
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
        Write-Host "Defender Exclusion Tool operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
