function Use-FolderPainter {
    <#
    .SYNOPSIS
    Executes operations using the Folder Painter tool.

    .DESCRIPTION
    This function downloads and executes FolderPainter to change folder icons or apply system default icons.

    .EXAMPLE
    Use-FolderPainter -Command '/CopyIcon'
    Use-FolderPainter -Command 'DefaultIcon' -Folder 'C:\Path\To\Folder'
    Use-FolderPainter -Command '/Subfolder'
    Use-FolderPainter -Command '/CopyIcon' -Subfolder
    Use-FolderPainter -Command 'DefaultIcon' -Folder 'C:\Path\To\Folder' -Subfolder

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the command to execute with FolderPainter")]
        [ValidateSet('/CopyIcon', 'DefaultIcon', '/Subfolder')]
        [string]$Command,

        [Parameter(Mandatory = $false, HelpMessage = "Folder path to apply the icon change")]
        [string]$Folder,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the icon file")]
        [string]$IconFile,

        [Parameter(Mandatory = $false, HelpMessage = "Apply icon change to subfolders")]
        [switch]$Subfolder,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the Folder Painter tool")]
        [uri]$FolderPainterDownloadUrl = "https://www.sordum.org/files/download/folder-painter/FolderPainter.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the Folder Painter tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\FolderPainter",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFolderPainter,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Folder Painter application after extraction")]
        [switch]$StartApplication
    )
    $FolderPainterZipPath = Join-Path $DownloadPath "FolderPainter.zip"
    $FolderPainterExtractPath = Join-Path $DownloadPath "FolderPainter"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path $FolderPainterZipPath)) {
            Write-Host "Downloading Folder Painter tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $FolderPainterDownloadUrl -OutFile $FolderPainterZipPath -UseBasicParsing -Verbose
            if ((Get-Item $FolderPainterZipPath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt."
            }
        }
        Write-Host "Extracting Folder Painter tool..." -ForegroundColor Green
        if (Test-Path -Path $FolderPainterExtractPath) {
            Remove-Item -Path $FolderPainterExtractPath -Recurse -Force
        }
        try {
            [System.IO.Compression.ZipFile]::ExtractToDirectory($FolderPainterZipPath, $DownloadPath)
        }
        catch {
            throw "Failed to extract the ZIP file. It may be corrupt or incomplete."
        }
        $FolderPainterExecutable = Join-Path $FolderPainterExtractPath "FolderPainter_x64.exe"
        if (-Not (Test-Path -Path $FolderPainterExecutable)) {
            throw "FolderPainter_x64.exe not found in $FolderPainterExtractPath"
        }
        $Arguments = $Command
        if ($Command -eq 'DefaultIcon' -and $Folder) {
            $Arguments += " Folder=$Folder"
        }
        if ($IconFile) {
            $Arguments += " $IconFile"
        }
        if ($Subfolder) {
            $Arguments += " /Subfolder"
        }
        Write-Verbose -Message "Starting Folder Painter with arguments: $Arguments"
        if ($StartApplication) {
            Start-Process -FilePath $FolderPainterExecutable
        }
        else {
            Start-Process -FilePath $FolderPainterExecutable -ArgumentList $Arguments -WindowStyle Hidden -Wait
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Folder Painter operation '$Command' completed." -ForegroundColor Cyan
        if ($RemoveFolderPainter) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
