#Requires -Version 2.0
Function Remove-CustomPSDrive {
    <#
    .SYNOPSIS
    Removes one or more PowerShell advanced drives by name.

    .DESCRIPTION
    This function removes one or more PowerShell advanced drives by specifying their names, it prompts for confirmation before removing the drives.

    .PARAMETER DriveNames
    Name of the drive or an array of drive names to be removed.
    .PARAMETER Recurse
    Indicates whether to remove the specified drive and all its child drives.
    .PARAMETER Force
    Specifies whether to force removal of the drive without confirmation.

    .EXAMPLE
    Remove-CustomPSDrive -Name "DataDrive", "TestDrive" -Recurse -Force

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$DriveNames,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    BEGIN {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"
    }
    PROCESS {
        foreach ($DriveName in $DriveNames) {
            try {
                $Drive = Get-PSDrive -Name $DriveName -ErrorAction Stop -ErrorVariable driveError
                if ($Drive) {
                    if ($Recurse) {
                        $ConfirmRecursive = Read-Host "Are you sure you want to remove drive '$DriveName' and all its child drives? (Y/N)"
                        if ($ConfirmRecursive -notmatch '^[Yy]$') {
                            Write-Warning -Message "Operation canceled by user for drive '$DriveName' and its child drives."
                            continue
                        }
                        Remove-PSDrive -Name $DriveName -PSProvider $Drive.Provider -Scope Global -Recurse -ErrorAction Stop -Verbose
                        Write-Host "PSDrive '$DriveName' and its child drives removed successfully" -ForegroundColor Green
                    }
                    else {
                        if (-not $Force) {
                            $Confirmation = Read-Host "Are you sure you want to remove drive '$DriveName'? (Y/N)"
                            if ($Confirmation -notmatch '^[Yy]$') {
                                Write-Warning -Message "Operation canceled by user for drive '$DriveName'!"
                                continue
                            }
                        }
                        Remove-PSDrive -Name $DriveName -ErrorAction Stop -Verbose
                        Write-Host "PSDrive '$DriveName' removed successfully" -ForegroundColor Green
                    }
                }
                else {
                    if ($DriveError.Exception.Message -match "Cannot find drive") {
                        Write-Warning -Message "No PSDrive found with the name '$DriveName'!"
                    }
                    else {
                        throw $DriveError.Exception
                    }
                }
            }
            catch {
                Write-Error -Message "Failed to remove PSDrive '$DriveName': $_"
            }
        }
    }
    END {
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
    }
}
