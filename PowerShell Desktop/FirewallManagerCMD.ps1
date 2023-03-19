#Requires -Version 5.1
Function FirewallManagerCMD {
    <#
    .SYNOPSIS
    Manage Windows Firewall rules.

    .DESCRIPTION
    This PowerShell function is used to manage Windows Firewall rules, it allows you to add, remove, modify, enable or disable a firewall rule.

    .PARAMETER Action
    Mandatory - action to be taken, valid values are Add, Remove, Modify, Enable or Disable.
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
    .PARAMETER Force
    NotMandatory - specifies whether to force the action or not.

    .EXAMPLE
    FirewallManagerCMD -Action Add -Name "your_rule" -Description "ADesc" -Direction Inbound -Protocol TCP -LocalPort 80 -LocalAddress 10.100.10.1 -RemotePort 546 -RemoteAddress 10.100.10.2 -Enabled True -Verbose
    FirewallManagerCMD -Action Remove -Name "your_rule" -Description "ADesc" -Direction Inbound -Protocol TCP -LocalPort 80 -LocalAddress 10.100.10.1 -RemotePort 546 -RemoteAddress 10.100.10.2 -Verbose
    FirewallManagerCMD -Action Modify -Name "your_rule" -Description "ADesc" -Direction Outbound -Protocol UDP -LocalPort 80 -LocalAddress 10.100.10.1 -RemotePort 546 -RemoteAddress 10.100.10.2 -Enabled True -Verbose
    FirewallManagerCMD -Action Enable -Name "your_rule" -Description "ADesc" -Direction Outbound -Protocol TCP -LocalPort 80 -LocalAddress 10.100.10.1 -RemotePort 546 -RemoteAddress 10.100.10.2 -Verbose
    FirewallManagerCMD -Action Disable -Name "your_rule" -Description "ADesc" -Direction Outbound -Protocol TCP -LocalPort 80 -LocalAddress 10.100.10.1 -RemotePort 546 -RemoteAddress 10.100.10.2 -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Add", "Remove", "Modify", "Enable", "Disable")]
        [string]$Action,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Description,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Inbound", "Outbound")]
        [string]$Direction,

        [Parameter(Mandatory = $true)]
        [ValidateSet("TCP", "UDP", "ICMPV4", "ICMPV6", "Any")]
        [string]$Protocol,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 65535)]
        [int]$LocalPort,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LocalAddress,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 65535)]
        [int]$RemotePort,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RemoteAddress,

        [Parameter(Mandatory = $false)]
        [ValidateSet("True", "False")]
        [string]$Enabled,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    $RuleCheck = Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue
    switch ($Action) {
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
        default {
            Write-Error "Invalid action. Please use one"
        }
    }
}
