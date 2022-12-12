Function CheckDiskSpace {
    <#
    .SYNOPSIS
    This function queries free space with options.
    
    .DESCRIPTION
    This function checks if there is enough free space. With parametars you can declare greater then 'Size', and 'Drive letter'.
    Default check is set to 'GreaterThan' based on free space. Choose any other operator as you wish.
    
    .PARAMETER Drive
    Mandatory - only local drives. Declare drive letter.
    .PARAMETER Size
    Mandatory - if free space is greater then the one declared.
    .PARAMETER Units
    NotMandatory - choose your unit of choice.
    .PARAMETER Type
    NotMandatory - default if set to 3.
    .PARAMETER OptionSize
    NotMandatory - pick an operator.

    .EXAMPLE
    CheckDiskSpace -Drive C -Size 60 ##-->(choose your size) 
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [ValidateRange('A', 'Z')]
        [string]$Drive,

        [Parameter(Mandatory = $true)]
        [int]$Size,

        [Parameter(Mandatory = $false)]
        [ValidateSet('KB', 'MB', 'GB', 'TB')]
        [string]$Units = 'GB',

        [Parameter(Mandatory = $false)]
        [ValidateSet('2', '3', '4', '5')]
        [string]$Type = '3',

        [Parameter(Mandatory = $false)]
        [ValidateSet('GreaterThan', 'LessThan', 'GreaterThanOrEqualTo', 'LessThanOrEqualTo', 'EqualTo', 'NotEqualTo')]
        [string]$OptionSize = 'GreaterThan'
    )
    switch ($Disks = Get-CimInstance Win32_LogicalDisk -Filter DriveType=$Type | `
            Select-Object DeviceID,
        @{'Name' = 'Size'; 'Expression' = { [math]::truncate($_.Size / "1$Units") } }, 
        @{'Name' = 'FreeSpace'; 'Expression' = { [math]::truncate($_.FreeSpace / "1$Units") } } | `
            Where-Object -Property DeviceID -EQ $Drive':') {
        { $OptionSize -eq 'GreaterThan' } { $Disks.FreeSpace -gt $Size }
        { $OptionSize -eq 'LessThan' } { $Disks.FreeSpace -lt $Size }
        { $OptionSize -eq 'GreaterThanOrEqualTo' } { $Disks.FreeSpace -ge $Size }
        { $OptionSize -eq 'LessThanOrEqualTo' } { $Disks.FreeSpace -le $Size }
        { $OptionSize -eq 'NotEqualTo' } { $Disks.FreeSpace -eq $Size }
        { $OptionSize -eq 'EqualTo' } { $Disks.FreeSpace -ne $Size }
    }
    return $Disks
}