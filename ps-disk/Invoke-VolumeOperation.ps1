Function Invoke-VolumeOperation {
    <#
    .SYNOPSIS
    Repairs, optimizes, and performs additional operations on a volume.

    .DESCRIPTION
    This function performs various operations like repair, optimization, defragmentation, file system check, or analysis on a volume specified by the drive letter.

    .PARAMETER DriveLetter
    Mandatory - the drive letter of the volume to repair and optimize.
    .PARAMETER Operation
    Mandatory - operation to perform (Repair, Optimize, Analyze, Defrag, CheckFileSystem).
    .PARAMETER Summary
    NotMandatory - displays a summary of the performed operations at the end.
    .PARAMETER Force
    NotMandatory - forces the operation without prompting for confirmation.

    .EXAMPLE
    Invoke-VolumeOperation -DriveLetter "C" -Operation "Repair"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[A-Za-z]$')]
        [string]$DriveLetter,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Repair", "Optimize", "Analyze", "Defrag", "CheckFileSystem")]
        [string]$Operation,

        [Parameter(Mandatory = $false)]
        [switch]$Summary,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    BEGIN {
        $OperationsPerformed = @()
    }
    PROCESS {
        try {
            switch ($Operation) {
                "Repair" {
                    Repair-Volume -DriveLetter $DriveLetter -Verbose -Force:$Force
                    $OperationsPerformed += "Volume repaired"
                }
                "Optimize" {
                    Optimize-Volume -DriveLetter $DriveLetter -Verbose -Force:$Force
                    $OperationsPerformed += "Volume optimized"
                }
                "Analyze" {
                    Optimize-Volume -DriveLetter $DriveLetter -Analyze -Verbose -Force:$Force
                    $OperationsPerformed += "Volume analyzed"
                }
                "Defrag" {
                    Defrag-Volume -DriveLetter $DriveLetter -Verbose -Force:$Force
                    $OperationsPerformed += "Volume defragmented"
                }
                "CheckFileSystem" {
                    Repair-Volume -DriveLetter $DriveLetter -Check -Verbose -Force:$Force
                    $OperationsPerformed += "File system checked"
                }
                default {
                    Write-Error -Message "Invalid operation selected!"
                }
            }
        }
        catch {
            Write-Error -Message "Error occurred during the operation: $_"
        }
    }
    END {
        try {
            if ($Summary) {
                Write-Output "Operations Summary:"$OperationsPerformed | ForEach-Object { Write-Output "- $_" }
            }
        }
        catch {
            Write-Error -Message "Error during cleanup: $_"
        }
        finally {
            Write-Host "Operation completed, exiting!" -ForegroundColor DarkCyan
        }
    }
}
