Function Set-PartitionAccessPath {
    <#
    .SYNOPSIS
    Assigns or removes a drive letter from a partition.

    .DESCRIPTION
    This function assigns or removes a drive letter from a partition.

    .PARAMETER DriveLetter
    Mandatory - the drive letter to assign to or remove from the partition.
    .PARAMETER Mode
    Mandatory - specifies the action to perform (Assign/Remove).

    .EXAMPLE
    Set-PartitionAccessPath -DriveLetter "D" -Mode "Assign"

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
        [ValidateSet("Assign", "Remove")]
        [string]$Mode
    )

    BEGIN {
        try {
            $Partition = Get-Partition -DriveLetter $DriveLetter
            Write-Verbose -Message "Initial Drive Letter Information:"
            Write-Output $Partition | Format-Table -AutoSize
        }
        catch {
            Write-Error -Message "Error during initialization: $_"
        }
    }
    PROCESS {
        try {
            switch ($Mode) {
                "Assign" {
                    if (-not ($Partition.AccessPaths -contains "$DriveLetter`:\")) {
                        $DriveLetterObj = ($Partition | Get-WmiObject).GetRelated("Win32_DiskPartition") | Where-Object { $_.Type -eq "DRIVE LETTER" -and $_.DeviceID -eq "$DriveLetter`:" }
                        $DriveLetterObj.SetAccessPath("$DriveLetter`:\")
                        Write-Host "Drive letter assigned to partition" -ForegroundColor Green
                    }
                    else {
                        Write-Warning -Message "Drive letter already assigned to partition"
                    }
                }
                "Remove" {
                    if ($Partition.AccessPaths -contains "$DriveLetter`:\") {
                        $DriveLetterObj = ($Partition | Get-WmiObject).GetRelated("Win32_DiskPartition") | Where-Object { $_.Type -eq "DRIVE LETTER" -and $_.DeviceID -eq "$DriveLetter`:" }
                        $DriveLetterObj.SetAccessPath($null)
                        Write-Host "Drive letter removed from partition" -ForegroundColor Green
                    }
                    else {
                        Write-Warning -Message "Drive letter not assigned to partition"
                    }
                }
                default {
                    Write-Error -Message "Invalid mode selected. Use 'Assign' or 'Remove'."
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
            $Partition = Get-Partition -DriveLetter $DriveLetter
            Write-Verbose -Message "Final Drive Letter Information:"
            Write-Output $Partition | Format-Table -AutoSize
        }
        catch {
            Write-Error -Message "Error during cleanup: $_"
        }
    }
}
