function Set-RemoteDesktopConfig {
    <#
    .SYNOPSIS
    Manages Remote Desktop settings on a local or remote computer.

    .DESCRIPTION
    This cmdlet allows you to enable, disable, or check the status of Remote Desktop on a local or remote computer. It can also manage related firewall rules and restart the computer if required.

    .EXAMPLE
    Set-RemoteDesktopConfig -Action Status
    Set-RemoteDesktopConfig -Action Enable
    Set-RemoteDesktopConfig -Action Disable
    Set-RemoteDesktopConfig -Action Status -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"
    Set-RemoteDesktopConfig -Action Enable -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"
    Set-RemoteDesktopConfig -Action Disable -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.4.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Action to perform")]
        [ValidateSet("Status", "Enable", "Disable")]
        [Alias("a")]
        [string]$Action,
        
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, HelpMessage = "Remote computer name, default is the local computer")]
        [Alias("c")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Username for remote authentication")]
        [Alias("u")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for remote authentication")]
        [Alias("p")]
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "Restarts the computer after applying changes")]
        [Alias("r")]
        [switch]$Restart
    )
    BEGIN {
        if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Warning -Message "Please run this script as an Administrator!"
            return
        }
    }
    PROCESS {
        $Cred = $null
        if ($User -and $Pass) {
            try {
                $SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
                $Cred = New-Object System.Management.Automation.PSCredential ($User, $SecPass)
            }
            catch {
                Write-Error -Message "Error converting password to secure string: $_"
                return
            }
        }
        switch ($Action.ToLower()) {
            "status" {
                $ScriptBlock = {
                    $RDPEnabled = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections").fDenyTSConnections
                    $FirewallRule = Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Select-Object -ExpandProperty Enabled
                    $UserAuthentication = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication").UserAuthentication
                    $SecurityLayer = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "SecurityLayer").SecurityLayer
                    [PSCustomObject]@{
                        "RDPEnabled"          = -not $RDPEnabled
                        "FirewallRuleEnabled" = $FirewallRule
                        "UserAuthentication"  = $UserAuthentication
                        "SecurityLayer"       = $SecurityLayer
                    }
                }
                $Status = if ($Cred) {
                    Invoke-Command -ComputerName $ComputerName -Credential $Cred -ScriptBlock $ScriptBlock
                }
                else {
                    & $ScriptBlock
                }
                Write-Output -InputObject $Status
            }
            "enable" {
                $ScriptBlock = {
                    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
                    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
                    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1
                    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "SecurityLayer" -Value 2
                }
                if ($Cred) {
                    Invoke-Command -ComputerName $ComputerName -Credential $Cred -ScriptBlock $ScriptBlock
                }
                else {
                    & $ScriptBlock
                }
                Write-Host "Remote Desktop Enabled" -ForegroundColor Green
            }
            "disable" {
                $ScriptBlock = {
                    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 1
                    Disable-NetFirewallRule -DisplayGroup "Remote Desktop"
                }
                if ($Cred) {
                    Invoke-Command -ComputerName $ComputerName -Credential $Cred -ScriptBlock $ScriptBlock
                }
                else {
                    & $ScriptBlock
                }
                Write-Host "Remote Desktop Disabled" -ForegroundColor DarkYellow
            }
            default {
                Write-Warning -Message "Invalid action specified. Use 'Enable', 'Disable', or 'Status'!"
            }
        }
    }
    END {
        if ($Restart) {
            $RestartConfirmationMessage = "This will restart the computer. Continue?"
            if ($PSCmdlet.ShouldContinue($RestartConfirmationMessage, "Confirm")) {
                Restart-Computer -Force
            }
        }
    }
}
