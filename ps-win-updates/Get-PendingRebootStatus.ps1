function Get-PendingRebootStatus {
    <#
    .SYNOPSIS
    Checks whether a local or remote system requires a reboot due to pending updates, file rename operations, or other conditions.

    .DESCRIPTION
    This function checks for pending reboots on the local or a remote system by examining various Windows registry keys that indicate if a reboot is required.
    These keys include pending file rename operations, Windows Update reboot requirements, Component-Based Servicing (CBS), and others. It can be run on a remote computer by specifying a username and password for authentication.

    .EXAMPLE
    Get-PendingRebootStatus
    Get-PendingRebootStatus -ComputerName "RemotePC" -User "AdminUser" -Pass "password123"

    .NOTES
    v0.1.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Name of the remote computer to check, if not provided, the function checks the local system")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, HelpMessage = "Username for authenticating to the remote computer, required for remote checks")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for authenticating to the remote computer, required for remote checks")]
        [string]$Pass
    )
    $PendingRebootKeys = @{
        "WindowsUpdate"        = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
        "FileRenameOperations" = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations"
        "CBSReboot"            = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending"
        "ComputerRename"       = "HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName"
    }
    $Cred = $null
    if ($ComputerName) {
        if (-not $User -or -not $Pass) {
            Write-Error -Message "Username and password are required for remote checks!"
            return
        }
        $SecPass = ConvertTo-SecureString $Pass -AsPlainText -Force
        $Cred = New-Object System.Management.Automation.PSCredential ($User, $SecPass)
    }
    $CheckKey = {
        param($Key)
        Test-Path -Path $Key
    }
    $RebootStatus = @{
        IsPendingReboot         = $false
        IsPendingFileRename     = $false
        IsPendingCBS            = $false
        IsPendingComputerRename = $false
        RebootReasons           = @()
    }
    foreach ($Key in $PendingRebootKeys.GetEnumerator()) {
        $KeyName = $Key.Key
        $RegPath = $Key.Value
        $Result = if ($ComputerName) {
            Invoke-Command -ComputerName $ComputerName -Credential $Cred -ScriptBlock $CheckKey -ArgumentList $RegPath -ErrorAction SilentlyContinue
        }
        else {
            & $CheckKey $RegPath
        }
        if ($Result) {
            switch ($KeyName) {
                "WindowsUpdate" {
                    $RebootStatus.IsPendingReboot = $true
                    $RebootStatus.RebootReasons += "Windows Update requires reboot"
                }
                "FileRenameOperations" {
                    $RebootStatus.IsPendingFileRename = $true
                    $RebootStatus.RebootReasons += "Pending file rename operations"
                }
                "CBSReboot" {
                    $RebootStatus.IsPendingCBS = $true
                    $RebootStatus.RebootReasons += "Component-Based Servicing (CBS) requires reboot"
                }
                "ComputerRename" {
                    $RebootStatus.IsPendingComputerRename = $true
                    $RebootStatus.RebootReasons += "Computer name change requires reboot"
                }
            }
        }
    }
    if ($RebootStatus.IsPendingReboot -or $RebootStatus.IsPendingFileRename -or $RebootStatus.IsPendingCBS -or $RebootStatus.IsPendingComputerRename) {
        if ($ComputerName) {
            Write-Host "$ComputerName requires a reboot" -ForegroundColor Yellow
        }
        else {
            Write-Host "Local system requires a reboot!" -ForegroundColor DarkYellow
        }
        foreach ($Reason in $RebootStatus.RebootReasons) {
            Write-Host "Reason: $Reason" -ForegroundColor Cyan
        }
    }
    else {
        if ($ComputerName) {
            Write-Host "$ComputerName has no pending reboot operations" -ForegroundColor Green
        }
        else {
            Write-Host "Local system has no pending reboot operations" -ForegroundColor DarkGreen
        }
    }
    return $RebootStatus
}
