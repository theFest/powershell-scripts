Function FirewallManagerHNC {
    <#
    .SYNOPSIS
    Manages Windows Firewall rules and Windows Firewall control.

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
    FirewallRulesManagerFWPolicy -ClearDuplicates -Verbose
    FirewallRulesManagerFWPolicy -Operate Add -Name "AAAabc" -Description "AAAabc" -ApplicationName "C:\temp\myapp.exe" -Action Allow -Direction Inbound -Protocol TCP `
        -LocalPort "80" -RemotePort '2334' -LocalAddress "192.168.100.5", "192.168.100.2" -RemoteAddress "192.168.100.3", "192.168.100.2" -Enable -Verbose -Force

    .NOTES
    v0.1.0
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, HelpMessage = "Choose operation for managing rules via HNet Configuration")]
        [ValidateSet("AddRule", "RemoveRule", "EnableRule", "DisableRule", "ModifyRule", `
                "BlockIP", "UnblockIP", "BlockPort", "UnblockPort", "EnableFW", "DisableFW", "ResetFW", "HNetCfgRegSvrDLL")]
        [string]$Operate,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, HelpMessage = "Enter a name for the Windows firewall rule")]
        [ValidateNotNullOrEmpty()]
        [string[]]$Name,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string[]]$CSVFilePath,

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
        [ValidateSet("Any", "TCP", "UDP", "ICMPv4", "ICMPv6")]
        [string]$Protocol,

        [Parameter(Mandatory = $false, HelpMessage = "Enter a local port number or a comma-separated list of port numbers for the firewall rule")]
        [ValidateRange(1, 65535)]
        [string[]]$LocalPort,

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
        [string]$Direction, # In/Out

        [Parameter(Mandatory = $false, HelpMessage = "Select the interface for the firewall rule")]
        [ValidateSet("Ethernet", "Wi-Fi")]
        [string[]]$Interfaces = "Ethernet",

        [Parameter(Mandatory = $false, HelpMessage = "Select the interface type for the firewall rule")]
        [ValidateSet("Any", "Ethernet", "Wireless", "RemoteAccess", "VPN")]
        [string]$InterfaceType = "Any", # "All"

        [Parameter(Mandatory = $false, HelpMessage = "Enter a grouping for the firewall rule")]
        [string]$Group = "",

        [Parameter(Mandatory = $false, HelpMessage = "Select the profile for the firewall rule")]
        [ValidateSet("Any", "Private", "Public", "Domain")]
        [string[]]$Profile = "Any", # "All"

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
        [string[]]$LocalUserAuthorizedList,

        [Parameter(Mandatory = $false, HelpMessage = "Either output to file or display on screen, count and list of rules")]
        [ValidateSet("List", "OutHost", "ExportFile", "ActiveRulesList", "InactiveRulesList")]
        [string]$OutputType,

        [Parameter(Mandatory = $false)]
        [string]$ExportPath = "$env:USERPROFILE\Desktop\your_rules_info.csv",

        [Parameter(Mandatory = $false, HelpMessage = "Switch to clear duplicate entries firewall rule names")]
        [switch]$Enable,

        [Parameter(Mandatory = $false, HelpMessage = "Switch to clear duplicate entries firewall rule names")]
        [switch]$Force,

        [Parameter(Mandatory = $false, HelpMessage = "Switch to clear duplicate entries firewall rule names")]
        [switch]$CheckForDuplicates
    )
    BEGIN {
        Write-Verbose -Message "Starting HNetCfg Firewall Manager..."
        if ($CSVFilePath) {
            $rules = Import-Csv -Path $CSVFilePath
            $rules | ForEach-Object { FirewallManagerHNC @PSBoundParameters -Action "Add" @$_ }
        }
        #$FirewallMgr = New-Object -ComObject HNetCfg.FwMgr
        $FirewallPolicy = New-Object -ComObject HNetCfg.FwPolicy2
        if ($OutputType) {
            $Outputs = {
                try {
                    $RulesList = $FirewallPolicy.Rules
                    $RuleCount = $RulesList.Count
                    $RulesDisplay = foreach ($Rules in $RulesList) {
                        Write-Host "Name: $($Rules.Name), Enabled: $($Rules.Enabled)"
                    }
                    switch ($OutputType) {
                        "List" {
                            $RulesList | Select-Object Name, Protocol, Direction, Enabled `
                                , @{Name = "Remote Addresses"; Expression = { $_.RemoteAddresses -join ',' } } | Format-Table
                        }
                        "OutHost" {
                            Write-Host "Firewall rule count: $RuleCount" -ForegroundColor DarkGreen
                            Write-Host "Firewall rules list: $RulesDisplay" -ForegroundColor DarkCyan
                        }
                        "ExportFile" {
                            $RulesList | Export-Csv -Path $ExportPath -NoTypeInformation -Append -Verbose
                            Write-Verbose -Message "Exported list and count of rules to $ExportPath"
                        }
                        "ActiveRulesList" {
                            $ActiveRules = $FirewallPolicy.Rules | Where-Object { $_.Enabled -eq $true }
                            $ActiveRules | Export-Csv -Path $ExportPath -NoTypeInformation -Append -Verbose
                            Write-Host "Active Firewall Rules:"
                            foreach ($Rule in $ActiveRules) {
                                Write-Host "- $($Rule.Name)"
                            }
                        }
                        "InactiveRulesList" {
                            $InactiveRules = $FirewallPolicy.Rules | Where-Object { $_.Enabled -eq $false }
                            $InactiveRules | Export-Csv -Path $ExportPath -NoTypeInformation -Append -Verbose
                            Write-Host "Inactive Firewall Rules:"
                            foreach ($Rule in $InactiveRules) {
                                Write-Host "- $($Rule.Name)"
                            }
                        }
                    }
                }
                catch {
                    Write-Error -Message "An error occurred: $_"
                }
            }
            Write-Host "Output information before tampering: " ; Invoke-Command -ScriptBlock $Outputs
        }
        if ($CheckForDuplicates) {
            Write-Verbose -Message "Verification of duplicates, please wait..."
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
                } ; $_
                $Rules = $Objects | Group-Object -Property RuleName, Program, Action, Profiles, RemoteIP, RemotePort, LocalIP, LocalPort, Enabled, Protocol, Direction
                $Rules | Where-Object { $_.Count -gt 1 } | ForEach-Object {
                    $Name = $_ | Select-Object -ExpandProperty Group | Select-Object -ExpandProperty RuleName -First 1
                    Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue | Select-Object -Skip 1 | Remove-NetFirewallRule -Verbose
                }
            }
            Write-Verbose -Message "Searching for duplicate Firewall rules(Pass~1)..." ; Invoke-Command -ScriptBlock $RemoveDuplicates ; return
        }
    }
    PROCESS {
        $FirewallProps = @{
            Name                    = $Name -join ','
            Enabled                 = $Enable.IsPresent
            Description             = $Description
            ApplicationName         = $ApplicationName
            ServiceName             = $ServiceName
            IcmpTypesAndCodes       = $IcmpTypesAndCodes
            LocalAppPackageId       = $LocalAppPackageId
            LocalUserAuthorizedList = $LocalUserAuthorizedList
        }
        if ($Action) {
            $FirewallProps.Action = @{
                Allow = 1 ; Block = 0
            }[$Action]
        }
        if ($Direction) {
            $FirewallProps.Direction = @{
                Inbound = 1 ; Outbound = 2
            }[$Direction]
        }
        if ($Protocol) {
            $FirewallProps.Protocol = @{
                Any = 256 ; TCP = 6 ; UDP = 17 ; ICMPv4 = 1 ; ICMPv6 = 58
            }[$Protocol]
        }
        if ($Group) {
            $FirewallProps.Grouping = $Group #"@firewallapi.dll,-23255"
        }
        if ($Profile) {
            $FirewallProps.Profiles = @{
                Any = 0 ; Domain = 1 ; Private = 2 ; Public = 4
            }[$Profile]
        }
        if ($LocalAddress) {
            $FirewallProps.LocalAddresses = $LocalAddress -join ','
        }
        if ($LocalPort) {
            $FirewallProps.LocalPorts = $LocalPort -join ','
        }
        if ($RemoteAddress) {
            $FirewallProps.RemoteAddresses = $RemoteAddress -join ','
        }
        if ($RemotePort) {
            $FirewallProps.RemotePorts = $RemotePort -join ','
        }
        if ($Interfaces -or $InterfaceTypes) {
            $FirewallProps.Interfaces = $Interface
            $FirewallProps.InterfaceTypes = @{
                All = 0 ; Ethernet = 1 ; Wireless = 71
            }[$InterfaceType]
        }
        if ($EdgeTraversal -or $EdgeTraversalOptions) {
            $FirewallProps.EdgeTraversal = $EdgeTraversal
            $FirewallProps.EdgeTraversalOptions = @{
                NotConfigured = 0 ; Block = 1 ; Allow = 2
            }[$EdgeTraversalOptions]
        }
        if ($LocalUserOwner) {
            $FirewallProps.LocalUserOwner = @{
                Any = "S-1-1-0" ; CurrentUser = "S-1-5-32-545" ; AllUsers = "S-1-5-32-544"
            }[$LocalUserOwner]
        }
        $FirewallRule = New-Object -TypeName PSObject -Property $FirewallProps
        switch ($Operate) {
            "AddRule" {
                foreach ($Rule in $FirewallProps) {
                    $FWNewPolicy = New-Object -ComObject HNetCfg.FwPolicy2
                    $FirewallRule = $FWNewPolicy.Rules | Where-Object { $_.Name -eq $Rule.Name }
                    if ($null -ne $FirewallRule) {
                        if ($Force) {
                            Write-Warning -Message "Firewall rule '$($Rule.Name)' already exists, overwriting!"
                        }
                        else {
                            Write-Verbose -Message "Firewall rule '$($Rule.Name)' already exists, skipping..."
                            continue
                        }
                    }
                    else {
                        $FirewallRule = New-Object -ComObject HNetCfg.FWRule
                        foreach ($Prop in $Rule.Properties.Keys) {
                            $Value = $Rule.Properties[$Prop]
                            if ($Value) {
                                $FirewallRule.Properties.Item($Prop).Value = $Value
                            }
                        }
                        $FirewallRule.Name = $Rule.Name
                        #$FirewallRule.Action = @{Allow = 1; Block = 0 }[$Rule.Action]
                        try {
                            $FWNewPolicy.Rules.Add($FirewallRule)
                            Write-Verbose -Message "Created firewall rule: $($Rule.Name)"
                        }
                        catch [System.Exception] {
                            Write-Error "Failed to create firewall rule: $($_.Exception.Message)"
                        }
                    }
                }
            }
            "RemoveRule" {
                foreach ($RuleName in $Name) {
                    if ($RuleName -isnot [string]) {
                        Write-Error "Firewall rule name '$RuleName' is not a string"
                        continue
                    }
                    $FirewallRule = $FirewallPolicy.Rules | Where-Object { $_.Name -eq $RuleName }
                    if ($null -ne $FirewallRule) {
                        try {
                            $FirewallRule | Foreach-Object {
                                $FirewallPolicy.Rules.Remove($RuleName)
                            }
                            Write-Verbose -Message "Firewall rule's '$RuleName' has been removed"
                        }
                        catch [System.Exception] {
                            Write-Error "Failed to remove firewall rule: $($_.Exception.Message)"
                        }
                    }
                    else {
                        Write-Warning -Message "Firewall rule '$RuleName' does not exist"
                    }
                }
            }
            "ModifyRule" {
                $FirewallPolicy = New-Object -ComObject HNetCfg.FwPolicy2
                $ExistingRule = $FirewallPolicy.Rules | Where-Object { $_.Name -eq $Name }
                if ($null -eq $ExistingRule) {
                    throw "Firewall rule '$Name' does not exist and cannot be modified"
                }
                Write-Warning -Message "Modifying existing rule: $($ExistingRule.Name)"
                try {
                    $FirewallProps.GetEnumerator() | ForEach-Object {
                        $Prop = $_.Key
                        $Value = $_.Value
                        if ($Value) {
                            if ($Prop -eq "Profiles") {
                                $ExistingRule.Profiles = $FirewallProfiles.$Value
                            }
                            else {
                                $ExistingRule.$Prop = $Value
                            }
                        }
                    }
                    Write-Verbose -Message "Modified firewall rule: $($ExistingRule.Name)"
                }
                catch {
                    Write-Error "Failed to modify firewall rule: $($_.Exception.Message)"
                }
            }
            "EnableRule" {
                try {
                    $FirewallRule = $FirewallPolicy.Rules.Item($Name)
                    $FirewallRule.Action = $Action
                    $FirewallRule.Enabled = $true
                    Write-Verbose -Message "Enabled firewall rule: $($FirewallRule.Name)"
                }
                catch [System.Exception] {
                    Write-Error "Failed to enable firewall rule: $($_.Exception.Message)"
                }
            }
            "DisableRule" {
                try {
                    $FirewallRule = $FirewallPolicy.Rules.Item($Name)
                    $FirewallRule.Enabled = $false
                    Write-Verbose -Message "Disabled firewall rule: $($FirewallRule.Name)"
                }
                catch [System.Exception] {
                    Write-Error "Failed to disable firewall rule: $($_.Exception.Message)"
                }
            }
            "BlockIP" {
                if ($null -eq $BlkIpsPrt) {
                    Write-Warning -Message "IP address not provided."
                }
                else {
                    $FirewallPolicy.Rules | Where-Object { $_.RemoteAddress -eq $BlkIpsPrt } | ForEach-Object { $_.Enabled = $false }
                    Write-Host "Blocked traffic from IP address: $BlkIpsPrt" -ForegroundColor DarkGreen
                }
            }
            "UnblockIP" {
                if ($null -eq $BlkIpsPrt) {
                    Write-Warning "IP address not provided."
                }
                else {
                    $FirewallPolicy.Rules | Where-Object { $_.RemoteAddress -eq $BlkIpsPrt } | ForEach-Object { $_.Enabled = $true }
                    Write-Host "Unblocked traffic from IP address: $BlkIpsPrt" -ForegroundColor DarkGreen
                }
            }
            "BlockPort" {
                if ($null -eq $BlkIpsPrt) {
                    Write-Warning "Port not provided."
                }
                else {
                    $FirewallPolicy.Rules | Where-Object { $_.LocalPort -eq $BlkIpsPrt } | ForEach-Object { $_.Enabled = $false }
                    Write-Host "Blocked traffic on port: $BlkIpsPrt" -ForegroundColor DarkGreen
                }
            }
            "UnblockPort" {
                if ($null -eq $BlkIpsPrt) {
                    Write-Warning "Port not provided."
                }
                else {
                    $FirewallPolicy.Rules | Where-Object { $_.LocalPort -eq $BlkIpsPrt } | ForEach-Object { $_.Enabled = $true }
                    Write-Host "Unblocked traffic on port: $BlkIpsPrt" -ForegroundColor DarkGreen
                }
            }
            "EnableFW" {
                $FirewallPolicy.Enable() ; $FirewallPolicy.EnableRuleGroup("Windows Firewall")
                Write-Host "Windows Firewall has been enabled" -ForegroundColor DarkGreen
            }
            "DisableFW" {
                $FirewallPolicy.Disable() ; $FirewallPolicy.DisableRuleGroup("Windows Firewall")
                Write-Host "Windows Firewall has been disabled!" -ForegroundColor DarkMagenta
            }
            "ResetFW" {
                $FirewallPolicy.RestoreLocalFirewallDefaults()
                Write-Warning -Message "Windows Firewall has been reset to default settings!"
            }
            "HNetCfgRegSvrDLL" {
                Write-Warning -Message "Invalid action, use: EnableFW, DisableFW or ResetFW!"
                Write-Verbose -Message "HNet Configuration Registration in process..."
                Start-Process regsvr32 -ArgumentList "HNetCfg.dll /s" -WindowStyle Hidden -Wait `
                    -RedirectStandardError "$env:TEMP\fwrmobject_error.log" `
                    -RedirectStandardOutput "$env:TEMP\fwrmobject_output.log"
            }
            default {
                Write-Debug -Message "Invalid operation selected!" -Verbose
            }
        }
    }
    END {
        if ($OutputType) {
            Write-Host "Output information after tampering: " -ForegroundColor Cyan ; `
                Write-Output -InputObject $FirewallRule ; Invoke-Command -ScriptBlock $Outputs
        }
        if ($CheckForDuplicates) {
            Write-Verbose -Message "Searching for duplicate Firewall rules(Pass~2)..." ; Invoke-Command -ScriptBlock $RemoveDuplicates
        }
    }
}
