function Use-ClassicShutDown {
    <#
    .SYNOPSIS
    Manages the Classic Shut Down tool to open the classic shutdown dialog or perform shutdown operations.

    .DESCRIPTION
    This function uses the Classic Shut Down tool to open the classic shutdown dialog or execute shutdown, restart, log off, sleep, or hibernate commands.

    .EXAMPLE
    Use-ClassicShutDown -StartApplication -Command "/S"
    Use-ClassicShutDown -StartApplication -Command "/R /F"
    Use-ClassicShutDown -StartApplication -Command "/L"
    Use-ClassicShutDown -StartApplication -Command "/H"
    Use-ClassicShutDown -StartApplication -Command "/SM"

    .NOTES
    The command to execute with the ClassicShutDown tool. Valid options are:
    - /L  : Log off current user
    - /S  : Shutdown computer
    - /R  : Restart computer
    - /P  : Power off computer
    - /F  : Force mode(forces programs to Close)
    - /SM : Sleep Mode
    - /H  : Hibernate (hardware must support this as well)
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Classic Shut Down application")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Command-line parameters for the Classic Shut Down tool")]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Classic Shut Down tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/classic-shut-down/cShutdown.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Classic Shut Down tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\ClassicShutDownTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "cShutdown.zip"
    $ExtractPath = Join-Path $DownloadPath "cShutdown"
    $Executable = Join-Path $ExtractPath "cShutdown_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Classic Shut Down tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Classic Shut Down tool..." -ForegroundColor Green
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
            throw "Classic Shut Down executable not found at $ExtractPath"
        }
        Write-Verbose -Message "Classic Shut Down executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Classic Shut Down application..." -ForegroundColor Green
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
        Write-Host "Classic Shut Down operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
