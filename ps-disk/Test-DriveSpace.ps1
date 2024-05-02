Function Test-DriveSpace {
    <#
    .SYNOPSIS
    Tests the free space on a specified drive.

    .DESCRIPTION
    This function checks the free space on a specified drive and compares it with the provided size.

    .PARAMETER Drive
    Specifies the drive letter (e.g., C).
    .PARAMETER Size
    Size to compare against.
    .PARAMETER Units
    Size units (KB, MB, GB, TB). Default is GB.
    .PARAMETER Type
    Drive type (2: Removable, 3: Local Disk, 4: Network Drive, 5: CD/DVD).
    .PARAMETER OptionSize
    Comparison operator, values are GreaterThan, LessThan, GreaterThanOrEqualTo, LessThanOrEqualTo, EqualTo, NotEqualTo.

    .EXAMPLE
    Test-DriveSpace -Drive C -Size 10 -Units GB

    .NOTES
    v0.2.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, HelpMessage = "Drive letter (e.g., C)")]
        [ValidatePattern("[A-Z]")]
        [string]$Drive,

        [Parameter(Mandatory, HelpMessage = "Size to compare against")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Size,

        [Parameter(HelpMessage = "Size units (KB, MB, GB, TB)")]
        [ValidateSet("KB", "MB", "GB", "TB")]
        [string]$Units = "GB",

        [Parameter(HelpMessage = "Drive type (2: Removable, 3: Local Disk, 4: Network Drive, 5: CD/DVD)")]
        [ValidateSet("2", "3", "4", "5")]
        [string]$Type = "3",

        [Parameter(HelpMessage = "Select the comparison operator")]
        [ValidateSet("GreaterThan", "LessThan", "GreaterThanOrEqualTo", "LessThanOrEqualTo", "EqualTo", "NotEqualTo")]
        [string]$OptionSize = "GreaterThan"
    )
    $driveType = @{
        '2' = 'Removable'
        '3' = 'Local Disk'
        '4' = 'Network Drive'
        '5' = 'CD/DVD'
    }[$Type]
    Write-Verbose -Message "Checking $driveType drives..."
    $Disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType = $Type" | Where-Object DeviceID -eq "${Drive}:"
    $Res = switch ($OptionSize) {
        "GreaterThan" { $Disks | Where-Object { $_.FreeSpace / "1$Units" -gt $Size } }
        "LessThan" { $Disks | Where-Object { $_.FreeSpace / "1$Units" -lt $Size } }
        "GreaterThanOrEqualTo" { $Disks | Where-Object { $_.FreeSpace / "1$Units" -ge $Size } }
        "LessThanOrEqualTo" { $Disks | Where-Object { $_.FreeSpace / "1$Units" -le $Size } }
        "EqualTo" { $Disks | Where-Object { $_.FreeSpace / "1$Units" -eq $Size } }
        "NotEqualTo" { $Disks | Where-Object { $_.FreeSpace / "1$Units" -ne $Size } }
    } 
    $Res | Select-Object DeviceID, VolumeName, @{Name = "Size($Units)"; Expression = { [math]::truncate($_.Size / "1$Units") } }, @{Name = "FreeSpace($Units)"; Expression = { [math]::truncate($_.FreeSpace / "1$Units") } }
}
