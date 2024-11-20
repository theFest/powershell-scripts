function Disable-SMB {
    <#
    .SYNOPSIS
    Disables specified versions of the SMB protocol on the local machine.

    .DESCRIPTION
    This function allows users to disable the Server Message Block (SMB) protocol versions SMBv1, SMBv2, and SMBv3 on a Windows machine. This is a crucial security measure to protect against vulnerabilities associated with older SMB versions. Can disable a specific version or all versions and offers the option to restart the system immediately after making changes.

    .EXAMPLE
    Disable-SMB

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify the SMB version to disable, defaults to 'All'")]
        [ValidateSet("SMBv1", "SMBv2", "SMBv3", "All")]
        [string]$Version = "All",

        [Parameter(Mandatory = $false, HelpMessage = "If the system should restart immediately after making changes")]
        [switch]$RestartImmediately
    )
    try {
        if ($Version -eq "All" -or $Version -eq "SMBv1") {
            Write-Host "Disabling SMBv1 protocol..." -ForegroundColor Cyan
            Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
            $SmbStatusAfter = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
            if ($SmbStatusAfter.State -eq 'Disabled') {
                Write-Host "SMBv1 protocol is now confirmed as disabled." -ForegroundColor Green
            }
            else {
                Write-Host "Failed to disable SMBv1 protocol. Current state: $($SmbStatusAfter.State)" -ForegroundColor Red
            }
        }
        if ($Version -eq "All" -or $Version -eq "SMBv2" -or $Version -eq "SMBv3") {
            $SmbRegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
            if ($Version -eq "SMBv2" -or $Version -eq "All") {
                Write-Host "Disabling SMBv2 protocol..." -ForegroundColor Cyan
                Set-ItemProperty -Path $SmbRegistryPath -Name "SMB2" -Value 0 -Force
            }
            if ($Version -eq "SMBv3" -or $Version -eq "All") {
                Write-Host "Disabling SMBv3 protocol..." -ForegroundColor Cyan
                Set-ItemProperty -Path $SmbRegistryPath -Name "SMB3" -Value 0 -Force
            }
            $Smb2Status = Get-ItemProperty -Path $SmbRegistryPath -Name "SMB2" -ErrorAction SilentlyContinue
            if ($Smb2Status.SMB2 -eq 0) {
                Write-Host "SMBv2 protocol is now confirmed as disabled." -ForegroundColor Green
            }
            else {
                Write-Host "Failed to disable SMBv2 protocol. Current state: $($Smb2Status.SMB2)" -ForegroundColor Red
            }
            $Smb3Status = Get-ItemProperty -Path $SmbRegistryPath -Name "SMB3" -ErrorAction SilentlyContinue
            if ($Smb3Status.SMB3 -eq 0) {
                Write-Host "SMBv3 protocol is now confirmed as disabled." -ForegroundColor Green
            }
            else {
                Write-Host "Failed to disable SMBv3 protocol. Current state: $($Smb3Status.SMB3)" -ForegroundColor Red
            }
        }
        if ($RestartImmediately) {
            Write-Host "Restarting the system to apply changes..." -ForegroundColor Yellow
            Restart-Computer -Force
        }
        else {
            Write-Host "Please restart your system to apply the changes." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "An error occurred while disabling SMB protocols: $_" -ForegroundColor Red
    }
}
