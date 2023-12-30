Function Disable-HyperV {
    <#
    .SYNOPSIS
    Disables the Hyper-V feature on the system.

    .DESCRIPTION
    This function disables the Microsoft Hyper-V feature on the system if it's currently enabled. It verifies administrative privileges and checks if Hyper-V is already disabled before proceeding.

    .PARAMETER ForceRestart
    NotMandatory - specifies whether to force a system restart even if it's not pending.

    .EXAMPLE
    Disable-HyperV -ForceRestart

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$ForceRestart
    )
    BEGIN {
        $CurrentUser = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
        if (-not $CurrentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Warning -Message "Please run this script as an administrator!"
            return
        }
        $isHyperVInstalled = Get-WindowsOptionalFeature -Online | Where-Object { $_.FeatureName -eq "Microsoft-Hyper-V-All" -and $_.State -eq "Enabled" }
        if (-not $isHyperVInstalled) {
            Write-Host "Hyper-V is not enabled!" -ForegroundColor DarkCyan
            return
        }
    }
    PROCESS {
        Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -Verbose
        if ((Get-WmiObject -Class Win32_OperatingSystem).RebootPending) {
            Write-Host "A system restart is pending. Restarting the system to apply changes..."
            Restart-Computer -Force
        }
        else {
            Write-Host "Hyper-V and its components have been disabled. A system restart might be required for changes to take effect"
        }
    }
    END {
        if ($ForceRestart -and -not (Get-WmiObject -Class Win32_OperatingSystem).RebootPending) {
            Write-Host "ForceRestart parameter specified, but no system restart is pending!" -ForegroundColor DarkYellow
        }
    }
}
