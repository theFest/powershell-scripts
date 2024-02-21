Function Set-RemoteRDPSessionConfig {
    <#
    .SYNOPSIS
    Configures Remote Desktop Protocol (RDP) settings on a local or remote computer.

    .DESCRIPTION
    This function enables, disables, or retrieves the status of Remote Desktop Protocol (RDP) settings on a local or remote computer.

    .PARAMETER Action
    Action to perform, values are "Status", "Enable", or "Disable".
    .PARAMETER ComputerName
    Name of the target computer, defaults to the local computer if not specified.
    .PARAMETER User
    Username to be used for authentication when configuring RDP settings on a remote computer.
    .PARAMETER Pass
    Password corresponding to the provided username for authentication when configuring RDP settings on a remote computer.
    .PARAMETER Restart
    Indicates whether to restart the target computer after performing the specified action.

    .EXAMPLE
    Set-RemoteRDPSessionConfig -Action Status
    Set-RemoteRDPSessionConfig -Action Enable
    Set-RemoteRDPSessionConfig -Action Disable
    Set-RemoteRDPSessionConfig -Action Status -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"
    Set-RemoteRDPSessionConfig -Action Enable -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"
    Set-RemoteRDPSessionConfig -Action Disable -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Status", "Enable", "Disable")]
        [string]$Action,
        
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Pass,

        [Parameter(Mandatory = $false)]
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
            $SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Cred = New-Object System.Management.Automation.PSCredential ($User, $SecPass)
        }
        switch ($Action.ToLower()) {
            "Status" {
                if ($Cred) {
                    $Status = Invoke-Command -ComputerName $ComputerName -Credential $Cred -ScriptBlock {
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
                }
                else {
                    $RDPEnabled = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections").fDenyTSConnections
                    $FirewallRule = Get-NetFirewallRule -DisplayGroup "Remote Desktop" | Select-Object -ExpandProperty Enabled
                    $UserAuthentication = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication").UserAuthentication
                    $SecurityLayer = (Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "SecurityLayer").SecurityLayer
                    $Status = [PSCustomObject]@{
                        "RDPEnabled"          = -not $RDPEnabled
                        "FirewallRuleEnabled" = $FirewallRule
                        "UserAuthentication"  = $UserAuthentication
                        "SecurityLayer"       = $SecurityLayer
                    }
                }
                Write-Output -InputObject $Status
            }
            "Enable" {
                if ($Cred) {
                    Invoke-Command -ComputerName $ComputerName -Credential $Cred -ScriptBlock {
                        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
                        Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
                        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1
                        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "SecurityLayer" -Value 2
                    }
                }
                else {
                    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 0
                    Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
                    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 1
                    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "SecurityLayer" -Value 2
                }
                Write-Host "Remote Desktop Enabled" -ForegroundColor Green
            }
            "Disable" {
                if ($Cred) {
                    Invoke-Command -ComputerName $ComputerName -Credential $Cred -ScriptBlock {
                        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 1
                        Disable-NetFirewallRule -DisplayGroup "Remote Desktop"
                    }
                }
                else {
                    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name "fDenyTSConnections" -Value 1
                    Disable-NetFirewallRule -DisplayGroup "Remote Desktop"
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
