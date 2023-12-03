Function Enable-BitLocker {
    <#
    .SYNOPSIS
    Enables BitLocker on the specified drive.
    
    .DESCRIPTION
    This function enables BitLocker encryption on the specified drive, it checks the current status of BitLocker on the drive and if it's not enabled, it proceeds to enable BitLocker.

    .PARAMETER MountPoint
    Mandatory - the drive letter or mount point for which BitLocker will be enabled.

    .EXAMPLE
    Enable-BitLocker -MountPoint "C:"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MountPoint
    )
    $DriveInfo = Get-BitLockerVolume -MountPoint $MountPoint
    if ($DriveInfo.ProtectionStatus -eq "Off") {
        Enable-BitLocker -MountPoint $MountPoint -Verbose
        Write-Host "BitLocker has been enabled on drive $MountPoint" -ForegroundColor Green
    }
    else {
        Write-Host "BitLocker is already enabled on drive $MountPoint" -ForegroundColor Yellow
    }
}
