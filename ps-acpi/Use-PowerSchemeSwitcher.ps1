function Use-PowerSchemeSwitcher {
    <#
    .SYNOPSIS
    Switches power schemes or performs other related actions using the Switch Power Scheme tool.

    .DESCRIPTION
    This function manages the Switch Power Scheme tool, which provides options to switch between power schemes, export/import power plans, and more. It supports command-line parameters for these actions.

    .EXAMPLE
    Use-PowerSchemeSwitcher -StartApplication
    Use-PowerSchemeSwitcher -SchemeName "High Performance"
    Use-PowerSchemeSwitcher -ExportPlan "PowerPlanName"
    Use-PowerSchemeSwitcher -ImportPlan "C:\Path\To\PlanFile.pow"
    Use-PowerSchemeSwitcher -AddToContextMenu
    Use-PowerSchemeSwitcher -ShowTrayIcon

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Power scheme to activate")]
        [string]$SchemeName,

        [Parameter(Mandatory = $false, HelpMessage = "Name of the power plan to export")]
        [string]$ExportPlan,

        [Parameter(Mandatory = $false, HelpMessage = "File path to import a power plan from")]
        [string]$ImportPlan,

        [Parameter(Mandatory = $false, HelpMessage = "Add the power scheme options to the desktop context menu")]
        [switch]$AddToContextMenu,

        [Parameter(Mandatory = $false, HelpMessage = "Show the power scheme options in the system tray")]
        [switch]$ShowTrayIcon,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Switch Power Scheme application after setup")]
        [switch]$StartApplication,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Switch Power Scheme tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/switch-power-scheme/SwitchPowerScheme.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Switch Power Scheme tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\SwitchPowerSchemeTool",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles
    )
    $ZipFilePath = Join-Path $DownloadPath "SwitchPowerScheme.zip"
    $ExtractPath = Join-Path $DownloadPath "SwitchPowerScheme_v1.3"
    $Executable = Join-Path $ExtractPath "sPowers_x64.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Switch Power Scheme tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Switch Power Scheme tool..." -ForegroundColor Green
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
            throw "Switch Power Scheme executable not found at $ExtractPath"
        }
        Write-Verbose -Message "Switch Power Scheme executable located at: $($Executable)"
        $Arguments = @()
        if ($SchemeName) {
            $Arguments += "/$SchemeName"
        }
        if ($ExportPlan) {
            $Arguments += "/Export:$ExportPlan"
        }
        if ($ImportPlan) {
            $Arguments += "/Import:$ImportPlan"
        }
        if ($AddToContextMenu) {
            $Arguments += "/AddToContextMenu"
        }
        if ($ShowTrayIcon) {
            $Arguments += "/ShowTrayIcon"
        }
        if ($Arguments.Count -gt 0) {
            Write-Host "Executing Switch Power Scheme with arguments: $($Arguments -join ' ')" -ForegroundColor Green
            Start-Process -FilePath $Executable -ArgumentList ($Arguments -join ' ') -Wait
        }
        else {
            Write-Host "No valid command specified." -ForegroundColor DarkCyan
        }
        if ($StartApplication) {
            Write-Host "Starting Switch Power Scheme application..." -ForegroundColor Green
            Start-Process -FilePath $Executable -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Switch Power Scheme operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
