Function DiskOperationsManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateSet("ChangeDriveLabel", "ChangeDriveLetter")]
        [string]$Action,

        [Parameter(Mandatory = $true)]
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
Get-VolumeInformation -DriveLetter "C" -IncludePercentages -IncludeHealthStatus -IncludeFileSystemType -IncludeDriveType -IncludeVolumeGuid -IncludeStatus
#Get-VolumeInformation -DriveLetter "C" -NewDriveLabel 



### OPTIONS FOR SWITCH
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
"GetVolumeList" {
    $volumes = Get-Volume
    Write-Output $volumes
    return
}  
"FormatDrive" {
    $FileSystemType = Read-Host "Enter the file system type (NTFS, FAT32, etc.):"
    $DriveInfo | Format-Volume -FileSystemLabel $DriveInfo.FileSystemLabel -FileSystemType $FileSystemType -Confirm:$false
    Write-Output "Drive formatted with $FileSystemType file system."
    return
}
"UnmountVolume" {
    Dismount-Volume -DriveLetter $DriveLetter -Confirm:$false
    Write-Output "Drive successfully unmounted."
    return
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
"EjectDrive" {
    $Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$DriveLetter`:'"
    $Drive | Invoke-CimMethod -MethodName Dismount -Verbose
    Write-Output "Drive ejected."
    return
}
"EjectRemovableDrive" {
    if ($DriveInfo.DriveType -eq "Removable") {
        Eject-Disk -Number $DriveInfo.DiskNumber -Confirm:$false -PassThru | Out-Null
        Write-Output "Drive $($DriveLetter) has been ejected."
        return
    }
    else {
        Write-Warning "Drive $($DriveLetter) is not a removable drive and cannot be ejected."
        return
    }
}
"SetCompression" {
    if ($EnableCompression) {
        $DriveInfo | Enable-FileCompression -Verbose
        Write-Output "Compression enabled on drive"
        return
    }
    if ($DisableCompression) {
        $DriveInfo | Disable-FileCompression -Verbose
        Write-Output "Compression disabled on drive"
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
"SetQuota" {
    if ($NewQuotaLimitGB) {
        $DriveInfo | Set-FsrmQuota -Size $NewQuotaLimitGB -Verbose
        Write-Output "Quota limit set to '$NewQuotaLimitGB' GB"
        return
    }
}
"ResizeDrive" {
    if ($NewDriveSizeGB) {
        $DriveInfo | Resize-Partition -Size $NewDriveSizeGB -Verbose
        Write-Output "Drive size changed to '$NewDriveSizeGB' GB"
        return
    }
}
"ShrinkVolume" {
    $ShrinkAmount = Read-Host "Enter the amount in GB to shrink the volume by"
    $DriveInfo | Resize-Partition -Size ($DriveInfo.SizeRemaining - $ShrinkAmount * 1GB) -Confirm:$false
    Write-Output "Volume shrunk by $ShrinkAmount GB"
    return
}
"ExtendVolume" {
    $ExtendAmount = Read-Host "Enter the amount in GB to extend the volume by"
    $DriveInfo | Resize-Partition -Size ($DriveInfo.Size + $ExtendAmount * 1GB) -Confirm:$false
    Write-Output "Volume extended by $ExtendAmount GB"
    return
}
"EnableCompression" {
    $DriveInfo | Enable-FileCompression -Force
    Write-Output "Compression enabled on drive"
    return
}
"DisableCompression" {
    $DriveInfo | Disable-FileCompression -Force
    Write-Output "Compression disabled on drive"
    return
}

"InitializeDisk" {
    $Disk = Get-Disk -Number $DriveInfo.DiskNumber
    Initialize-Disk -InputObject $Disk -PartitionStyle MBR
    Write-Output "Disk initialized"
    return
}
"EnableBitLocker" {
    $Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$DriveLetter`:'"
    $ProtectionMethod = "TPMAndPIN"
    $BitLockerKeyProtector = $Drive | Add-BitLockerKeyProtector -TPMAndPIN -RecoveryPasswordProtector
    $BitLockerKeyProtector | Enable-BitLocker -MountPoint "$($Drive.DeviceID)\\" -EncryptionMethod "Aes256" -UsedSpaceOnly -SkipHardwareTest -SkipTrim -Verbose
    Write-Output "BitLocker encryption enabled on drive $($Drive.DeviceID)"
    return
}
"RemovePartition" {
    $Partition = Get-Partition -DriveLetter $DriveLetter
    Remove-Partition -InputObject $Partition -Confirm:$false
    Write-Output "Partition removed"
    return
}
"ResizePartition" {
    $Partition = Get-Partition -DriveLetter $DriveLetter
    Resize-Partition -InputObject $Partition -Size 50GB
    Write-Output "Partition resized"
    return
}
"ConvertFileSystem" {
    if ($DriveInfo.FileSystemType -eq "FAT32") {
        $result = ConvertTo-Ntfs -DriveLetter $DriveLetter -Confirm:$false
        if ($result -eq $true) {
            Write-Output "File system of drive $($DriveLetter) has been converted to NTFS."
            return
        }
        else {
            Write-Warning "Failed to convert file system of drive $($DriveLetter) to NTFS."
            return
        }
    }
    else {
        Write-Warning "Drive $($DriveLetter) is already using the NTFS file system and cannot be converted."
        return
    }
}
"Add-PartitionAccessPath" {
    $Partition = Get-Partition -DriveLetter $DriveLetter
    Add-PartitionAccessPath -InputObject $Partition -AssignDriveLetter
    Write-Output "Drive letter assigned to partition"
    return
}
"Remove-PartitionAccessPath" {
    $Partition = Get-Partition -DriveLetter $DriveLetter
    Remove-PartitionAccessPath -InputObject $Partition -AssignDriveLetter
    Write-Output "Drive letter removed from partition"
    return
}
"Set-PartitionType" {
    $Partition = Get-Partition -DriveLetter $DriveLetter
    Set-PartitionType -InputObject $Partition -GptType "EBD0A0A2-B9E5-4433-87C0-68B6B72699C7"
    Write-Output "Partition type set"
    return
}
"Get-PartitionSupportedSize" {
    $Disk = Get-Disk -Number $DiskNumber
    $SupportedSize = Get-PartitionSupportedSize -Disk $Disk
    Write-Output "Minimum size: $($SupportedSize.MinimumSize) Maximum size: $($SupportedSize.MaximumSize)"
    return
}
"Initialize-Disk" {
    $Disk = Get-Disk -Number $DiskNumber
    Initialize-Disk -InputObject $Disk -PartitionStyle MBR
    Write-Output "Disk initialized"
    return
}
"Clear-Disk" {
    $Disk = Get-Disk -Number $DiskNumber
    Clear-Disk -InputObject $Disk -RemoveData -RemoveOEM -Confirm:$false
    Write-Output "Disk cleared"
    return
}
"Repair-Volume" {
    $Volume = Get-Volume -DriveLetter $DriveLetter
    Repair-Volume -DriveLetter $DriveLetter
    Write-Output "Volume repaired"
    return
}
"Optimize-Volume" {
    $Volume = Get-Volume -DriveLetter $DriveLetter
    Optimize-Volume -DriveLetter $DriveLetter -Analyze -Verbose
    Write-Output "Volume optimized"
    return
}
"Update-Disk" {
    $Disk = Get-Disk -Number $DiskNumber
    Update-Disk -InputObject $Disk
    Write-Output "Disk updated"
    return
}
"Add-PhysicalDisk" {
    $Pool = Get-StoragePool -FriendlyName $PoolName
    $Disk = Get-PhysicalDisk -UniqueId $DiskUniqueId
    Add-PhysicalDisk -StoragePool $Pool -PhysicalDisks $Disk
    Write-Output "Physical disk added to storage pool"
    return
}
"Remove-PhysicalDisk" {
    $Pool = Get-StoragePool -FriendlyName $PoolName
    $Disk = Get-PhysicalDisk -UniqueId $DiskUniqueId
    Remove-PhysicalDisk -StoragePool $Pool -PhysicalDisks $Disk
    Write-Output "Physical disk removed from storage pool"
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
"ExtendVolume" {
    $UnallocatedSpace = Get-Partition -DriveLetter $DriveLetter | Where-Object { $_.SizeRemaining -gt 0 }
    $SizeToAdd = Read-Host "Enter the amount of space (in GB) to add to the volume:"
    $SizeToAddBytes = $SizeToAdd * 1GB
    if ($UnallocatedSpace) {
        $DriveInfo | Resize-Partition -Size $DriveInfo.Size + $SizeToAddBytes
        Write-Output "Volume extended by $SizeToAdd GB."
        return
    }
    else {
        Write-Warning "No unallocated space available on this disk."
        return
    }
}
"ExpandVolume" {
    if ($NewVolumeSize -gt $DriveInfo.Size) {
        $DriveInfo | Resize-Partition -Size ($NewVolumeSize - $DriveInfo.Size) -Verbose
        Write-Output "Drive expanded to $($NewVolumeSize)GB"
        return
    }
    elseif ($NewVolumeSize -lt $DriveInfo.Size) {
        Write-Warning -Message "Shrinking volumes is not supported yet."
        return
    }
}
