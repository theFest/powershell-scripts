function Edit-ContextMenu {
    <#
    .SYNOPSIS
    Executes operations using the Easy Context Menu tool.

    .DESCRIPTION
    This function downloads and executes Easy Context Menu app to perform various system operations such as deleting temporary files, restarting Windows Explorer, and changing file attributes.

    .EXAMPLE
    Edit-ContextMenu -Command '/TempClean' -StartApplication
    Edit-ContextMenu -Command '/ReExplorer'
    Edit-ContextMenu -Command '/HiddenFile'
    Edit-ContextMenu -Command '/Takeown' -FileOrFolder 'C:\Path\To\FileOrFolder'
    Edit-ContextMenu -Command '/Shutdown'

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the command to execute with EcMenu_x64.exe")]
        [ValidateSet('/TempClean', '/ReExplorer', '/ReduceMemory', '/BlockInput', '/BlockKeyboard', '/HiddenFile', '/HiddenSysFile', '/HideFileExt', '/RebuildCache', '/FixPrint', '/CopyIP', '/CopyText', '/SelectAll', '/ChangeIcon', '/CopyFolderContents', '/Takeown', '/BlockAccess', '/PermanentlyDelete', '/EmptyBin', '/ChangeAttributes', '/RunParameters', '/Shutdown')]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "File or folder path for commands that require a target")]
        [string]$FileOrFolder = "",

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the EcMenu tool")]
        [uri]$EcMenuDownloadUrl = "https://www.sordum.org/files/easy-context-menu/ec_menu.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the EcMenu tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\EcMenu",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveEcMenu,

        [Parameter(Mandatory = $false, HelpMessage = "Start the EcMenu application after extraction")]
        [switch]$StartApplication
    )
    $EcMenuZipPath = Join-Path $DownloadPath "ec_menu.zip"
    $EcMenuExtractPath = Join-Path $DownloadPath "EcMenu_v1.6"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path $EcMenuZipPath)) {
            Write-Host "Downloading EcMenu tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $EcMenuDownloadUrl -OutFile $EcMenuZipPath -UseBasicParsing -Verbose
            if ((Get-Item $EcMenuZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting EcMenu tool..." -ForegroundColor Green
        if (Test-Path -Path $EcMenuExtractPath) {
            Remove-Item -Path $EcMenuExtractPath -Recurse -Force
        }
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($EcMenuZipPath, $DownloadPath)
        }
        catch {
            throw "Failed to extract the ZIP file. It may be corrupt or incomplete."
        }
        $EcMenuExecutable = Join-Path $EcMenuExtractPath "EcMenu_x64.exe"
        if (-Not (Test-Path -Path $EcMenuExecutable)) {
            throw "EcMenu_x64.exe not found in $EcMenuExtractPath"
        }
        $Arguments = $Command
        if ($FileOrFolder) {
            $Arguments += " $FileOrFolder"
        }
        Write-Verbose -Message "Starting EcMenu with arguments: $Arguments"
        if ($StartApplication) {
            Start-Process -FilePath $EcMenuExecutable
        }
        else {
            Start-Process -FilePath $EcMenuExecutable -ArgumentList $Arguments -WindowStyle Hidden -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "EcMenu operation '$Command' completed." -ForegroundColor Cyan
        if ($RemoveEcMenu) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
