Function Set-FSRMQuotaLimit {
    <#
    .SYNOPSIS
    Sets a quota limit using File Server Resource Manager (FSRM).

    .DESCRIPTION
    This function sets a quota limit using File Server Resource Manager (FSRM) on a specific drive or volume.

    .PARAMETER DriveLetter
    Mandatory - drive letter of the volume to set the quota limit.
    .PARAMETER NewQuotaLimitGB
    Mandatory - the new quota limit in GB to set.
    .PARAMETER SoftLimitAction
    NotMandatory - action when the soft limit is reached (e.g., Email, Command).
    .PARAMETER HardLimitAction
    NotMandatory - action when the hard limit is reached (e.g., EventLog, Command).

    .EXAMPLE
    Set-FSRMQuotaLimit -DriveLetter "D" -NewQuotaLimitGB 100 -SoftLimitAction Email -HardLimitAction EventLog

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[A-Za-z]$')]
        [string]$DriveLetter,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $_ -ge 0 })]
        [int]$NewQuotaLimitGB,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Email", "Command")]
        [string]$SoftLimitAction,

        [Parameter(Mandatory = $false)]
        [ValidateSet("EventLog", "Command")]
        [string]$HardLimitAction
    )
    BEGIN {
        try {
            $DriveInfo = Get-Volume -DriveLetter $DriveLetter
            $CurrentQuota = Get-FsrmQuota -Path $DriveInfo.DriveLetterPath
            Write-Output "Initial Quota Information: $CurrentQuota"
        }
        catch {
            Write-Error -Message "Error during initialization: $_"
        }
    }
    PROCESS {
        try {
            $QuotaParams = @{
                Size = $NewQuotaLimitGB * 1GB
            }
            if ($SoftLimitAction) {
                $QuotaParams['SoftLimitAction'] = $SoftLimitAction
            }
            if ($HardLimitAction) {
                $QuotaParams['HardLimitAction'] = $HardLimitAction
            }
            $DriveInfo | Set-FsrmQuota @QuotaParams -Verbose
            Write-Host "Quota limit set to '$NewQuotaLimitGB' GB" -ForegroundColor Green
        }
        catch {
            Write-Error -Message "Error during processing: $_"
        }
    }
    END {
        try {
            $UpdatedQuota = Get-FsrmQuota -Path $DriveInfo.DriveLetterPath
            Write-Output "Final Quota Information: $UpdatedQuota"
        }
        catch {
            Write-Error -Message "Error during cleanup: $_"
        }
    }
}
