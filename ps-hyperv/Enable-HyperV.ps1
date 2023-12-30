Function Enable-HyperV {
    <#
    .SYNOPSIS
    Enables the Hyper-V feature on the system.
    
    .DESCRIPTION
    This function enables the Microsoft Hyper-V feature on the system if it's not already enabled. It checks for administrative privileges and Hyper-V's current state before attempting to enable it.

    .PARAMETER ForceRestart
    NotMandatory - specifies whether to force a system restart even if it's not pending.

    .EXAMPLE
    Enable-HyperV -ForceRestart

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$ForceRestart
    )
    BEGIN {
        $currentUser = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Warning -Message "Please run this script as an administrator!"
            return
        }
        $isHyperVInstalled = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq "Microsoft-Hyper-V-All" -and $_.State -eq "Enabled" }
        if ($isHyperVInstalled) {
            Write-Host "Hyper-V is already enabled!" -ForegroundColor DarkGreen
            return
        }
    }
    PROCESS {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart -Verbose
        if ((Get-WmiObject -Class Win32_OperatingSystem).RebootPending) {
            Write-Host "A system restart is pending. Restarting the system to apply changes..." -ForegroundColor Gray
            Restart-Computer -Force
        }
        else {
            Write-Host "Hyper-V and its components have been enabled. A system restart might be required for changes to take effect."
        }
    }
    END {
        if ($ForceRestart -and -not (Get-WmiObject -Class Win32_OperatingSystem).RebootPending) {
            Write-Host "ForceRestart parameter specified, but no system restart is pending." -ForegroundColor DarkYellow
        }
    }
}
