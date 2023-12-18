Function Format-DriveFileSystem {
    <#
    .SYNOPSIS
    Formats a drive with a specified file system type.

    .DESCRIPTION
    This function formats a drive with the specified file system type.

    .PARAMETER DriveLetter
    Mandatory - the drive letter of the volume to be formatted.
    .PARAMETER FileSystemType
    Mandatory - the file system type to format the drive (e.g., NTFS, FAT32).
    .PARAMETER AllocationUnitSize
    NotMandatory - the allocation unit size for the new file system (default: 4096 bytes).
    .PARAMETER FullFormat
    NotMandatory - performs a full format instead of a quick format (default: $false).
    .PARAMETER Eject
    NotMandatory - ejects the drive after formatting (default: $false).

    .EXAMPLE
    Format-DriveFileSystem -DriveLetter "D" -FileSystemType "NTFS" -AllocationUnitSize 8192 -FullFormat -Eject

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
        [string]$FileSystemType,

        [Parameter(Mandatory = $false)]
        [ValidateRange(512, 2147483647)]
        [int]$AllocationUnitSize = 4096,

        [Parameter(Mandatory = $false)]
        [switch]$FullFormat,

        [Parameter(Mandatory = $false)]
        [switch]$Eject
    )
    BEGIN {
        $DriveInfo = Get-Volume -DriveLetter $DriveLetter
    }
    PROCESS {
        try {
            $FormatParams = @{
                FileSystemLabel    = $DriveInfo.FileSystemLabel
                FileSystemType     = $FileSystemType
                AllocationUnitSize = $AllocationUnitSize
                Confirm            = $false
            }
            if ($FullFormat) {
                $FormatParams['FullFormat'] = $true
                Write-Verbose -Message "Performing a full format."
            }
            else {
                Write-Verbose -Message "Performing a quick format."
            }
            $DriveInfo | Format-Volume @FormatParams -Verbose
            Write-Output "Drive $DriveLetter formatted with $FileSystemType file system."
        }
        catch {
            Write-Error -Message "Error: $_"
        }
    }
    END {
        try {
            if ($Eject) {
                $Drive = Get-CimInstance -ClassName Win32_Volume -Filter "DriveLetter = '$DriveLetter`:'"
                $Drive | Invoke-CimMethod -MethodName Dismount -Verbose
                Write-Host "Drive $DriveLetter ejected" -ForegroundColor DarkCyan
            }
        }
        catch {
            Write-Error -Message "Error ejecting the drive: $_"
        }
    }
}
