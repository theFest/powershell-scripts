Function Enable-OnlineDiskState {
    <#
    .SYNOPSIS
    Enables users to bring eligible offline disks online on a Windows system.

    .DESCRIPTION
    This function identifies offline disks based on operational status and non-presence in the boot configuration, it presents a menu allowing users to select an offline disk to bring online. Handles scenarios like preventing the system disk from being brought online unless overridden by the -Force parameter.

    .PARAMETER Force
    Specifies whether to override the restriction preventing the system disk from being brought online.

    .EXAMPLE
    Enable-OnlineDiskState

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force = $false
    )
    $OfflineDisks = Get-Disk | Where-Object { $_.OperationalStatus -eq 'Offline' -and $_.BootFromDisk -eq $false }
    if ($OfflineDisks.Count -eq 0) {
        Write-Warning -Message "No eligible disks found for bringing online!"
        return
    }
    $GroupedDisks = $OfflineDisks | Group-Object MediaType
    foreach ($Group in $GroupedDisks) {
        $MenuTitle = "Select a $($Group.Name) disk to bring online"
        $MenuItems = @{}
        $Index = 1
        foreach ($Disk in $Group.Group) {
            $MenuItems[$Index] = $Disk
            Write-Host "$Index. $($Disk.FriendlyName)"
            $Index++
        }
        do {
            $MenuChoice = Read-Host -Prompt $MenuTitle
        } while (-not ($MenuChoice -match '^\d+$' -and $MenuItems.ContainsKey([int]$MenuChoice)))
        $SelectedDisk = $MenuItems[[int]$MenuChoice]
        if ($SelectedDisk.IsSystem -and !$Force) {
            Write-Host "Cannot bring the system disk $($SelectedDisk.FriendlyName) online. Use -Force parameter to override!"
        }
        else {
            Set-Disk -InputObject $SelectedDisk -IsOffline $false -Verbose
            Write-Host "$($SelectedDisk.FriendlyName) has been brought online" -ForegroundColor Green
        }
    }
}
