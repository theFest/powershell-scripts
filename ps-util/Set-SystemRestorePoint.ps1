Function Set-SystemRestorePoint {
    <#
    .SYNOPSIS
    Manage system restore points on a Windows computer.

    .DESCRIPTION
    This function provides an easy way to create, customize, and restore system restore points on a Windows computer.

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
    .PARAMETER TargetDrive
    NotMandatory - specifies the target drive where the restore point should be created. Only used when Action is "Create" or "Save".

    .EXAMPLE
    Set-SystemRestorePoint -Action List -Verbose
    Set-SystemRestorePoint -Action Create -Description "Before software installation"
    Set-SystemRestorePoint -Action Remove -Description "Unwanted Restore Point"

    .NOTES
    v0.0.6
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
        [string]$BackupPath,

        [Parameter(Mandatory = $false)]
        [string]$TargetDrive
    )
    switch ($Action) {
        "Create" {
            Write-Verbose -Message "Creating a new system restore point..."
            $null = Checkpoint-Computer -Description $Description -TargetPath $TargetDrive
            Write-Host "System restore point created" -ForegroundColor Green
        }
        "Save" {
            Write-Verbose -Message "Creating a custom system restore point..."
            $null = Checkpoint-Computer -Description $Description -IncludeRegistry:$IncludeRegistry -IncludeDrivers:$IncludeDrivers -CustomName $CustomName -BackupPath $BackupPath -TargetPath $TargetDrive
            Write-Host "Custom system restore point created" -ForegroundColor Green
        }
        "Restore" {
            Write-Verbose -Message "Restoring system to the most recent restore point..."
            $RestorePoint = Get-ComputerRestorePoint | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
            if ($RestorePoint) {
                $null = Restore-Computer -RestorePoint $RestorePoint
                Write-Host "System restored to the most recent restore point" -ForegroundColor Green
            }
            else {
                Write-Warning -Message "No restore points available!"
            }
        }
        "List" {
            Write-Verbose -Message "Listing available restore points..."
            Get-ComputerRestorePoint | Format-Table -AutoSize
        }
        "Remove" {
            Write-Verbose -Message "Removing specified restore points..."
            $RestorePoints = Get-ComputerRestorePoint | Where-Object { $_.Description -eq $Description }
            if ($RestorePoints) {
                $RestorePoints | ForEach-Object {
                    Write-Host "Removing restore point: $($_.Description)" -ForegroundColor DarkCyan
                    Disable-ComputerRestore -RestorePoint $_
                }
                Write-Host "Specified restore points removed." -ForegroundColor Green
            }
            else {
                Write-Warning -Message "No matching restore points found!"
            }
        }
    }
}
