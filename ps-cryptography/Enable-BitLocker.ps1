Function Enable-BitLocker {
    <#
    .SYNOPSIS
    Enables BitLocker on the specified drive.
    
    .DESCRIPTION
    This function enables BitLocker encryption on the specified drive. It checks the current status of BitLocker on the drive, verifies TPM status, and if BitLocker is not enabled and TPM is present and activated, it proceeds to enable BitLocker.

    .PARAMETER MountPoint
    Mandatory - the drive letter or mount point for which BitLocker will be enabled.

    .EXAMPLE
    Enable-BitLocker -MountPoint "C:"

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
        Write-Warning -Message "TPM is not available on this system. BitLocker cannot be enabled"
        return
    }
    if ($TPMStatus.IsActivated -eq $false -or $TPMStatus.IsEnabled -eq $false) {
        Write-Warning -Message "TPM is either not activated or not enabled. BitLocker cannot be enabled"
        return
    }
    $DriveInfo = Get-BitLockerVolume -MountPoint $MountPoint
    if ($DriveInfo.ProtectionStatus -eq "Off") {
        Enable-BitLockerVolume -MountPoint $MountPoint -Verbose
        Write-Host "BitLocker has been enabled on drive $MountPoint" -ForegroundColor Green
    }
    else {
        Write-Host "BitLocker is already enabled on drive $MountPoint" -ForegroundColor Yellow
    }
}
