function Use-SimpleVHDManager {
    <#
    .SYNOPSIS
    Manages VHD files using the Simple VHD Manager tool.

    .DESCRIPTION
    This function downloads and executes Simple VHD Manager to manage VHD files, including attaching, detaching, changing drive letters, and more. Credits to Sordum.

    .EXAMPLE
    Use-SimpleVHDManager -VhdOperation '/A' -VhdFile 'C:\test.vhd'
    Use-SimpleVHDManager -VhdOperation '/A /L=Z:' -VhdFile 'C:\test.vhd'

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the operation to perform on the VHD file")]
        [ValidateSet("/A", "/R", "/L", "/D", "/O", "/I", "/U")]
        [string]$VhdOperation,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the VHD file (required for certain operations)")]
        [string]$VhdFile = "",

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the Simple VHD Manager tool")]
        [uri]$VhdManagerDownloadUrl = "https://www.sordum.org/files/downloads.php?simple-vhd-manager",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the Simple VHD Manager tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\SimpleVHDManager",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveVHDManager
    )
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        $VhdManagerZipPath = Join-Path $DownloadPath "SimpleVHDManager.zip"
        if (!(Test-Path -Path $VhdManagerZipPath)) {
            Write-Host "Downloading Simple VHD Manager tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $VhdManagerDownloadUrl -OutFile $VhdManagerZipPath -UseBasicParsing -Verbose
        }
        $VhdManagerExtractPath = Join-Path $DownloadPath "SimpleVHDManager"
        Write-Host "Extracting Simple VHD Manager tool..." -ForegroundColor Green
        Expand-Archive -Path $VhdManagerZipPath -DestinationPath $VhdManagerExtractPath -Force -Verbose
        $VhdManagerExecutable = Get-ChildItem -Path $VhdManagerExtractPath -Recurse -Filter "VhdManager_x64.exe" | Select-Object -First 1
        if (-Not $VhdManagerExecutable) {
            throw "VhdManager_x64.exe not found in $VhdManagerExtractPath"
        }
        $Arguments = if ($VhdFile) { "$VhdOperation $VhdFile" } else { $VhdOperation }
        Write-Verbose -Message "Starting Simple VHD Manager with arguments: $Arguments"
        Start-Process -FilePath $VhdManagerExecutable.FullName -ArgumentList $Arguments -WindowStyle Hidden -Wait
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "VHD operation '$VhdOperation' completed." -ForegroundColor Cyan
    }
    if ($RemoveVHDManager) {
        Write-Warning -Message "Cleaning up, removing the temporary folder..."
        Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
    }
}
