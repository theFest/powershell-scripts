Function ManageRestorePoint {
    <#
    .SYNOPSIS
    Manage system restore points on a Windows computer.

    .DESCRIPTION
    This function provides an easy way to create, customize, and restore system restore points on a Windows computer.
    System restore points are snapshots of your system's state that can be used to restore your computer to a previous state if issues arise.

    .PARAMETER Action
    Specifies the action to perform. Valid values are "Create", "Save", "Restore", "List", and "Remove".
    - Create: Creates a new system restore point.
    - Save: Creates a custom system restore point with additional options.
    - Restore: Restores the system to the most recent restore point.
    - List: Lists available restore points.
    - Remove: Removes specific restore points.

    .PARAMETER Description
    Mandatory - description for the restore point. Only used when Action is "Create" or "Save".
    .PARAMETER IncludeRegistry
    NotMandatory - includes the system registry in the restore point. Only used when Action is "Save".
    .PARAMETER IncludeDrivers
    NotMandatory - includes drivers in the restore point. Only used when Action is "Save".
    .PARAMETER CustomName
    NotMandatory - provides a custom name for the restore point. Only used when Action is "Save".
    .PARAMETER BackupPath
    NotMandatory - specifies a custom backup path for the restore point. Only used when Action is "Save".

    .EXAMPLE
    ManageRestorePoint -Action Create -Description "Before software installation"
    ManageRestorePoint -Action List
    ManageRestorePoint -Action Remove -Description "Unwanted Restore Point"

    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Create", "Save", "Restore", "List", "Remove")]
        [string]$Action,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeRegistry,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDrivers,

        [Parameter(Mandatory = $false)]
        [string]$CustomName,

        [Parameter(Mandatory = $false)]
        [string]$BackupPath
    )
    switch ($Action) {
        "Create" {
            Write-Host "Creating a new system restore point..."
            $null = Checkpoint-Computer -Description $Description
            Write-Host "System restore point created." -ForegroundColor Green
        }
        "Save" {
            Write-Host "Creating a custom system restore point..." -ForegroundColor Yellow
            $null = Checkpoint-Computer -Description $Description -IncludeRegistry:$IncludeRegistry -IncludeDrivers:$IncludeDrivers -CustomName $CustomName -BackupPath $BackupPath
            Write-Host "Custom system restore point created."
        }
        "Restore" {
            Write-Host "Restoring system to the most recent restore point..." -ForegroundColor Yellow
            $RestorePoint = Get-ComputerRestorePoint | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
            if ($RestorePoint) {
                $null = Restore-Computer -RestorePoint $RestorePoint
                Write-Host "System restored to the most recent restore point."
            }
            else {
                Write-Host "No restore points available." -ForegroundColor DarkCyan
            }
        }
        "List" {
            Write-Host "Listing available restore points..." -ForegroundColor Yellow
            Get-ComputerRestorePoint | Format-Table -AutoSize
        }
        "Remove" {
            Write-Host "Removing specified restore points..." -ForegroundColor Yellow
            $RestorePoints = Get-ComputerRestorePoint | Where-Object { $_.Description -eq $Description }
            if ($RestorePoints) {
                $RestorePoints | ForEach-Object {
                    Write-Host "Removing restore point: $($_.Description)" -ForegroundColor Yellow
                    Disable-ComputerRestore -RestorePoint $_
                }
                Write-Host "Specified restore points removed." -ForegroundColor Green
            }
            else {
                Write-Host "No matching restore points found." -ForegroundColor DarkCyan
            }
        }
    }
}
