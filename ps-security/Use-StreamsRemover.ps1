function Use-StreamsRemover {
    <#
    .SYNOPSIS
    Manages the Streams Remover tool for unblocking files by removing NTFS alternate data streams.

    .DESCRIPTION
    This function uses the Streams Remover tool to remove NTFS alternate data streams from files or directories, supports various command-line parameters for different operations.

    .EXAMPLE
    Use-StreamsRemover -StartApplication
    Use-StreamsRemover -StartApplication -Command "*C:\test.exe*"
    Use-StreamsRemover -StartApplication -Command "/S C:\Downloads\"

    .NOTES
    The command to execute with the StreamsRemover tool, options are:
    - /S : Recurse subdirectories
    - /l : Show info
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Start the Streams Remover application")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "Command-line parameters for the Streams Remover tool")]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Streams Remover tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/streams-remover/sRemover.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Streams Remover tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\StreamsRemover",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "sRemover.zip"
    $ExtractPath = Join-Path $DownloadPath "sRemover"
    $Executable = Join-Path $ExtractPath "sRemover.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Streams Remover tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Streams Remover tool..." -ForegroundColor Green
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
        if (-Not (Test-Path -Path $Executable)) {
            throw "Streams Remover executable not found at $ExtractPath"
        }
        Write-Verbose -Message "Streams Remover executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Streams Remover application..." -ForegroundColor Green
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
        Write-Host "Streams Remover operation completed." -ForegroundColor Cyan
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
