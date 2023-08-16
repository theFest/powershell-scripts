Function ManageRestorePoint {
    <#
    .SYNOPSIS
    Manage system restore points on a Windows computer.

    .DESCRIPTION
    This function provides an easy way to create, customize, and restore system restore points on a Windows computer.
    System restore points are snapshots of your system's state that can be used to restore your computer to a previous state if issues arise.

    .PARAMETER Action
    Specifies the action to perform. Valid values are "Create", "Save", and "Restore".
    - Create: Creates a new system restore point.
    - Save: Creates a custom system restore point with additional options.
    - Restore: Restores the system to the most recent restore point.

    .PARAMETER Description
    Mandatory - description for the restore point. Only used when Action is "Create" or "Save".
    .PARAMETER IncludeRegistry
    NotMandatory - includes the system registry in the restore point. Only used when Action is "Save".
    .PARAMETER IncludeDrivers
    NotMandatory - includes drivers in the restore point. Only used when Action is "Save".

    .EXAMPLE
    ManageRestorePoint -Action Create -Description "Before software installation"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Create", "Save", "Restore")]
        [string]$Action,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeRegistry,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDrivers
    )
    switch ($Action) {
        "Create" {
            Write-Host "Creating a new system restore point..."
            $null = Checkpoint-Computer -Description $Description
            Write-Host "System restore point created." -ForegroundColor Green
        }
        "Save" {
            Write-Host "Creating a custom system restore point..." -ForegroundColor Yellow
            $null = Checkpoint-Computer -Description $Description -IncludeRegistry:$IncludeRegistry -IncludeDrivers:$IncludeDrivers
            Write-Host "Custom system restore point created."
        }
        "Restore" {
            Write-Host "Restoring system to the most recent restore point..." -ForegroundColor Yellow
            $restorePoint = Get-ComputerRestorePoint | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
            if ($restorePoint) {
                $null = Restore-Computer -RestorePoint $restorePoint
                Write-Host "System restored to the most recent restore point."
            }
            else {
                Write-Host "No restore points available." -ForegroundColor DarkCyan
            }
        }
    }
}
