Function Disable-BitLocker {
    <#
    .SYNOPSIS
    Disables BitLocker on the specified drive.
    
    .DESCRIPTION
    This function disables BitLocker encryption on the specified drive. It checks the current status of BitLocker on the drive, verifies TPM status, and if BitLocker is enabled, it proceeds to disable BitLocker.

    .PARAMETER MountPoint
    Mandatory - the drive letter or mount point for which BitLocker will be disabled.

    .EXAMPLE
    Disable-BitLocker -MountPoint "C:"

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MountPoint
    )
    $TPMStatus = Get-WmiObject -Namespace "Root\CIMv2\Security\MicrosoftTpm" -Class Win32_Tpm
    if (!$TPMStatus) {
        Write-Warning -Message "TPM is not available on this system. BitLocker cannot be disabled as it cannot be enabled!"
        return
    }
    if ($TPMStatus.IsActivated -eq $false -or $TPMStatus.IsEnabled -eq $false) {
        Write-Warning -Message "TPM is either not activated or not enabled. BitLocker cannot be disabled, not supported!"
        return
    }
    $DriveInfo = Get-BitLockerVolume -MountPoint $MountPoint
    if ($DriveInfo.ProtectionStatus -eq "On") {
        Disable-BitLockerVolume -MountPoint $MountPoint -Confirm:$false
        Write-Host "BitLocker has been disabled on drive $MountPoint" -ForegroundColor Green
    }
    else {
        Write-Host "BitLocker is already disabled on drive $MountPoint" -ForegroundColor Yellow
    }
}
