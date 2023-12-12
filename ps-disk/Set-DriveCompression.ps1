Function Set-DriveCompression {
    <#
    .SYNOPSIS
    Enables or disables compression on a drive.

    .DESCRIPTION
    This function enables or disables compression on a drive.

    .PARAMETER DriveLetter
    Mandatory - the drive letter to enable or disable compression.
    .PARAMETER Mode
    Mandatory - action to perform (EnableCompression/DisableCompression).

    .EXAMPLE
    Set-DriveCompression -DriveLetter "C" -Mode "EnableCompression"

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
        [ValidateSet("EnableCompression", "DisableCompression")]
        [string]$Mode
    )
    BEGIN {
        try {
            $DriveInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='${DriveLetter}:'"
            Write-Output "Initial Drive Information:"$DriveInfo | Format-Table -AutoSize
        }
        catch {
            Write-Error -Message "Error during initialization: $_"
        }
    }
    PROCESS {
        try {
            switch ($Mode) {
                "EnableCompression" {
                    if (-not ($DriveInfo.CompressionMethod -band 1)) {
                        Start-Process -FilePath "cmd" -ArgumentList "/c fsutil behavior set DisableCompression 0" -Wait -NoNewWindow
                        Write-Host "Compression enabled on drive $DriveLetter"  -ForegroundColor Green
                    }
                    else {
                        Write-Warning -Message "Compression already enabled on drive $DriveLetter"
                    }
                }
                "DisableCompression" {
                    if ($DriveInfo.CompressionMethod -band 1) {
                        Start-Process -FilePath "cmd" -ArgumentList "/c fsutil behavior set DisableCompression 1" -Wait -NoNewWindow
                        Write-Host "Compression disabled on drive $DriveLetter" -ForegroundColor Green
                    }
                    else {
                        Write-Warning -Message "Compression already disabled on drive $DriveLetter"
                    }
                }
                default {
                    Write-Error -Message "Invalid mode selected. Use 'EnableCompression' or 'DisableCompression'."
                    return
                }
            }
        }
        catch {
            Write-Error -Message "Error during processing: $_"
        }
    }
    END {
        try {
            $FinalDriveInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='${DriveLetter}:'"
            Write-Output "Final Drive Information:"$FinalDriveInfo | Format-Table -AutoSize
        }
        catch {
            Write-Error -Message "Error during cleanup: $_"
        }
    }
}
