function Use-PowerRun {
    <#
    .SYNOPSIS
    Downloads, extracts, and launches PowerRun with elevated privileges.

    .DESCRIPTION
    This function downloads and extracts PowerRun, then starts the application with specified command-line arguments.

    .EXAMPLE
    Use-PowerRun -StartApplication
    Use-PowerRun -CommandLineArgs "cmd.exe /k echo Hello, World!"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Command-line arguments for PowerRun")]
        [string]$CommandLineArgs,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading PowerRun")]
        [uri]$PowerRunDownloadUrl = "https://www.sordum.org/files/download/power-run/PowerRun_v1.7.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where PowerRun will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\PowerRun",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemovePowerRun,

        [Parameter(Mandatory = $false, HelpMessage = "Start the PowerRun application after extraction")]
        [switch]$StartApplication
    )
    $PowerRunZipPath = Join-Path $DownloadPath "PowerRun_v1.7.zip"
    $PowerRunExtractPath = Join-Path $DownloadPath "PowerRun"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $PowerRunZipPath)) {
            Write-Host "Downloading PowerRun..." -ForegroundColor Green
            Invoke-WebRequest -Uri $PowerRunDownloadUrl -OutFile $PowerRunZipPath -UseBasicParsing -Verbose
            if ((Get-Item $PowerRunZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting PowerRun..." -ForegroundColor Green
        if (Test-Path -Path $PowerRunExtractPath) {
            Remove-Item -Path $PowerRunExtractPath -Recurse -Force -ErrorAction Stop
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($PowerRunZipPath, $DownloadPath)
        }
        catch {
            Write-Host "Extracting with Shell.Application..." -ForegroundColor Yellow
            $Shell = New-Object -ComObject Shell.Application
            $Zip = $Shell.NameSpace($PowerRunZipPath)
            $Destination = $Shell.NameSpace($DownloadPath)
            $Destination.CopyHere($zip.Items(), 4)
        }
        Write-Host "Files in extraction directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $DownloadPath -Recurse | ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Yellow
        }
        $PowerRunExecutable = Join-Path $PowerRunExtractPath "PowerRun_x64.exe"
        if (-Not (Test-Path -Path $PowerRunExecutable)) {
            throw "PowerRun executable not found at $PowerRunExecutable"
        }
        Write-Verbose -Message "PowerRun extracted to: $PowerRunExecutable"
        if ($StartApplication) {
            Write-Host "Starting PowerRun..." -ForegroundColor Green
            if ($CommandLineArgs) {
                Start-Process -FilePath $PowerRunExecutable -ArgumentList $CommandLineArgs
            }
            else {
                Start-Process -FilePath $PowerRunExecutable
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "PowerRun operation completed." -ForegroundColor Cyan
        if ($RemovePowerRun) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
