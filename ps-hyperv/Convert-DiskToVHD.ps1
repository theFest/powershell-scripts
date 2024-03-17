Function Convert-DiskToVHD {
    <#
    .SYNOPSIS
    Converts a physical disk to a VHD or VHDX file using Disk2VHD from Sysinternals.

    .DESCRIPTION
    This function automates the process of converting a physical disk to a VHD or VHDX file format using Disk2VHD from Sysinternals, downloads Disk2VHD if it's not already available and then performs the conversion.

    .PARAMETER SourceDisk
    Disk to be converted, use an asterisk (*) to specify all disks or e.g. 'C:'.
    .PARAMETER OutputPath
    Path where the converted VHD or VHDX file will be saved.
    .PARAMETER OutputFileName
    Specifies the name of the output VHD or VHDX file.
    .PARAMETER UseVHDX
    Indicates whether to create a VHDX file instead of a VHD file.

    .EXAMPLE
    Convert-DiskToVHD -SourceDisk "*" -OutputPath "D:\Temp" -OutputFileName "converted2vhd" -UseVHDX

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$SourceDisk = "*",

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputFileName,

        [Parameter(Mandatory = $false)]
        [switch]$UseVHDX
    )
    Write-Verbose -Message "Checking if Disk2VHD is already downloaded, if not downloading it..."
    if (-not (Test-Path -Path "$env:TEMP\Disk2VHD\Disk2VHD.exe")) {
        Write-Host "Downloading Disk2VHD from Sysinternals..."
        $Disk2VHDUrl = "https://download.sysinternals.com/files/Disk2vhd.zip"
        $TempZipFile = "$env:TEMP\Disk2VHD.zip"
        Invoke-WebRequest -Uri $Disk2VHDUrl -OutFile $TempZipFile -UseBasicParsing -Verbose
        Expand-Archive -Path $TempZipFile -DestinationPath "$env:TEMP\Disk2VHD" -Force -Verbose
    }
    Write-Host "Converting disk to VHD/VHDX..." -ForegroundColor DarkYellow
    $OutputFormat = if ($UseVHDX) { ".vhdx" } else { ".vhd" }
    $OutputFile = Join-Path -Path $OutputPath -ChildPath "$OutputFileName$OutputFormat"
    Start-Process -FilePath "$env:TEMP\Disk2VHD\disk2vhd64.exe" -ArgumentList "-h -c $SourceDisk $OutputFile" -Wait -WindowStyle Minimized
    Write-Host "Conversion complete, output file: $OutputFile" -ForegroundColor Green
}
