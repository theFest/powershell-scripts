Function Resize-DriveVolume {
    <#
    .SYNOPSIS
    Resizes a volume by shrinking and/or extending it.

    .DESCRIPTION
    This function resizes a volume by shrinking it by a specified amount in GB and then extending it by another specified amount in GB.

    .PARAMETER DriveLetter
    Mandatory - the drive letter of the volume to be resized.
    .PARAMETER ShrinkAmount
    Mandatory - the amount in GB to shrink the volume by.
    .PARAMETER ExtendAmount
    Mandatory - the amount in GB to extend the volume by.
    .PARAMETER ShrinkToMinimum
    NotMandatory - shrinks the volume to its minimum possible size after the specified shrink amount (default: $false).
    .PARAMETER ExtendToMaximum
    NotMandatory - extends the volume to its maximum possible size after the specified extend amount (default: $false).
    .PARAMETER ValidateSize
    NotMandatory - validates the new size to ensure it is within acceptable limits (default: $true).

    .EXAMPLE
    Resize-DriveVolume -DriveLetter "D" -ShrinkAmount 10 -ExtendAmount 5 -ShrinkToMinimum -ExtendToMaximum -ValidateSize

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
        [int]$ShrinkAmount,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateScript({ $_ -ge 0 })]
        [int]$ExtendAmount,

        [Parameter(Mandatory = $false)]
        [switch]$ShrinkToMinimum,

        [Parameter(Mandatory = $false)]
        [switch]$ExtendToMaximum,

        [Parameter(Mandatory = $false)]
        [switch]$ValidateSize
    )
    BEGIN {
        try {
            $DriveInfo = Get-Volume -DriveLetter $DriveLetter
            Write-Output "Initial Volume Size: $($DriveInfo.Size / 1GB) GB"
        }
        catch {
            Write-Error -Message "Error during initialization: $_"
        }
    }
    PROCESS {
        try {
            $NewSizeShrink = $DriveInfo.SizeRemaining - $ShrinkAmount * 1GB
            if ($ShrinkToMinimum) {
                $NewSizeShrink = $DriveInfo.SizeMin
                Write-Verbose -Message "Shrinking to minimum possible size"
            }
            if ($ValidateSize -and $NewSizeShrink -lt $DriveInfo.SizeMin) {
                throw "Error: Shrink amount results in a size smaller than the minimum allowable size"
            }
            $DriveInfo | Resize-Partition -Size $NewSizeShrink -Verbose -Confirm:$false
            Write-Host "Volume shrunk by $ShrinkAmount GB" -ForegroundColor Green
            if ($ExtendToMaximum) {
                $NewSizeExtend = $DriveInfo.SizeMax
                Write-Verbose -Message "Extending to maximum possible size..."
            }
            else {
                $NewSizeExtend = $DriveInfo.Size + $ExtendAmount * 1GB
            }
            if ($ValidateSize -and $NewSizeExtend -gt $DriveInfo.SizeMax) {
                throw "Error: Extend amount results in a size larger than the maximum allowable size"
            }
            $DriveInfo | Resize-Partition -Size $NewSizeExtend -Verbose -Confirm:$false
            Write-Host "Volume extended by $ExtendAmount GB" -ForegroundColor Green
        }
        catch {
            Write-Error -Message "Error during processing: $_"
        }
    }
    END {
        try {
            $DriveInfoAfter = Get-Volume -DriveLetter $DriveLetter
            Write-Output "Final Volume Size: $($DriveInfoAfter.Size / 1GB) GB"
        }
        catch {
            Write-Error -Message "Error during cleanup: $_"
        }
    }
}
