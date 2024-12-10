function Use-HibernateTool {
    <#
    .SYNOPSIS
    Enables or disables hibernation using the Sordum "Hibernate Enable or Disable" tool or launches the tool interface.

    .DESCRIPTION
    This function downloads and extracts the "Hibernate Enable or Disable" tool to manage hibernation on Windows machines. You can enable/disable hibernation, query the status, adjust the size of the hibernation file, or launch the tool manually.

    .EXAMPLE
    Use-HibernateTool -StartApplication
    Use-HibernateTool -Command Enable
    Use-HibernateTool -Command Disable

    .NOTES
    The command to run with the Hibernate tool. Valid options are:
    - Enable: Enables hibernation.
    - Disable: Disables hibernation.
    - Query: Queries the current hibernation status.
    - Auto: Automatically disables hibernation on SSD and enables it on other disks.
    - Minimum: Sets the hibernation file size to 40% of total RAM.
    - Medium: Sets the hibernation file size to 75% of total RAM.
    - Maximum: Sets the hibernation file size to 100% of total RAM.
    - Reduced: Sets the hibernation file size to 20% of total RAM (only on Windows 10+).
    - None: Use this to start the application without parameters.
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify the command to execute: Enable, Disable, Query, Auto, Minimum, Medium, Maximum, Reduced.")]
        [ValidateSet("Enable", "Disable", "Query", "Auto", "Minimum", "Medium", "Maximum", "Reduced", "None")]
        [string]$Command = "None",

        [Parameter(Mandatory = $false, HelpMessage = "Start the Hibernate Enable or Disable tool GUI.")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Hibernate Enable or Disable tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/hibernate-enable-or-disable/Hibernate.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Hibernate tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\HibernateTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "Hibernate.zip"
    $ExtractPath = Join-Path $DownloadPath "Hibernate"
    $Executable = Join-Path $ExtractPath "Hibernate_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Hibernate Enable or Disable tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Hibernate Enable or Disable tool..." -ForegroundColor Green
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
            throw "Hibernate Enable or Disable executable not found in $ExtractPath"
        }
        Write-Verbose -Message "Hibernate Enable or Disable executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Launching Hibernate Enable or Disable GUI..." -ForegroundColor Green
            Start-Process -FilePath $Executable -Wait
        }
        else {
            $CmdParameter = switch ($Command) {
                "Enable" { "/E" }
                "Disable" { "/D" }
                "Query" { "/Q" }
                "Auto" { "/Auto" }
                "Minimum" { "/Minimum" }
                "Medium" { "/Medium" }
                "Maximum" { "/Maximum" }
                "Reduced" { "/Reduced" }
                "None" { "" }
            }
            Write-Host "Executing Hibernate command: $CmdParameter" -ForegroundColor Green
            if ($CmdParameter -ne "") {
                Start-Process -FilePath $Executable -ArgumentList $CmdParameter -Wait
            }
            else {
                Write-Host "No command specified, use -StartApplication to launch the GUI or provide a valid command."
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Hibernate Enable or Disable operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
