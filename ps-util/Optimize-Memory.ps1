function Optimize-Memory {
    <#
    .SYNOPSIS
    Manages memory reduction operations using the Reduce Memory tool.

    .DESCRIPTION
    This function downloads and executes ReduceMemory to manage memory usage for specified applications. It allows applying operations to one or multiple files or patterns.

    .EXAMPLE
    Optimize-Memory -Command '/O' -StartApplication
    Optimize-Memory -Command '/O' -FilePaths 'example1.exe', 'example2.exe'
    Optimize-Memory -Command '/O' -FilePaths 'example1.exe|example2.exe'

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the command to execute with ReduceMemory_x64.exe")]
        [ValidateSet('/O')]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "File paths or patterns to apply the operation to, comma-separated or pipe-separated")]
        [string[]]$FilePaths = @(),

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the ReduceMemory tool")]
        [uri]$ReduceMemoryDownloadUrl = "https://www.sordum.org/files/download/reduce-memory/ReduceMemory.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the ReduceMemory tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\ReduceMemory",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveReduceMemory,

        [Parameter(Mandatory = $false, HelpMessage = "Start the ReduceMemory application after extraction")]
        [switch]$StartApplication
    )
    $ReduceMemoryZipPath = Join-Path $DownloadPath "ReduceMemory.zip"
    $ReduceMemoryExtractPath = Join-Path $DownloadPath "ReduceMemory"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path $ReduceMemoryZipPath)) {
            Write-Host "Downloading ReduceMemory tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $ReduceMemoryDownloadUrl -OutFile $ReduceMemoryZipPath -UseBasicParsing -Verbose
            if ((Get-Item $ReduceMemoryZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting ReduceMemory tool..." -ForegroundColor Green
        if (Test-Path -Path $ReduceMemoryExtractPath) {
            Remove-Item -Path $ReduceMemoryExtractPath -Recurse -Force
        }
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ReduceMemoryZipPath, $ReduceMemoryExtractPath)
        }
        catch {
            throw "Failed to extract the ZIP file. It may be corrupt or incomplete."
        }
        $ReduceMemoryExecutable = Get-ChildItem -Path $ReduceMemoryExtractPath -Recurse -Filter "ReduceMemory_x64.exe" | Select-Object -First 1
        if (-Not $ReduceMemoryExecutable) {
            throw "ReduceMemory_x64.exe not found in $ReduceMemoryExtractPath"
        }
        $Arguments = $Command
        if ($FilePaths.Count -gt 0) {
            $FilePathsString = $FilePaths -join '|'
            $Arguments += " $FilePathsString"
        }
        Write-Verbose -Message "Starting ReduceMemory with arguments: $Arguments"
        if ($StartApplication) {
            Start-Process -FilePath $ReduceMemoryExecutable.FullName
        }
        else {
            Start-Process -FilePath $ReduceMemoryExecutable.FullName -ArgumentList $Arguments -WindowStyle Hidden -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "ReduceMemory operation '$Command' completed." -ForegroundColor Cyan
        if ($RemoveReduceMemory) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
