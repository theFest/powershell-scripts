function Find-PrimeNumbers {
    <#
    .SYNOPSIS
    Manages the Find Prime Numbers tool for testing CPU performance in finding prime numbers.

    .DESCRIPTION
    This function uses the Find Prime Numbers tool to test how fast the CPU can search for prime numbers between a given range. It supports running with one core or all CPU cores.

    .EXAMPLE
    Find-PrimeNumbers -StartApplication
    Find-PrimeNumbers -StartApplication -UseAllCores       > n/a
    Find-PrimeNumbers -StartApplication -Range "1-100000"  > n/a

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Find Prime Numbers application")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Use all CPU cores for the test")]
        [switch]$UseAllCores,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the range for the prime number test (e.g., '1-100000')")]
        [string]$Range = "1-250000",

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Find Prime Numbers tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/small-tools/PrimeNumbers.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Find Prime Numbers tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "PrimeNumbers.zip"
    $ExtractPath = Join-Path $DownloadPath "PrimeNumbers"
    $Executable = Join-Path $ExtractPath "PrimeNumbers.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Find Prime Numbers tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Find Prime Numbers tool..." -ForegroundColor Green
        if (Test-Path -Path $ExtractPath) {
            Write-Host "Removing existing extraction path..." -ForegroundColor Yellow
            Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction Stop
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFilePath, $ExtractPath)
        }
        catch {
            Write-Host "Extracting with Shell.Application..." -ForegroundColor Yellow
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
            throw "Find Prime Numbers executable not found at $ExtractPath"
        }
        Write-Verbose -Message "Find Prime Numbers executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Find Prime Numbers application..." -ForegroundColor Green
            $Arguments = @()
            if ($UseAllCores) {
                $Arguments += "/ALLCORES"
            }
            if ($Range) {
                $Arguments += "/R $Range"
            }
            Start-Process -FilePath $Executable -ArgumentList $Arguments -Wait
        }
        else {
            Write-Host "No action specified. Use -StartApplication to launch the tool with options."
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Find Prime Numbers operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            try {
                Start-Sleep -Seconds 2
                Remove-Item -Path $ExtractPath -Force -Recurse -Verbose
                Remove-Item -Path $ZipFilePath -Force -Verbose
            }
            catch {
                Write-Warning -Message "Failed to remove temporary files: $_"
            }
        }
    }
}
