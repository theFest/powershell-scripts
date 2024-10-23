function Use-RunAsTool {
    <#
    .SYNOPSIS
    Downloads, extracts, and manages the RunAsTool application.

    .DESCRIPTION
    This function downloads and extracts RunAsTool.exe. After extraction, it supports importing settings via command-line arguments.

    .EXAMPLE
    Use-RunAsTool -StartApplication
    Use-RunAsTool -ImportFile "C:\Path\To\Import.rnt" -Admin "AdminAccount" -Password "AdminPassword"
    Use-RunAsTool -StartApplication -ImportFile "C:\Path\To\Import.rnt" -Admin "AdminAccount" -Password "AdminPassword"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the RunAsTool")]
        [uri]$RunAsToolDownloadUrl = "https://www.sordum.org/files/download/runastool/RunAsTool.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the RunAsTool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\RunAsTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveRunAsTool,

        [Parameter(Mandatory = $false, HelpMessage = "Start the RunAsTool application after extraction")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the import file")]
        [string]$ImportFile,

        [Parameter(Mandatory = $false, HelpMessage = "Admin account name for importing settings")]
        [string]$Admin,

        [Parameter(Mandatory = $false, HelpMessage = "Admin password for importing settings")]
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "Reset previous list during import")]
        [switch]$Reset
    )
    $RunAsToolZipPath = Join-Path $DownloadPath "RunAsTool.zip"
    $RunAsToolExtractPath = Join-Path $DownloadPath "RunAsTool"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path $RunAsToolZipPath)) {
            Write-Host "Downloading RunAsTool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $RunAsToolDownloadUrl -OutFile $RunAsToolZipPath -UseBasicParsing -Verbose
            if ((Get-Item $RunAsToolZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting RunAsTool..." -ForegroundColor Green
        if (Test-Path -Path $RunAsToolExtractPath) {
            Remove-Item -Path $RunAsToolExtractPath -Recurse -Force
        }
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($RunAsToolZipPath, $DownloadPath)
        }
        catch {
            throw "Failed to extract the ZIP file. It may be corrupt or incomplete."
        }
        $RunAsToolExecutable = Get-ChildItem -Path $RunAsToolExtractPath -Recurse -Filter "RunAsTool.exe" | Select-Object -First 1
        if (-Not $RunAsToolExecutable) {
            throw "RunAsTool.exe not found in $RunAsToolExtractPath"
        }
        Write-Verbose -Message "RunAsTool extracted to: $($RunAsToolExecutable.FullName)"
        if ($ImportFile) {
            $Arguments = "/U=$Admin /P=$Pass /I=$ImportFile"
            if ($Reset) {
                $Arguments += " /R"
            }
            Write-Verbose -Message "Importing settings with arguments: $Arguments"
            Start-Process -FilePath $RunAsToolExecutable.FullName -ArgumentList $Arguments -Wait
        }
        if ($StartApplication) {
            Write-Host "Starting RunAsTool..." -ForegroundColor Green
            Start-Process -FilePath $RunAsToolExecutable.FullName
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "RunAsTool operation completed." -ForegroundColor Cyan
        if ($RemoveRunAsTool) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
