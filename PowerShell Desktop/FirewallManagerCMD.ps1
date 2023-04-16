#Requires -Version 5.1
Function FirewallManagerCMD {
    <#
    .SYNOPSIS
    Manage Windows Firewall rules.

    .DESCRIPTION
    This PowerShell function is used to manage Windows Firewall rules, it allows you to add, remove, modify, enable or disable a firewall rule.

    .PARAMETER Action
    Mandatory - action to be taken, valid values are declared in validate set.
    .PARAMETER Name
    Mandatory - name of the firewall rule to manage.
    .PARAMETER Description
    Mandatory - specifies the description of the firewall rule.
    .PARAMETER Direction
    Mandatory - direction of the firewall rule, valid values are Inbound or Outbound.
    .PARAMETER Protocol
    Mandatory - the protocol to be used by the firewall rule, valid values are TCP, UDP, ICMPV4, ICMPV6 or Any.
    .PARAMETER LocalPort
    Mandatory - local port to be used by the firewall rule, valid values are integers between 1 and 65535.
    .PARAMETER LocalAddress
    Mandatory - local address to be used by the firewall rule.
    .PARAMETER RemotePort
    Mandatory - the remote port to be used by the firewall rule, valid values are integers between 1 and 65535.
    .PARAMETER RemoteAddress
    Mandatory - the remote address to be used by the firewall rule.
    .PARAMETER Enabled
    NotMandatory - specifies whether the firewall rule is enabled or disabled, valid values are True or False.
    .PARAMETER NewName
    NotMandatory - when renaming, use this parameter to define new rule name.
    .PARAMETER Force
    NotMandatory - specifies whether to force the action or not.

    .EXAMPLE
    FirewallManagerCMD -Action List
    FirewallManagerCMD -Action Show
    FirewallManagerCMD -Action Get -Name "your_rule"
    FirewallManagerCMD -Action Add -Name "your_rule" -Description "ADesc" -Direction Inbound -Protocol TCP -LocalPort 80 -LocalAddress 10.100.10.1 -RemotePort 546 -RemoteAddress 10.100.10.2 -Enabled True -Verbose
    FirewallManagerCMD -Action Remove -Name "your_rule" -Description "ADesc" -Direction Inbound -Protocol TCP -LocalPort 80 -LocalAddress 10.100.10.1 -RemotePort 546 -RemoteAddress 10.100.10.2 -Verbose
    FirewallManagerCMD -Action Modify -Name "your_rule" -Description "ADesc" -Direction Outbound -Protocol UDP -LocalPort 80 -LocalAddress 10.100.10.1 -RemotePort 546 -RemoteAddress 10.100.10.2 -Enabled True -Verbose
    FirewallManagerCMD -Action Enable -Name "your_rule" -Description "ADesc" -Direction Outbound -Protocol TCP -LocalPort 80 -LocalAddress 10.100.10.1 -RemotePort 546 -RemoteAddress 10.100.10.2 -Verbose
    FirewallManagerCMD -Action Disable -Name "your_rule" -Description "ADesc" -Direction Outbound -Protocol TCP -LocalPort 80 -LocalAddress 10.100.10.1 -RemotePort 546 -RemoteAddress 10.100.10.2 -Verbose
    FirewallManagerCMD -Action Rename -Name "old_name" -NewName "new_name"
    FirewallManagerCMD -Action Start
    FirewallManagerCMD -Action Stop

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("List", "Get", "Show", "Add", "Remove", "Modify", "Enable", "Disable", "Rename", "Start", "Stop")]
        [string]$Action,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Inbound", "Outbound")]
        [string]$Direction,

        [Parameter(Mandatory = $false)]
        [ValidateSet("TCP", "UDP", "ICMPV4", "ICMPV6", "Any")]
        [string]$Protocol,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 65535)]
        [int]$LocalPort,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$LocalAddress,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 65535)]
        [int]$RemotePort,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$RemoteAddress,

        [Parameter(Mandatory = $false)]
        [ValidateSet("True", "False")]
        [string]$Enabled,

        [Parameter(Mandatory = $false)]
        [string]$NewName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    if ($Action -eq "List" -or $Action -eq "Show" -or $Action -eq "Start" -or $Action -eq "Stop") {
        Write-Verbose -Message "Listing or showing rules..."
    }
    else {
        $RuleCheck = Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue
    }
    switch ($Action) {
        "Get" {
            return $RuleCheck
        }
        "List" {
            Get-NetFirewallRule | Format-Table -AutoSize
        }
        "Show" {
            Show-NetFirewallRule -PolicyStore ActiveStore | Format-Table -AutoSize
        }
        "Add" {
            if ($RuleCheck -and $Force) {
                Write-Warning -Message "A firewall rule with name '$Name' already exists. Skipping 'Add' action."
            }
            else {
                New-NetFirewallRule -DisplayName $Name -Description $Description `
                    -Direction $Direction -Protocol $Protocol -LocalPort $LocalPort `
                    -LocalAddress $LocalAddress -RemotePort $RemotePort -RemoteAddress $RemoteAddress `
                    -Action Allow -Enabled $Enabled -Verbose
                Write-Verbose -Message "Added firewall rule with name '$Name'."
            }
        }
        "Remove" {
            if ($RuleCheck) {
                Remove-NetFirewallRule -DisplayName $Name -Verbose
                Write-Verbose -Message "Removed firewall rule with name '$Name'."
            }
            else {
                Write-Warning -Message "No firewall rule with name '$Name' found. Skipping 'Remove' action."
            }
        }
        "Modify" {
            if ($RuleCheck) {
                Set-NetFirewallRule -DisplayName $Name -Description $Description -Direction $Direction `
                    -Protocol $Protocol -LocalPort $LocalPort -LocalAddress $LocalAddress -RemotePort $RemotePort `
                    -RemoteAddress $RemoteAddress -Enabled $Enabled -Verbose
                Write-Verbose -Message "Modified firewall rule with name '$Name'."
            }
            else {
                Write-Warning -Message "No firewall rule with name '$Name' found. Skipping 'Modify' action."
            }
        }
        "Enable" {
            if ($RuleCheck) {
                Set-NetFirewallRule -DisplayName $Name -Enabled "True" -Verbose
                Write-Verbose -Message "Enabled firewall rule with name '$Name'."
            }
            else {
                Write-Warning -Message "No firewall rule with name '$Name' found. Skipping 'Enable' action."
            }
        }
        "Disable" {
            if ($RuleCheck) {
                Set-NetFirewallRule -DisplayName $Name -Enabled "False" -Verbose
                Write-Verbose -Message "Disabled firewall rule with name '$Name'."
            }
            else {
                Write-Warning -Message "No firewall rule with name '$Name' found. Skipping 'Disable' action."
            }
        }
        "Rename" {
            $Rules = Get-NetFirewallRule -DisplayName $Name
            foreach ($Rule in $Rules) {
                $CurrentName = $Rule.Name
                Rename-NetFirewallRule -Name $CurrentName -NewName $NewName -Verbose
            }
        }
        "Start" {
            netsh advfirewall set allprofiles state on
            Get-Service -Name mpssvc -Verbose | Start-Service -Verbose -PassThru
        }
        "Stop" {
            netsh advfirewall set allprofiles state off
            ## reg add hklm\system\currentcontrolset\services\mpssvc /t reg_dword /v start /d 4 /f
        }
        default {
            Write-Error "Invalid action. Please use one"
        }
    }
}
