Function Set-DrivePartitions {
    <#
    .SYNOPSIS
    Manages partitions on a drive.

    .DESCRIPTION
    This function performs various partition management operations on a drive.

    .PARAMETER DriveLetter
    Mandatory - drive letter associated with the partition.
    .PARAMETER NewDriveLetter
    Mandatory - the new drive letter for the partition.
    .PARAMETER Operation
    Mandatory - operation to perform (NewPartition, RemovePartition, CreatePartition, GetPartitionSupportedSize).
    .PARAMETER VolumeGUID
    NotMandatory - specifies the Volume GUID to retrieve.

    .EXAMPLE
    Set-DrivePartitions -DriveLetter "C" -NewDriveLetter "D" -Operation "CreatePartition"

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
        [ValidatePattern('^[A-Za-z]$')]
        [string]$NewDriveLetter,

        [Parameter(Mandatory = $true)]
        [ValidateSet("NewPartition", "RemovePartition", "CreatePartition", "GetPartitionSupportedSize")]
        [string]$Operation,

        [Parameter(Mandatory = $false)]
        [string]$VolumeGUID
    )
    BEGIN {
        try {
            $DriveInfo = Get-Volume -DriveLetter $DriveLetter -ErrorAction Stop
            if ($PSBoundParameters.ContainsKey('VolumeGUID')) {
                $VolumeGUID = $DriveInfo.UniqueId
            }
        }
        catch {
            Write-Error -Message "Failed to get volume information: $_"
        }
    }
    PROCESS {
        try {
            switch ($Operation) {
                "NewPartition" {
                    New-Partition -DiskNumber (Get-Volume -DriveLetter $DriveLetter).DiskNumber -DriveLetter $NewDriveLetter -UseMaximumSize -Verbose
                    Write-Host "New partition created with drive letter '$NewDriveLetter'" -ForegroundColor Green
                }
                "RemovePartition" {
                    $Partition = Get-Partition -DriveLetter $DriveLetter
                    Remove-Partition -InputObject $Partition -Confirm:$false -Verbose
                    Write-Host "Partition removed" -ForegroundColor Green
                }
                "CreatePartition" {
                    $PartInfo = Get-Volume -DriveLetter $DriveLetter
                    if ($PartInfo.PartitionStyle -eq "RAW") {
                        $Result = New-Partition -DiskNumber $PartInfo.DiskNumber -Size 20GB -DriveLetter $NewDriveLetter
                        if ($Result) {
                            Write-Host "New partition created on drive $($DriveLetter) with drive letter $($NewDriveLetter)" -ForegroundColor Green
                        }
                        else {
                            Write-Warning -Message "Failed to create new partition on drive $($DriveLetter)"
                        }
                    }
                    else {
                        Write-Warning -Message "Drive $($DriveLetter) already has a partition and cannot create a new one"
                    }
                }
                "GetPartitionSupportedSize" {
                    $Disk = Get-Disk -Number (Get-Volume -DriveLetter $DriveLetter).DiskNumber
                    $SupportedSize = Get-PartitionSupportedSize -Disk $Disk
                    Write-Host "Minimum size: $($SupportedSize.MinimumSize) Maximum size: $($SupportedSize.MaximumSize)" -ForegroundColor Green
                }
                default {
                    Write-Error -Message "Invalid operation selected!"
                }
            }
        }
        catch {
            Write-Error -Message "Error occurred during partition management: $_"
        }
    }
    END {
        try {
            if ($VolumeGUID) {
                Write-Output -InputObject "Volume GUID: $VolumeGUID"
            }
        }
        catch {
            Write-Error -Message "Failed to get Volume GUID: $_"
        }
    }
}
