Function FirewallRulesManager {
    <#
    .SYNOPSIS
    Manages firewall rules.

    .DESCRIPTION
    This function manages firewall rules in Windows Firewall. Firewall rules can be created, modified, or removed using this function.

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
    .PARAMETER ClearDuplicates
    NotMandatory - clears any duplicate firewall rules.

    .EXAMPLE
    FirewallRulesManager -ClearDuplicates -Verbose
    ManageFirewallRule -Direction Inbound -Name "your_app_rule" -ApplicationName "C:\your_app.exe" -Protocol TCP -LocalPorts 80 -Action Allow -Enable

    .NOTES
    v0.0.7
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, HelpMessage = "Enter a name for the firewall rule")]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $false, HelpMessage = "Enter a description for the firewall rule")]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [Parameter(Mandatory = $false, HelpMessage = "Enter the name of the application for which the firewall rule will be created")]
        [string]$ApplicationName,

        [Parameter(Mandatory = $false, HelpMessage = "Enter the name of the service for which the firewall rule will be created")]
        [string]$ServiceName,

        [Parameter(Mandatory = $false, HelpMessage = "Select the protocol for the firewall rule")]
        [ValidateSet("TCP", "UDP", "ICMPv4", "ICMPv6")]
        [string]$Protocol,

        [Parameter(Mandatory = $false, HelpMessage = "Enter a local port number or a comma-separated list of port numbers for the firewall rule")]
        [ValidateRange(1, 65535)]
        [int]$LocalPorts,

        [Parameter(Mandatory = $false, HelpMessage = "Enter a remote port number or a comma-separated list of port numbers for the firewall rule")]
        [ValidateRange(1, 65535)]
        [int]$RemotePorts,

        [Parameter(Mandatory = $false, HelpMessage = "Enter a local IP address for the firewall rule")]
        [ValidatePattern('^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')]
        [string]$LocalAddresses, #ipaddress

        [Parameter(Mandatory = $false, HelpMessage = "Enter a remote IP address for the firewall rule")]
        [ValidatePattern('^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$')]
        [string]$RemoteAddresses, #ipaddress

        [Parameter(Mandatory = $false, HelpMessage = "Enter the ICMP type and code for the firewall rule")]
        [string]$IcmpTypesAndCodes,

        [Parameter(Mandatory = $false, HelpMessage = "Select the direction of the traffic for the firewall rule")]
        [ValidateSet("Inbound", "Outbound")]
        [string]$Direction,

        [Parameter(Mandatory = $false, HelpMessage = "Select the interface for the firewall rule")]
        [ValidateSet("Ethernet", "Wi-Fi")]
        [string]$Interfaces = "Ethernet",

        [Parameter(Mandatory = $false, HelpMessage = "Select the interface type for the firewall rule")]
        [ValidateSet("All", "Wired", "Wireless", "RemoteAccess", "VPN")]
        [string]$InterfaceTypes = "All",

        [Parameter(Mandatory = $false, HelpMessage = "Enter a grouping for the firewall rule")]
        [string]$Grouping,

        [Parameter(Mandatory = $false, HelpMessage = "Select the profile for the firewall rule")]
        [ValidateSet("Domain", "Private", "Public")]
        [string]$Profiles = "Private",

        [Parameter(Mandatory = $false, HelpMessage = "Select whether edge traversal is allowed for the firewall rule")]
        [bool]$EdgeTraversal = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Select the action to be taken for the firewall rule")]
        [ValidateSet("Allow", "Block", "Bypass")]
        [string]$Action = "Allow",

        [Parameter(Mandatory = $false, HelpMessage = "Select the edge traversal options for the firewall rule")]
        [ValidateSet("None", "Allow", "Block")]
        [string]$EdgeTraversalOptions = "Allow",

        [Parameter(Mandatory = $false, HelpMessage = "Enter the package ID of a Windows Store app")]
        [string]$LocalAppPackageId,

        [Parameter(Mandatory = $false, HelpMessage = "The name of a local user account")]
        [string]$LocalUserOwner,

        [Parameter(Mandatory = $false, HelpMessage = "Enter the package ID of a Windows Store app")]
        [string]$LocalUserAuthorizedList,

        [Parameter(Mandatory = $false, HelpMessage = "'0' for NotRequired, '1' for Required, '2' for RequiredForInbound, '3' for RequiredForOutbound")]
        [ValidateRange(0, 3)]
        [int]$SecureFlags = 1,

        [Parameter(Mandatory = $false, HelpMessage = "Switch to enable firewall rule")]
        [switch]$Enable,

        [Parameter(Mandatory = $false, HelpMessage = "Switch to disable firewall rule")]
        [switch]$Disable,

        [Parameter(Mandatory = $false, HelpMessage = "Switch to remove firewall rule")]
        [switch]$Remove,

        [Parameter(Mandatory = $false, HelpMessage = "Switch to clear duplicate entries firewall rule names")]
        [switch]$ClearDuplicates
    )
    $fwRule = New-Object -ComObject HNetCfg.FwPolicy2
    ## check for duplicate rules and remove them if specified
    if ($ClearDuplicates.IsPresent) {
        $RemoveDuplicates = {
            ## get all firewall rules as strings and split them into sections
            $Output = (netsh advfirewall firewall show rule name=all verbose | Out-String).Trim() -split '\r?\n\s*\r?\n'
            ## extract property names from the first section of the output
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
                ## add missing properties to each object
                foreach ($Prop in $PropertyNames) {
                    if ($_.PSObject.Properties.Name -notcontains $Prop) {
                        $_ | Add-Member -MemberType NoteProperty -Name $Prop -Value $null
                    }
                }
                $_
            }
            ## group the firewall rules by their properties
            $Rules = $Objects | Group-Object -Property RuleName, Program, Action, Profiles, RemoteIP, RemotePort, LocalIP, LocalPort, Enabled, Protocol, Direction
            Write-Verbose -Message "Searching and removing duplicates..."
            ## remove duplicates for each group of rules
            $Rules | Where-Object { $_.Count -gt 1 } | ForEach-Object {
                ## get the name of the rule to keep and remove the rest
                $Name = $_ | Select-Object -ExpandProperty Group | Select-Object -ExpandProperty RuleName -First 1
                Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue | Select-Object -Skip 1 | Remove-NetFirewallRule -Verbose
            }
        }
        Invoke-Command -ScriptBlock $RemoveDuplicates
        return
    }
    $fwRule = New-Object -ComObject hnetcfg.fwpolicy2
    ## map Action to corresponding value
    switch ($Action) {
        "Allow" { $fwAction = 1 }
        "Block" { $fwAction = 0 }
        default { Write-Verbose -Message "Invalid Action parameter value: $Action"; return }
    }

    ## map Direction to corresponding value
    switch ($Direction) {
        "Inbound" { $fwDirection = 1 }
        "Outbound" { $fwDirection = 2 }
        default { Write-Verbose -Message "Invalid Direction parameter value: $Direction"; return }
    }

    ## map Protocol to corresponding value
    switch ($Protocol) {
        "TCP" { $fwProtocol = 6 }
        "UDP" { $fwProtocol = 17 }
        default { Write-Verbose -Message "Invalid Protocol parameter value: $Protocol"; return }
    }
    ## create a new firewall rule object and set properties
    $newRule = New-Object -ComObject HNetCfg.FWRule
    $newRule.Name = $Name
    $newRule.Description = "Rule for $Name"
    $newRule.Protocol = $fwProtocol
    $newRule.LocalPorts = $LocalPort
    $newRule.RemoteAddresses = $RemoteAddress
    $newRule.Direction = $fwDirection
    $newRule.Enabled = $Enable.IsPresent
    $newRule.Grouping = "@firewallapi.dll,-23255"
    $newRule.Profiles = 7
    $newRule.Action = $fwAction
    $newRule.EdgeTraversal = $false
    $newRule.InterfaceTypes = "All"
    $newRule.ApplicationName = $ApplicationName
    ## add the new rule if Enable parameter is present
    if ($Enable.IsPresent) {
        $fwRule.Rules.Add($newRule)
        Write-Verbose -Message "Firewall rule '$Name' has been added."
    }
    ## disable the rule if Disable parameter is present
    if ($Disable.IsPresent) {
        $rule = $fwRule.Rules.Item($Name)
        if ($null -ne $rule) {
            $rule.Enabled = $false
            Write-Verbose -Message "Firewall rule '$Name' has been disabled."
        }
        else {
            Write-Verbose -Message "Firewall rule '$Name' does not exist."
        }
    }
    ## remove the rule if Remove parameter is present
    if ($Remove.IsPresent) {
        $rule = $fwRule.Rules.Item($Name)
        if ($null -ne $rule) {
            $fwRule.Rules.Remove($Name)
            Write-Verbose -Message "Firewall rule '$Name' has been removed."
        }
        else {
            Write-Verbose -Message "Firewall rule '$Name' does not exist."
        }
    }
}
