Function Edit-StorageDiskPool {
    <#
    .SYNOPSIS
    Initializes, clears, updates, adds, or removes a disk from a storage pool.

    .DESCRIPTION
    This function performs various operations on a disk within a storage pool.

    .PARAMETER DiskNumber
    Mandatory - the number of the disk to manage.
    .PARAMETER PoolName
    Mandatory - the name of the storage pool.
    .PARAMETER DiskUniqueId
    Mandatory - the unique ID of the disk.
    .PARAMETER Operation
    Mandatory - operation to perform (Initialize, Clear, Update, AddToPool, RemoveFromPool).

    .EXAMPLE
    Edit-StorageDiskPool -DiskNumber 1 -PoolName "MyPool" -DiskUniqueId "12345678" -Operation "Initialize"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$DiskNumber,

        [Parameter(Mandatory = $true)]
        [string]$PoolName,

        [Parameter(Mandatory = $true)]
        [string]$DiskUniqueId,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Initialize", "Clear", "Update", "AddToPool", "RemoveFromPool")]
        [string]$Operation
    )
    BEGIN {
        try {
            $Disk = Get-Disk -Number $DiskNumber
        }
        catch {
            Write-Error -Message "Error during initialization: $_"
        }
    }
    PROCESS {
        try {
            switch ($Operation) {
                "Initialize" {
                    Initialize-Disk -InputObject $Disk -PartitionStyle MBR -Verbose
                    Write-Host "Disk initialized" -ForegroundColor Green
                }
                "Clear" {
                    Clear-Disk -InputObject $Disk -RemoveData -RemoveOEM -Verbose -Confirm:$false
                    Write-Host "Disk cleared" -ForegroundColor Green
                }
                "Update" {
                    Update-Disk -InputObject $Disk -Verbose
                    Write-Host "Disk updated" -ForegroundColor Green
                }
                "AddToPool" {
                    $Pool = Get-StoragePool -FriendlyName $PoolName
                    $Disk = Get-PhysicalDisk -UniqueId $DiskUniqueId
                    Add-PhysicalDisk -StoragePool $Pool -PhysicalDisks $Disk -Verbose
                    Write-Host "Physical disk added to storage pool" -ForegroundColor Green
                }
                "RemoveFromPool" {
                    $Pool = Get-StoragePool -FriendlyName $PoolName
                    $Disk = Get-PhysicalDisk -UniqueId $DiskUniqueId
                    Remove-PhysicalDisk -StoragePool $Pool -PhysicalDisks $Disk -Verbose
                    Write-Host "Physical disk removed from storage pool"
                }
                default {
                    Write-Error -Message "Invalid operation selected!"
                }
            }
        }
        catch {
            Write-Error -Message "Error during processing: $_"
        }
    }
    END {
        try {
            $DiskStatus = Get-Disk -Number $DiskNumber
            if ($DiskStatus.Status -eq "Online") {
                Write-Verbose -Message "Operation completed successfully."
            }
            else {
                Write-Warning -Message "Operation may not have completed successfully. Disk status: $($DiskStatus.Status)"
            }
        }
        catch {
            Write-Error -Message "Error during verification: $_"
        }
    }
}
