Function Get-PendingRebootStatus {
    <#
    .SYNOPSIS
    Checks whether a system or remote computer requires a reboot due to pending updates or file rename operations.

    .DESCRIPTION
    This function checks for pending reboots on the local system or a remote computer. It examines the Windows registry keys associated with Windows Update and pending file rename operations.

    .PARAMETER Computername
    Name of the remote computer to check, if not provided, the function checks the local system.
    .PARAMETER User
    Username for authenticating to the remote computer, required for remote checks.
    .PARAMETER Pass
    Password for authenticating to the remote computer, required for remote checks.

    .EXAMPLE
    Get-PendingRebootStatus
    Get-PendingRebootStatus -Computername "RemoteComputer" -User "Username" -Pass "Password"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Computername,

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Pass
    )
    $PendingRebootRegistryKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
    $PendingFileRenameRegistryKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations"
    if (-not $Computername) {
        $IsPendingReboot = Test-Path -Path $PendingRebootRegistryKey
        $IsPendingFileRename = Test-Path -Path $PendingFileRenameRegistryKey
    }
    else {
        $IsPendingReboot = Invoke-Command -ComputerName $Computername -Credential (New-Object PSCredential -ArgumentList $User, (ConvertTo-SecureString $Pass -AsPlainText -Force)) -ScriptBlock {
            Test-Path -Path $using:PendingRebootRegistryKey
        }
        $IsPendingFileRename = Invoke-Command -ComputerName $Computername -Credential (New-Object PSCredential -ArgumentList $User, (ConvertTo-SecureString $Pass -AsPlainText -Force)) -ScriptBlock {
            Test-Path -Path $using:PendingFileRenameRegistryKey
        }
    }
    $RebootStatus = @{
        "IsPendingReboot"     = $IsPendingReboot
        "IsPendingFileRename" = $IsPendingFileRename
        "PendingRebootReason" = $null
    }
    if ($IsPendingReboot) {
        if (-not $Computername) {
            $RebootReason = (Get-ItemProperty -LiteralPath $PendingRebootRegistryKey -Name "RebootRequired").RebootRequiredReason
        }
        else {
            $RebootReason = Invoke-Command -ComputerName $Computername -Credential (New-Object PSCredential -ArgumentList $User, (ConvertTo-SecureString $Pass -AsPlainText -Force)) -ScriptBlock {
                (Get-ItemProperty -LiteralPath $using:PendingRebootRegistryKey -Name "RebootRequired").RebootRequiredReason
            }
        }
        $RebootStatus["PendingRebootReason"] = $RebootReason
    }
    if ($RebootStatus["IsPendingReboot"] -or $RebootStatus["IsPendingFileRename"]) {
        if ($Computername) {
            Write-Host "$Computername requires a reboot" -ForegroundColor Yellow
        }
        else {
            Write-Host "Local system requires a reboot!" -ForegroundColor DarkYellow
        }
        if ($RebootStatus["IsPendingReboot"]) {
            Write-Host "Reason for pending reboot: $($RebootStatus['PendingRebootReason'])" -ForegroundColor Cyan
        }
        if ($RebootStatus["IsPendingFileRename"]) {
            Write-Host "Pending file rename operations detected!" -ForegroundColor DarkGray
        }
    }
    else {
        if ($Computername) {
            Write-Host "$Computername has no pending reboot or file rename operations" -ForegroundColor Green
        }
        else {
            Write-Host "Local system has no pending reboot or file rename operations" -ForegroundColor DarkGreen
        }
    }
    return $RebootStatus
}
