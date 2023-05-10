#Requires -Version 5.1
Function DiskOperationsManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "GetVolumeList", "ChangeDriveLabel", "ChangeDriveLetter", "MountDiskImage", "UnmountDiskImage", `
                "ToggleVSS", "FormatDrive", "EjectDrive", "ShrinkVolume", "ExtendVolume", "InitializeDisk", "ClearDisk", `
                "RepairVolume", "OptimizeVolume", "UpdateDisk", "RemovePartition", "AddPhysicalDisk", "RemovePhysicalDisk", `
                "EnableCompression", "DisableCompression", "GetPartitionSupportedSize", "AddPartitionAccessPath", "RemovePartitionAccessPath", `
                "SetQuota", "EnableBitLocker", "SetEncryption", "EnableBitLocker"
        )]
        [string]$Action,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$DriveLetter,

        [string]$NewDriveLabel,

        [string]$NewDriveLetter,

        [switch]$IncludeDriveType,

        [switch]$IncludeStatus,

        [switch]$IncludePercentages,

        [switch]$IncludeHealthStatus,

        [switch]$IncludeFileSystemType,

        [switch]$IncludeVolumeGuid
    )
    $DriveInfo = Get-Volume -DriveLetter $DriveLetter
    try {
        switch ($Action) {
            "GetVolumeList" {
                $Volumes = Get-Volume
                Write-Output $Volumes
                return
            }  
            "ChangeDriveLabel" {
                if ($NewDriveLabel) {
                    $DriveInfo.FileSystemLabel = $NewDriveLabel
                    $DriveInfo | Set-Volume -NewFileSystemLabel $NewDriveLabel -Verbose
                    Write-Output "Drive label set to '$NewDriveLabel'"
                    return
                }
            }
            "ChangeDriveLetter" {
                if ($NewDriveLetter) {
                    $Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$DriveLetter`:'"
                    $Drive | Set-CimInstance -Property @{DriveLetter = "$NewDriveLetter`:" } -Verbose
                    Write-Output "Drive letter set to '$NewDriveLetter'"
                    return
                }
            }
            "MountDiskImage" {
                if ($NewDriveLetter) {
                    Mount-DiskImage -ImagePath $ImagePath -StorageType ISO -PassThru | Get-Volume | Set-Partition -NewDriveLetter $NewDriveLetter -Verbose
                    Write-Output "Drive mounted as $NewDriveLetter"
                    return
                }
            }
            "UnmountDiskImage" {
                if ($DriveLetter) {
                    Dismount-DiskImage -DevicePath $DriveLetter -Verbose
                    Write-Output "Drive unmounted"
                    return
                }
            }
            "ToggleVSS" {
                $VSSStatus = Get-Service -Name 'VSS' | Select-Object -ExpandProperty Status
                if ($VSSStatus -eq 'Running') {
                    Stop-Service -Name 'VSS' -Verbose
                    Write-Output "Volume Shadow Copy Service stopped."
                }
                elseif ($VSSStatus -eq 'Stopped') {
                    Start-Service -Name 'VSS' -Verbose
                    Write-Output "Volume Shadow Copy Service started."
                }
            }
            "FormatDrive" {
                $FileSystemType = Read-Host "Enter the file system type (NTFS, FAT32, etc.):"
                $DriveInfo | Format-Volume -FileSystemLabel $DriveInfo.FileSystemLabel -FileSystemType $FileSystemType -Verbose -Confirm:$false
                Write-Output "Drive formatted with $FileSystemType file system."
                return
            }
            "EjectDrive" {
                $Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$DriveLetter`:'"
                $Drive | Invoke-CimMethod -MethodName Dismount -Verbose
                Write-Output "Drive ejected."
                return
            }
            "ShrinkVolume" {
                $ShrinkAmount = Read-Host "Enter the amount in GB to shrink the volume by"
                $DriveInfo | Resize-Partition -Size ($DriveInfo.SizeRemaining - $ShrinkAmount * 1GB) -Verbose -Confirm:$false
                Write-Output "Volume shrunk by $ShrinkAmount GB"
                return
            }
            "ExtendVolume" {
                $ExtendAmount = Read-Host "Enter the amount in GB to extend the volume by"
                $DriveInfo | Resize-Partition -Size ($DriveInfo.Size + $ExtendAmount * 1GB) -Verbose -Confirm:$false
                Write-Output "Volume extended by $ExtendAmount GB"
                return
            }
            "InitializeDisk" {
                $Disk = Get-Disk -Number $DiskNumber
                Initialize-Disk -InputObject $Disk -PartitionStyle MBR -Verbose
                Write-Output "Disk initialized"
                return
            }
            "ClearDisk" {
                $Disk = Get-Disk -Number $DiskNumber
                Clear-Disk -InputObject $Disk -RemoveData -RemoveOEM -Verbose -Confirm:$false
                Write-Output "Disk cleared"
                return
            }
            "RepairVolume" {
                Repair-Volume -DriveLetter $DriveLetter -Verbose
                Write-Output "Volume repaired"
                return
            }
            "OptimizeVolume" {
                Optimize-Volume -DriveLetter $DriveLetter -Analyze -Verbose
                Write-Output "Volume optimized"
                return
            }
            "UpdateDisk" {
                $Disk = Get-Disk -Number $DiskNumber
                Update-Disk -InputObject $Disk
                Write-Output "Disk updated"
                return
            }
            "RemovePartition" {
                $Partition = Get-Partition -DriveLetter $DriveLetter
                Remove-Partition -InputObject $Partition -Confirm:$false
                Write-Output "Partition removed"
                return
            }
            "AddPhysicalDisk" {
                $Pool = Get-StoragePool -FriendlyName $PoolName
                $Disk = Get-PhysicalDisk -UniqueId $DiskUniqueId
                Add-PhysicalDisk -StoragePool $Pool -PhysicalDisks $Disk
                Write-Output "Physical disk added to storage pool"
                return
            }
            "RemovePhysicalDisk" {
                $Pool = Get-StoragePool -FriendlyName $PoolName
                $Disk = Get-PhysicalDisk -UniqueId $DiskUniqueId
                Remove-PhysicalDisk -StoragePool $Pool -PhysicalDisks $Disk
                Write-Output "Physical disk removed from storage pool"
                return
            }
            "EnableCompression" {
                try {
                    $DriveInfo.Attributes += [System.IO.FileAttributes]::Compressed
                    Write-Verbose "Enabled compression on drive $($DriveInfo.Root)"
                    Write-Output "Compression enabled on drive $($DriveInfo.Root)"
                }
                catch {
                    Write-Warning "Failed to enable compression on drive $($DriveInfo.Root): $_"
                }
                return
            }
            "DisableCompression" {
                try {
                    $DriveInfo.Attributes -= [System.IO.FileAttributes]::Compressed
                    Write-Verbose "Disabled compression on drive $($DriveInfo.Root)"
                    Write-Output "Compression disabled on drive $($DriveInfo.Root)"
                }
                catch {
                    Write-Warning "Failed to disable compression on drive $($DriveInfo.Root): $_"
                }
                return
            }
            "NewPartition" {
                New-Partition -DiskNumber $DriveInfo.DiskNumber -DriveLetter $NewDriveLetter -UseMaximumSize
                Write-Output "New partition created with drive letter '$NewDriveLetter'"
                return
            }
            "CreatePartition" {
                if ($DriveInfo.PartitionStyle -eq "RAW") {
                    $result = New-Partition -DiskNumber $DriveInfo.DiskNumber -Size 20GB -DriveLetter $NewDriveLetter
                    if ($result) {
                        Write-Output "New partition created on drive $($DriveLetter) with drive letter $($NewDriveLetter)."
                        return
                    }
                    else {
                        Write-Warning "Failed to create new partition on drive $($DriveLetter)."
                        return
                    }
                }
                else {
                    Write-Warning "Drive $($DriveLetter) already has a partition and cannot create a new one."
                    return
                }
            }
            "GetPartitionSupportedSize" {
                $Disk = Get-Disk -Number $DiskNumber
                $SupportedSize = Get-PartitionSupportedSize -Disk $Disk
                Write-Output "Minimum size: $($SupportedSize.MinimumSize) Maximum size: $($SupportedSize.MaximumSize)"
                return
            }
            "AddPartitionAccessPath" {
                $Partition = Get-Partition -DriveLetter $DriveLetter
                Add-PartitionAccessPath -InputObject $Partition -AssignDriveLetter
                Write-Output "Drive letter assigned to partition"
                return
            }
            "RemovePartitionAccessPath" {
                $Partition = Get-Partition -DriveLetter $DriveLetter
                Remove-PartitionAccessPath -InputObject $Partition -AssignDriveLetter
                Write-Output "Drive letter removed from partition"
                return
            }
            "SetQuota" {
                if ($NewQuotaLimitGB) {
                    $DriveInfo | Set-FsrmQuota -Size $NewQuotaLimitGB -Verbose
                    Write-Output "Quota limit set to '$NewQuotaLimitGB' GB"
                    return
                }
            }
            "SetEncryption" {
                if ($EnableEncryption) {
                    $DriveInfo | Enable-BitLocker -Verbose
                    Write-Output "Encryption enabled on drive"
                    return
                }
                if ($DisableEncryption) {
                    $DriveInfo | Disable-BitLocker -Verbose
                    Write-Output "Encryption disabled on drive"
                    return
                }
            }
            "EnableBitLocker" {
                $Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$DriveLetter`:'"
                $ProtectionMethod = "TPMAndPIN"
                $BitLockerKeyProtector = $Drive | Add-BitLockerKeyProtector -TPMAndPIN -RecoveryPasswordProtector
                $BitLockerKeyProtector | Enable-BitLocker -MountPoint "$($Drive.DeviceID)\\" -EncryptionMethod "Aes256" -UsedSpaceOnly -SkipHardwareTest -SkipTrim -Verbose
                Write-Output "BitLocker encryption enabled on drive $($Drive.DeviceID)"
                return
            }
        }
    }
    catch {
        Write-Warning -Message "Failed to import data. Error: $_"
    }
    $volLabel = $DriveInfo.FileSystemLabel
    $VolSize = "{0:N2}" -f ($DriveInfo.Size / 1GB) + " GB"
    $VolFreeSpace = "{0:N2}" -f ($DriveInfo.SizeRemaining / 1GB) + " GB"
    $VolUsedSpace = "{0:N2}" -f (($DriveInfo.Size - $DriveInfo.SizeRemaining) / 1GB) + " GB"
    Write-Output "Volume Information for drive $($DriveLetter):"
    Write-Output "Label: $($VolLabel)"
    Write-Output "Size: $($VolSize)"
    Write-Output "Free Space: $($VolFreeSpace)"
    Write-Output "Used Space: $($VolUsedSpace)"
    if ($IncludeDriveType) {
        $DriveType = $DriveInfo.DriveType
        Write-Output "Drive Type: $($DriveType)"
    }  
    if ($IncludeStatus) {
        $Status = $DriveInfo.OperationalStatus
        Write-Output "Operational Status: $Status"
    }
    if ($IncludePercentages) {
        $volFreePercent = "{0:N2}" -f (($DriveInfo.SizeRemaining / $DriveInfo.Size) * 100) + "%"
        $volUsedPercent = "{0:N2}" -f ((($DriveInfo.Size - $DriveInfo.SizeRemaining) / $DriveInfo.Size) * 100) + "%"
        Write-Output "Free Space (%): $($VolFreePercent)"
        Write-Output "Used Space (%): $($VolUsedPercent)"
    }
    if ($IncludeFileSystemType) {
        $FileSystemType = $driveInfo.FileSystemType
        Write-Output "File System Type: $FileSystemType"
    }
    if ($IncludeHealthStatus) {
        $healthStatus = $driveInfo.HealthStatus
        Write-Output "Health Status: $healthStatus"
    }
    if ($IncludeVolumeGuid) {
        $VolumeGuid = $DriveInfo.UniqueId
        Write-Output "Volume GUID: $VolumeGuid"
    }
}

## 
DiskOperationsManager -Action GetVolumeList #-DriveLetter "C" -IncludePercentages -IncludeHealthStatus -IncludeFileSystemType -IncludeDriveType -IncludeVolumeGuid -IncludeStatus
#Get-VolumeInformation -DriveLetter "C" -NewDriveLabel 
