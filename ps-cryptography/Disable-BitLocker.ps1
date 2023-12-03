Function Disable-BitLocker {
    <#
    .SYNOPSIS
    Disables BitLocker on the specified drive.
    
    .DESCRIPTION
    This function disables BitLocker encryption on the specified drive, it checks the current status of BitLocker on the drive and if it's enabled, it proceeds to disable BitLocker.

    .PARAMETER MountPoint
    Mandatory - the drive letter or mount point for which BitLocker will be disabled.

    .EXAMPLE
    Disable-BitLocker -MountPoint "C:"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MountPoint
    )
    $DriveInfo = Get-BitLockerVolume -MountPoint $MountPoint
    if ($DriveInfo.ProtectionStatus -eq "On") {
        Disable-BitLockerVolume -MountPoint $MountPoint -Confirm:$false
        Write-Host "BitLocker has been disabled on drive $MountPoint" -ForegroundColor Green
    }
    else {
        Write-Host "BitLocker is already disabled on drive $MountPoint" -ForegroundColor Yellow
    }
}
