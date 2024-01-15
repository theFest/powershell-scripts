Function Enable-OfflineDiskState {
    <#
    .SYNOPSIS
    Enables users to take eligible disks offline on a Windows system.

    .DESCRIPTION
    This function identifies disks based on operational status and presence in the boot configuration, it presents a menu allowing users to select a disk for offline status. Handles scenarios like preventing the system disk from being taken offline, unless overridden by the -Force parameter.

    .PARAMETER Force
    Specifies whether to override the restriction preventing the system disk from being taken offline.

    .EXAMPLE
    Enable-OfflineDiskState

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force = $false
    )
    $Disks = Get-Disk | Where-Object { $_.OperationalStatus -eq 'Online' -and $_.BootFromDisk -eq $false }
    if ($Disks.Count -eq 0) {
        Write-Warning -Message "No eligible disks found for taking offline!"
        return
    }
    $GroupedDisks = $Disks | Group-Object MediaType
    foreach ($Group in $GroupedDisks) {
        $MenuTitle = "Select a $($Group.Name) disk to take offline"
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
            Write-Host "Cannot take the system disk $($SelectedDisk.FriendlyName) offline. Use -Force parameter to override!"
        }
        else {
            Set-Disk -InputObject $SelectedDisk -IsOffline $true -Verbose
            Write-Host "$($SelectedDisk.FriendlyName) has been taken offline" -ForegroundColor Green
        }
    }
}
