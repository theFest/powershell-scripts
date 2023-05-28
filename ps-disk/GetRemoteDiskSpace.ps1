Function GetRemoteDiskSpace {
    <#
    .SYNOPSIS
    Retrieves disk space information for remote computers.

    .DESCRIPTION
    The GetRemoteDiskSpace function retrieves disk space information for one or more remote computers. It provides details such as used space, total space, and percentage used for each disk on the specified computers.

    .PARAMETER ComputerName
    Mandatory - name or IP address of the remote computer(s) to retrieve disk space information from. Multiple computer names can be provided.
    .PARAMETER WarningThreshold
    NotMandatory - the threshold percentage for the used disk space. If the used disk space exceeds this threshold, it will be displayed as a warning. The default value is 80.
    .PARAMETER ErrorThreshold
    NotMandatory - the threshold percentage for the used disk space. If the used disk space exceeds this threshold, it will be displayed as an error. The default value is 90.
    .PARAMETER Username
    NotMandatory - specifies the username to use for authenticating with the remote computers. If not provided, the current user context will be used.
    .PARAMETER Pass
    NotMandatory - specifies the password for the specified username. This parameter expects a secure string. If not provided, the function will prompt for the password.
    .PARAMETER PingBefore
    NotMandatory - ping the remote computers before retrieving disk space information. If a computer fails to respond to the ping request, it will be skipped. By default, this parameter is not set.
    .PARAMETER FilterSystemDrive
    NotMandatory - exclude the system drive (usually C:) from the disk space information. By default, the system drive is included.
    .PARAMETER TotalDiskSpace
    NotMandatory - display the total disk space for each disk. If set, the function will display the total disk space in GB. By default, this parameter is not set.
    .PARAMETER TotalPercentageUsed
    NotMandatory - specifies whether to display the total percentage used for each disk. If set, the function will display the total percentage used. By default, this parameter is not set.
    
    .EXAMPLE
    GetRemoteDiskSpace -ComputerName "" -Username "" -Pass "" -WarningThreshold 75 -ErrorThreshold 90 
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Alias('CN')]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $false, Position = 1)]
        [Alias('WT')]
        [int]$WarningThreshold = 80,

        [Parameter(Mandatory = $false, Position = 2)]
        [Alias('ET')]
        [int]$ErrorThreshold = 90,

        [Parameter(Mandatory = $false, Position = 3)]
        [Alias('U')]
        [string]$Username,

        [Parameter(Mandatory = $false, Position = 4)]
        [Alias('P')]
        [string]$Pass,

        [Parameter(Mandatory = $false)]
        [Alias('PB')]
        [switch]$PingBefore,

        [Parameter(Mandatory = $false)]
        [Alias('FS')]
        [switch]$FilterSystemDrive,

        [Parameter(Mandatory = $false)]
        [Alias('TD')]
        [switch]$TotalDiskSpace,

        [Parameter(Mandatory = $false)]
        [Alias('TP')]
        [switch]$TotalPercentageUsed
    )
    BEGIN {
        if ($PingBefore) {
            foreach ($Computer in $ComputerName) {
                Write-Host "Pinging $Computer..."
                if (-not (Test-Connection -ComputerName $Computer -Quiet)) {
                    Write-Error "Failed to ping $Computer."
                    continue
                }
            }
        }
    }
    PROCESS {
        $Credential = New-Object System.Management.Automation.PSCredential($Username, (ConvertTo-SecureString $Pass -AsPlainText -Force))
        foreach ($Computer in $ComputerName) {
            try {
                $Disks = Get-WmiObject -ComputerName $Computer -Class Win32_LogicalDisk -Filter "DriveType = 3" -Credential $Credential `
                | Select-Object DeviceID, FreeSpace, Size
            }
            catch {
                Write-Error -Message "Failed to retrieve disk information from $Computer : $($_.Exception.Message)"
                continue
            }
            foreach ($Disk in $Disks) {
                if ($FilterSystemDrive -and $Disk.DeviceID -eq 'C:') {
                    continue
                }
                $UsedSpace = ($Disk.Size - $Disk.FreeSpace) / $Disk.Size * 100
                if ($TotalDiskSpace) {
                    $totalDiskSpace = $Disk.Size / 1GB
                    Write-Host "$Computer $($Disk.DeviceID) Total Disk Space: $TotalDiskSpace GB" -ForegroundColor Cyan
                }
                if ($TotalPercentageUsed) {
                    $TotalPercentageUsed = 100 - ($Disk.FreeSpace / $Disk.Size * 100)
                    Write-Host "$Computer $($Disk.DeviceID) Total Percentage Used: $TotalPercentageUsed%" -ForegroundColor Cyan
                }
                if ($UsedSpace -gt $ErrorThreshold) {
                    Write-Host "$Computer $($Disk.DeviceID) Used Space: $($UsedSpace)%" -ForegroundColor Red
                }
                elseif ($UsedSpace -gt $WarningThreshold) {
                    Write-Host "$Computer $($Disk.DeviceID) Used Space: $($UsedSpace)%" -ForegroundColor Yellow
                }
                else {
                    Write-Host "$Computer $($Disk.DeviceID) Used Space: $($UsedSpace)%" -ForegroundColor Green
                }
            }
        }
    }
    END {
        if ($Username -or $Pass) {
            Clear-History -ErrorAction SilentlyContinue
            Clear-Variable -Name ComputerName, Credential, Username, Pass -Force -ErrorAction SilentlyContinue
            Remove-Variable -Name ComputerName, Credential, Username, Pass -Force -ErrorAction SilentlyContinue
        }
    }
}
