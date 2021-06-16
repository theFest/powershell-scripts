Function CheckDiskSpace {
    <#
    .SYNOPSIS
    This function queries free space in GB.
    
    .DESCRIPTION
    This function checks if there is enough free space. With parametars you can declare greater then 'Size', and 'Drive letter'.
    
    .PARAMETER Drive
    Mandatory - only local drives. Declare drive letter.
    .PARAMETER Size
    Mandatory - if free space is greater then the one declared.

    .EXAMPLE
    CheckDiskSpace -Drive C: -Size 24
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Drive,

        [Parameter(Mandatory = $true)]
        [string]$Size
    )
    $Disks = Get-WmiObject Win32_LogicalDisk -Filter DriveType=3 | `
        Select-Object DeviceID,
    @{'Name' = 'Size'; 'Expression' = { [math]::truncate($_.Size / 1GB) } }, 
    @{'Name' = 'FreeSpace'; 'Expression' = { [math]::truncate($_.FreeSpace / 1GB) } } | `
        Where-Object -Property DeviceID -EQ $Drive
    if ($Disks.FreeSpace -gt $Size) {
        $DiskReady = $true
    }
    else {
        $DiskReady = $false
    }
    return $DiskReady
}