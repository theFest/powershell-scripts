Function Set-DriveLetter {
    <#
    .SYNOPSIS
    Changes the drive letter of a volume using multiple methods.

    .DESCRIPTION
    This function changes the drive letter of a volume to the specified new drive letter using multiple methods, including DiskPart and updating the registry.

    .PARAMETER DriveLetter
    Mandatory - the current drive letter of the volume to change.
    .PARAMETER NewDriveLetter
    Mandatory - the new drive letter to set for the volume.
    .PARAMETER RestartComputer
    NotMandatory - restarts the computer after applying the changes.

    .EXAMPLE
    Set-DriveLetter -DriveLetter "D" -NewDriveLetter "G" -RestartComputer

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern('^[A-Za-z]$')]
        [string]$DriveLetter,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^[A-Za-z]$')]
        [string]$NewDriveLetter,

        [Parameter(Mandatory = $false)]
        [switch]$RestartComputer
    )
    BEGIN {
        Write-Host "Current drive letter > $DriveLetter" -ForegroundColor DarkCyan
    }
    PROCESS {
        $DiskpartScript = @"
select volume $DriveLetter
assign letter=$NewDriveLetter
"@
        $DiskpartScript | Out-File -FilePath "$env:USERPROFILE\Desktop\cdl.txt" -Encoding ASCII
        Start-Process -FilePath "diskpart.exe" -ArgumentList "/s $env:USERPROFILE\Desktop\cdl.txt" -Wait -WindowStyle Hidden
        $RegistryPath = "HKLM:\SYSTEM\MountedDevices"
        $OldRegistryKey = "${DriveLetter}:"
        $NewRegistryKey = "${NewDriveLetter}:"
        Set-ItemProperty -Path $RegistryPath -Name $OldRegistryKey -Value $NewRegistryKey -Verbose
        $TaskAction = New-ScheduledTaskAction -Execute 'cmd.exe' -Argument "/c start powershell.exe -NoProfile -ExecutionPolicy Bypass -Command \`"Get-Partition -DiskNumber 1 -PartitionNumber 2 | Set-Partition -NewDriveLetter $NewDriveLetter\`""
        $TaskTrigger = New-ScheduledTaskTrigger -AtStartup
        $TaskTriggerId = "ChangeDriveLetterTask"
        $Task = Register-ScheduledTask -Action $TaskAction -Trigger $TaskTrigger -TaskName $TaskTriggerId -Force
        if ($Task) {
            Write-Host "Drive letter changed using multiple methods" -ForegroundColor Green
        }
        else {
            Write-Warning -Message "Failed to create the scheduled task"
        }
    }
    END {
        if ($RestartComputer) {
            $Confirmation = Read-Host "Do you want to restart the computer now? (Y/N)"
            if ($Confirmation -eq "Y" -or $Confirmation -eq "y") {
                Restart-Computer -Force
            }
            else {
                Write-Warning -Message "Restart cancelled" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "Restart the computer for the drive letter change to take effect" -ForegroundColor Yellow
        }
    }
}
