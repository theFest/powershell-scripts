Function ExportDriversPnpUtil {
    <#
    .SYNOPSIS
    Export driver package(s) from the driver store into a target directory using PnPUtil.

    .DESCRIPTION
    This function exports driver package(s) from the driver store into a specified target directory
    using PnPUtil. The target directory will be created if it does not exist.

    .PARAMETER DriverName
    Mandatory - The name of the driver package to export. Use "*" to export all driver packages.
    .PARAMETER TargetDirectory
    Mandatory - The directory where the driver package(s) will be exported.

    .EXAMPLE
    ExportDriversPnpUtil -DriverName "oem12.inf" -TargetDirectory "$env:USERPROFILE\Desktop\Driver"
    ExportDriversPnpUtil -DriverName "*" -TargetDirectory "$env:USERPROFILE\Desktop\Drivers"

    .NOTES
    v0.1.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DriverName,

        [Parameter(Mandatory = $true)]
        [string]$TargetDirectory
    )
    Write-Verbose -Message "Checking if the target directory exists..."
    if (-not (Test-Path -Path $TargetDirectory -PathType Container)) {
        Write-Host "Creating target directory: $TargetDirectory" -ForegroundColor DarkGreen
        New-Item -Path $TargetDirectory -ItemType Directory | Out-Null
    }
    Write-Verbose -Message "Checking if pnputil.exe is in the environment variables and add it if not found"
    if (-not (Get-Command -Name "pnputil" -ErrorAction SilentlyContinue)) {
        Write-Host "Adding pnputil.exe to the environment variables..." -ForegroundColor DarkGreen
        $env:Path += ";$($env:SystemRoot)\System32"
    }
    Write-Verbose -Message "Exporting the driver package(s) using PnPUtil"
    $PnpUtilCommand = "pnputil.exe /export-driver $DriverName '$TargetDirectory'"
    Invoke-Expression -Command $PnpUtilCommand
    Write-Host "Driver package(s) exported successfully to: $TargetDirectory" -ForegroundColor Green
}
