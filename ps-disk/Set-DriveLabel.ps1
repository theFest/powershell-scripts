Function Set-DriveLabel {
    <#
    .SYNOPSIS
    Changes the label of a drive.

    .DESCRIPTION
    This function changes the label of a drive to the specified label.

    .PARAMETER DriveLetter
    Mandatory - the drive letter of the volume to change the label.
    .PARAMETER NewDriveLabel
    Mandatory - the new label to set for the drive.
    .PARAMETER RemoveDriveLabel
    NotMandatory - removes the label from the drive.

    .EXAMPLE
    Set-DriveLabel -DriveLetter "C" -NewDriveLabel "NewLabel" -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[A-Za-z]$')]
        [string]$DriveLetter,

        [Parameter(Mandatory = $true)]
        [string]$NewDriveLabel,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveDriveLabel
    )
    BEGIN {
        $DriveInfo = Get-Volume -DriveLetter $DriveLetter
        Write-Output "Current drive label: $($DriveInfoBefore.FileSystemLabel)"
    }
    PROCESS {
        if ($RemoveDriveLabel) {
            $DriveInfo.FileSystemLabel = $null
            $DriveInfo | Set-Volume -NewFileSystemLabel $null -Verbose
            Write-Verbose -Message "Drive label removed"
        }
        else {
            $DriveInfo.FileSystemLabel = $NewDriveLabel
            $DriveInfo | Set-Volume -NewFileSystemLabel $NewDriveLabel -Verbose
            Write-Verbose -Message "Drive label set to '$NewDriveLabel'"
        }
    }
    END {
        $DriveInfoAfter = Get-Volume -DriveLetter $DriveLetter
        Write-Output "Drive label change check: $($DriveInfoAfter.FileSystemLabel)"
    }
}
