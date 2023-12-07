Function Get-VolumeList {
    <#
    .SYNOPSIS
    Retrieves a list of volumes based on specified criteria.

    .DESCRIPTION
    This function retrieves a list of volumes based on DriveLetter, FileSystem, DriveType, and other optional parameters provided. It filters volumes based on the specified criteria and displays volume information.

    .PARAMETER DriveLetter
    Mandatory - the drive letter of the volume to retrieve.
    .PARAMETER FileSystem
    NotMandatory - file system of the volumes to retrieve. Valid values are NTFS, FAT32, or exFAT.
    .PARAMETER DriveType
    NotMandatory - type of drive to retrieve. Valid values are Fixed, Removable, CD-ROM, or Unknown.
    .PARAMETER HealthyOnly
    NotMandatory - retrieves only volumes with the 'Healthy' operational status.
    .PARAMETER ShowDetails
    NotMandatory - displays detailed information about the volumes including DriveLetter, FileSystem, DriveType, HealthStatus, OperationalStatus, SizeRemaining, and Size.
    .PARAMETER ExportToCsv
    NotMandatory - exports the output results to a CSV file.

    .EXAMPLE
    Get-VolumeList -DriveLetter "C" -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[A-Za-z]$')]
        [string]$DriveLetter,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateSet("NTFS", "FAT32", "exFAT")]
        [string]$FileSystem,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateSet("Fixed", "Removable", "CD-ROM", "Unknown")]
        [string]$DriveType,

        [Parameter(Mandatory = $false)]
        [switch]$HealthyOnly,

        [Parameter(Mandatory = $false)]
        [switch]$ShowDetails,

        [Parameter(Mandatory = $false)]
        [string]$ExportToCsv
    )
    BEGIN {
        $Volumes = Get-Volume
    }
    PROCESS {
        if ($DriveLetter) {
            $Volumes = $Volumes | Where-Object { $_.DriveLetter -eq $DriveLetter }
        }
        if ($FileSystem) {
            $Volumes = $Volumes | Where-Object { $_.FileSystem -eq $FileSystem }
        }
        if ($DriveType) {
            $Volumes = $Volumes | Where-Object { $_.DriveType -eq $DriveType }
        }
        if ($HealthyOnly) {
            $Volumes = $Volumes | Where-Object { $_.OperationalStatus -eq 'Healthy' }
        }
        if ($ShowDetails) {
            $Volumes | Format-Table -Property DriveLetter, FileSystem, DriveType, HealthStatus, OperationalStatus, SizeRemaining, Size, DriveLetter
        }
        else {
            Write-Output -InputObject $Volumes
        }
    }
    END {
        if ($ExportToCsv) {
            Write-Verbose -Message "Exporting results to a csv file..."
            $Volumes | Export-Csv -Path $ExportToCsv -NoTypeInformation -Force -Verbose
        }
    }
}
