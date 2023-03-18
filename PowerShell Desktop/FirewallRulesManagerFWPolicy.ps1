Function FirewallRulesManagerFWPolicy {
    <#
    .SYNOPSIS
    Manages firewall rules via Firewall Policy Object.

    .DESCRIPTION
    This function manages firewall rules in Windows Firewall. Firewall rules can be created, modified, or removed using this function.

    .PARAMETER Operate
    NotMandatory - operation for Firewall Rules.
    .PARAMETER Name
    NotMandatory - a name for the firewall rule.
    .PARAMETER Description
    NotMandatory - a description for the firewall rule.
    .PARAMETER ApplicationName
    NotMandatory - the name of the application for which the firewall rule will be created.
    .PARAMETER ServiceName
    NotMandatory - the name of the service for which the firewall rule will be created.
    .PARAMETER Protocol
    NotMandatory - the protocol for the firewall rule. The allowed values are TCP, UDP, ICMPv4, and ICMPv6.
    .PARAMETER LocalPorts
    NotMandatory - the local port number or a comma-separated list of port numbers for the firewall rule.
    .PARAMETER RemotePorts
    NotMandatory - the remote port number or a comma-separated list of port numbers for the firewall rule.
    .PARAMETER LocalAddresses
    NotMandatory - local IP address for the firewall rule.
    .PARAMETER RemoteAddresses
    NotMandatory - a remote IP address for the firewall rule.
    .PARAMETER IcmpTypesAndCodes
    NotMandatory - the ICMP type and code for the firewall rule.
    .PARAMETER Direction
    NotMandatory - the direction of the traffic for the firewall rule. The allowed values are Inbound and Outbound.
    .PARAMETER Interfaces
    NotMandatory - the interface for the firewall rule. The allowed values are Ethernet and Wi-Fi.
    .PARAMETER InterfaceTypes
    NotMandatory - the interface type for the firewall rule. The allowed values are All, Wired, Wireless, RemoteAccess, and VPN.
    .PARAMETER Grouping
    NotMandatory - a grouping for the firewall rule.
    .PARAMETER Profiles
    NotMandatory - the profile for the firewall rule. The allowed values are Domain, Private, and Public.
    .PARAMETER EdgeTraversal
    NotMandatory - whether edge traversal is allowed for the firewall rule.
    .PARAMETER Action
    NotMandatory - the action to be taken for the firewall rule. The allowed values are Allow, Block, and Bypass.
    .PARAMETER EdgeTraversalOptions
    NotMandatory - the edge traversal options for the firewall rule. The allowed values are None, Allow, and Block.
    .PARAMETER LocalAppPackageId
    NotMandatory - the package ID of a Windows Store app.
    .PARAMETER LocalUserOwner
    NotMandatory - the name of a local user account.
    .PARAMETER LocalUserAuthorizedList
    NotMandatory - a list of local user accounts that are authorized to access the firewall rule.
    .PARAMETER SecureFlags
    NotMandatory - the secure flags for the firewall rule.
    .PARAMETER Enable
    NotMandatory - enables the firewall rule.
    .PARAMETER Disable
    NotMandatory - disables the firewall rule.
    .PARAMETER Remove
    NotMandatory - removes the firewall rule.
    .PARAMETER CheckForDuplicates
    NotMandatory - clears any duplicate firewall rules.

    .EXAMPLE
    FirewallRulesManager -CheckForDuplicates -Verbose
    FirewallRulesManager -Operate Add -Name "AAAabc" -Description "AAAabc" -ApplicationName "C:\temp\myapp.exe" -Action Allow -Direction Inbound -Protocol TCP `
    -LocalPort "80" -RemotePort '2334' -LocalAddress "192.168.100.5", "192.168.100.2" -RemoteAddress "192.168.100.3", "192.168.100.2" -Enable -Verbose -Force

    .NOTES
    v0.0.8
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, HelpMessage = "Choose operation from validate set")]
        [ValidateSet("Add", "Remove", "Modify", "Enable", "Disable")]
        [string]$Operate,

        [Parameter(Mandatory = $false, HelpMessage = "Enter a name for the firewall rule")]
        [string]$Name,

        [Parameter(Mandatory = $false, HelpMessage = "Enter a description for the firewall rule")]
        [string]$Description = "",

        [Parameter(Mandatory = $false, HelpMessage = "Select the action to be taken for the firewall rule")]
        [ValidateSet("Allow", "Block", "Bypass")]
        [string]$Action,

        [Parameter(Mandatory = $false, HelpMessage = "Enter the name of the application for which the firewall rule will be created")]
        [string]$ApplicationName,

        [Parameter(Mandatory = $false, HelpMessage = "Enter the name of the service for which the firewall rule will be created")]
        [string]$ServiceName,

        [Parameter(Mandatory = $false, HelpMessage = "Select the protocol for the firewall rule")]
        [ValidateSet("TCP", "UDP", "ICMPv4", "ICMPv6", "Any")]
        [string]$Protocol,

        [Parameter(Mandatory = $false, HelpMessage = "Enter a local port number or a comma-separated list of port numbers for the firewall rule")]
        [ValidateRange(1, 65535)]
        [string]$LocalPort,

        [Parameter(Mandatory = $false, HelpMessage = "Enter a remote port number or a comma-separated list of port numbers for the firewall rule")]
        [ValidateRange(1, 65535)]
        [string[]]$RemotePort,

        [Parameter(Mandatory = $false, HelpMessage = "Enter a local IP address for the firewall rule")]
        [ipaddress[]]$LocalAddress,

        [Parameter(Mandatory = $false, HelpMessage = "Enter a remote IP address for the firewall rule")]
        [ipaddress[]]$RemoteAddress,

        [Parameter(Mandatory = $false, HelpMessage = "Enter the ICMP type and code for the firewall rule")]
        [string]$IcmpTypesAndCodes,

        [Parameter(Mandatory = $false, HelpMessage = "Select the direction of the traffic for the firewall rule")]
        [ValidateSet("Inbound", "Outbound")]
        [string]$Direction,

        [Parameter(Mandatory = $false, HelpMessage = "Select the interface for the firewall rule")]
        [ValidateSet("Ethernet", "Wi-Fi")]
        [string]$Interface = "Ethernet",

        [Parameter(Mandatory = $false, HelpMessage = "Select the interface type for the firewall rule")]
        [ValidateSet("Any", "Ethernet", "Wireless", "RemoteAccess", "VPN")]
        [string]$InterfaceType,

        [Parameter(Mandatory = $false, HelpMessage = "Enter a grouping for the firewall rule")]
        [string]$Group,

        [Parameter(Mandatory = $false, HelpMessage = "Select the profile for the firewall rule")]
        [ValidateSet("Any", "Private", "Public", "Domain")]
        [string]$Profile,

        [Parameter(Mandatory = $false, HelpMessage = "Select whether edge traversal is allowed for the firewall rule")]
        [bool]$EdgeTraversal = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Select the edge traversal options for the firewall rule")]
        [ValidateSet("NotConfigured", "Block", "Allow")]
        [string]$EdgeTraversalOptions = "NotConfigured",

        [Parameter(Mandatory = $false, HelpMessage = "Enter the package ID of a Windows Store app")]
        [string]$LocalAppPackageId,

        [Parameter(Mandatory = $false, HelpMessage = "The name of a local user account")]
        [ValidateSet("Any", "CurrentUser", "AllUsers")]
        [string]$LocalUserOwner,

        [Parameter(Mandatory = $false, HelpMessage = "Comma separated LocalUser Authorized List")]
        [string]$LocalUserAuthorizedList,

        [Parameter(Mandatory = $false, HelpMessage = "Switch to clear duplicate entries firewall rule names")]
        [switch]$Enable,

        [Parameter(Mandatory = $false, HelpMessage = "Switch to clear duplicate entries firewall rule names")]
        [switch]$Force,

        [Parameter(Mandatory = $false, HelpMessage = "Switch to clear duplicate entries firewall rule names")]
        [switch]$CheckForDuplicates
    )
    BEGIN {
        Write-Verbose -Message "Starting, csv to import..."
    }
    PROCESS {
        $FirewallPolicy = New-Object -ComObject HNetCfg.FwPolicy2
        $FirewallRule = New-Object -ComObject HNetCfg.FWRule
        switch ($Operate) {
            "Add" {
                if ($Force) {
                    $FirewallRule = New-Object -ComObject HNetCfg.FWRule
                    $FirewallRule.Name = $Name
                    $FirewallRule.Enabled = $Enable.IsPresent
                    $FirewallRule.Action = @{ Allow = 1; Block = 0 }[$Action]
                    $FirewallRule.Description = $Description
                    $FirewallRule.ApplicationName = $ApplicationName
                    $FirewallRule.Direction = @{ Inbound = 1; Outbound = 2 }[$Direction]
                    $FirewallRule.Protocol = @{ Any = 256; TCP = 6; UDP = 17; ICMPv4 = 1; ICMPv6 = 58 }[$Protocol]
                    if ($Group) {
                        $FirewallRule.Grouping = "@firewallapi.dll,-23255" #$Group
                    }
                    if ($ServiceName) {
                        $FirewallRule.ServiceName = $ServiceName
                    }
                    if ($LocalAddress) {
                        $LocalAddressesArray = $LocalAddress -join ','
                        $FirewallRule.LocalAddresses = $LocalAddressesArray
                    }
                    if ($LocalPort) {
                        $LocalPortsArray = $LocalPorts -join ','
                        $FirewallRule.LocalPorts = $LocalPortsArray
                    }
                    if ($RemoteAddress) {
                        $RemoteAddresses = $RemoteAddress -join ','
                        $FirewallRule.RemoteAddresses = $RemoteAddresses
                    }
                    if ($RemotePort) {
                        $RemotePortArray = $RemotePort -join ','
                        $FirewallRule.RemotePorts = $RemotePortArray
                    }
                    if ($IcmpTypesAndCodes) {
                        $FirewallRule.IcmpTypesAndCodes = $IcmpTypesAndCodes
                    }
                    if ($Profile) {
                        $FirewallRule.Profiles = @{ Any = 0; Domain = 1; Private = 2; Public = 4 }[$Profile]
                    }
                    if ($Interfaces -or $InterfaceTypes) {
                        $FirewallRule.Interfaces = $Interface
                        $FirewallRule.InterfaceTypes = @{ All = 0; Ethernet = 1; Wireless = 71 }[$InterfaceType]
                    }
                    if ($EdgeTraversal -or $EdgeTraversalOptions) {
                        $FirewallRule.EdgeTraversal = $EdgeTraversal
                        $FirewallRule.EdgeTraversalOptions = @{ NotConfigured = 0; Block = 1; Allow = 2 }[$EdgeTraversalOptions]
                    }
                    if ($LocalAppPackageId) {
                        $FirewallRule.LocalAppPackageId = $LocalAppPackageId
                    }
                    if ($LocalUserOwner) {
                        $FirewallRule.LocalUserOwner = @{
                            Any         = "S-1-1-0"
                            CurrentUser = "S-1-5-32-545"
                            AllUsers    = "S-1-5-32-544"
                        }[$LocalUserOwner]
                    }
                    if ($LocalUserAuthorizedList) {
                        $FirewallRule.LocalUserAuthorizedList = $LocalUserAuthorizedList
                    }
                    if ($ClearDuplicates) {
                        #$FirewallPolicy.Rules.Remove($NewRule.Name)
                    }
                    try {
                        $FirewallPolicy = New-Object -ComObject HNetCfg.FwPolicy2
                        $FirewallPolicy.Rules.Add($FirewallRule)
                        Write-Verbose -Message "Created firewall rule: $($FirewallRule.Name)"
                    }
                    catch [System.Exception] {
                        Write-Error "Failed to add firewall rule: $($_.Exception.Message)"
                    }
                }
                else {
                    Write-Verbose -Message "Firewall rule already exists: $($ExistingRule.Name)"
                }
            }
            "Remove" {
                $RemRule = New-Object -ComObject HNetCfg.FWRule
                $RulePolObj.Rules.Item($RemRule.Name)
            }
            "Modify" {
                $ModRule = New-Object -ComObject HNetCfg.FWRule
                $ModRule.Description = $Description
                $ModRule.Direction = $Direction
                $ModRule.Protocol = $Protocol
                $ModRule.LocalPorts = $LocalPort
                $ModRule.LocalAddresses = $LocalAddress
                $ModRule.RemotePorts = $RemotePort
                $ModRule.RemoteAddresses = $RemoteAddress
                $ModRule.Enabled = $Enabled
                $RulePolObj.Rules.Item($ModRule.Name)
            }
            "Update" {
                Write-Verbose -Message "Updating existing rule: $($ExistingRule.Name)"
                $ExistingRule.Description = $Description
                $ExistingRule.ApplicationName = $ApplicationPath
                $ExistingRule.Protocol = $Protocol
                $ExistingRule.LocalPorts = $LocalPorts
                $ExistingRule.Enabled = $Enabled
                $FirewallPolicy.Rules.Item($ExistingRule.Name).Put($ExistingRule)
            }
            "Enable" {
                $FwRuleDefine.Enabled = $true
            }
            "Disable" {
                $FwRuleDefine.Enabled = $false
            }
        }
        if ($CSVFilePath) {
            Import-Csv -Path $CSVFilePath | ForEach-Object {
                $params = @{
                    Operate       = $_.Operate
                    RuleName      = $_.Name
                    Description   = $_.Description
                    Direction     = $_.fwDirection
                    Protocol      = $_.Protocol
                    LocalPort     = $_.LocalPort
                    LocalAddress  = $_.LocalAddress
                    RemotePort    = $_.RemotePort
                    RemoteAddress = $_.RemoteAddress
                    Enabled       = $_.Enabled
                }
                ManageFirewallRule @params
            }
        }
    }
    END {
        Write-Verbose -Message "Verification of duplicates, then ending..."
        if ($CheckForDuplicates) {
            $RemoveDuplicates = {
                $Output = (netsh advfirewall firewall show rule name=all verbose | Out-String).Trim() -split '\r?\n\s*\r?\n'
                $PropertyNames = [System.Collections.Generic.List[string]]::new()
                $Objects = @(foreach ($Section in $Output) {
                        $Obj = @{}
                        foreach ($Line in ($Section -split '\r?\n')) {
                            if ($Line -match '^\-+$') { continue }
                            $Name, $Value = $Line -split ':\s*', 2
                            $Name = $Name -replace " ", ""
                            $Obj.$Name = $Value
                            if ($PropertyNames -notcontains $Name) {
                                $PropertyNames.Add($Name)
                            }
                        }
                        [PSCustomObject]$Obj
                    }) | ForEach-Object {
                    foreach ($Prop in $PropertyNames) {
                        if ($_.PSObject.Properties.Name -notcontains $Prop) {
                            $_ | Add-Member -MemberType NoteProperty -Name $Prop -Value $null
                        }
                    }
                    $_
                }
                $Rules = $Objects | Group-Object -Property RuleName, Program, Action, Profiles, RemoteIP, RemotePort, LocalIP, LocalPort, Enabled, Protocol, Direction
                Write-Verbose -Message "Searching and removing duplicates..."
                $Rules | Where-Object { $_.Count -gt 1 } | ForEach-Object {
                    $Name = $_ | Select-Object -ExpandProperty Group | Select-Object -ExpandProperty RuleName -First 1
                    Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue | Select-Object -Skip 1 | Remove-NetFirewallRule -Verbose
                }
            }
            Invoke-Command -ScriptBlock $RemoveDuplicates ; return
        }
    }
}
