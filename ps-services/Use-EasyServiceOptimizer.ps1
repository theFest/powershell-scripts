function Use-EasyServiceOptimizer {
    <#
    .SYNOPSIS
    Executes operations using the Easy Service Optimizer (eso.exe) tool.

    .DESCRIPTION
    This function downloads and executes eso.exe to apply or restore startup types and manage service settings.

    .EXAMPLE
    Use-EasyServiceOptimizer -Command '/A' -StartApplication
    Use-EasyServiceOptimizer -Command '/A' -Group 2
    Use-EasyServiceOptimizer -Command '/A' -ServiceList 'C:\Path\To\service_list.ini'
    Use-EasyServiceOptimizer -Command '/R'
    Use-EasyServiceOptimizer -Command '/A' -ServiceList 'C:\Path\To\service_list.ini'

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the command to execute with eso.exe")]
        [ValidateSet('/A', '/R')]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "Group settings to apply (1=Default, 2=Safe, 3=Tweaked, 4=Extreme)")]
        [ValidateSet('1', '2', '3', '4')]
        [string]$Group,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the service list configuration file")]
        [string]$ServiceList = "",

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the Easy Service Optimizer tool")]
        [uri]$EsoDownloadUrl = "https://www.sordum.org/files/easy-service-optimizer/eso.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the Easy Service Optimizer tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\Eso",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveEso,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Easy Service Optimizer application after extraction")]
        [switch]$StartApplication
    )
    $EsoZipPath = Join-Path $DownloadPath "eso.zip"
    $EsoExtractPath = Join-Path $DownloadPath "Eso"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path $EsoZipPath)) {
            Write-Host "Downloading Easy Service Optimizer tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $EsoDownloadUrl -OutFile $EsoZipPath -UseBasicParsing -Verbose
            if ((Get-Item $EsoZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Easy Service Optimizer tool..." -ForegroundColor Green
        if (Test-Path -Path $EsoExtractPath) {
            Remove-Item -Path $EsoExtractPath -Recurse -Force
        }
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($EsoZipPath, $DownloadPath)
        }
        catch {
            throw "Failed to extract the ZIP file. It may be corrupt or incomplete."
        }
        $EsoExecutable = Join-Path $EsoExtractPath "eso.exe"
        if (-Not (Test-Path -Path $EsoExecutable)) {
            throw "eso.exe not found in $EsoExtractPath"
        }
        $Arguments = $Command
        if ($Group) {
            $Arguments += " /G=$Group"
        }
        if ($ServiceList) {
            $Arguments += " $ServiceList"
        }
        Write-Verbose -Message "Starting Easy Service Optimizer with arguments: $Arguments"
        if ($StartApplication) {
            Start-Process -FilePath $EsoExecutable
        }
        else {
            Start-Process -FilePath $EsoExecutable -ArgumentList $Arguments -WindowStyle Hidden -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Easy Service Optimizer operation '$Command' completed." -ForegroundColor Cyan
        if ($RemoveEso) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
