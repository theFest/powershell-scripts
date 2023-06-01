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
    .PARAMETER ImportExportPath
    NotMandatory - path for either importing or exporting rules from/to csv file.
    .PARAMETER Force
    NotMandatory - specifies whether to force the action or not.
    .PARAMETER Block
    Parameter - blocks the traffic specified by the rule.
    .PARAMETER Scope
    Parameter - scope of the operation. Valid values are "Profile" or "Rule". Default is "Rule".
    .PARAMETER Group
    Parameter - specifies the group to which the firewall rule belongs.
    .PARAMETER AllGroups
    Parameter - performs the action on all firewall rule groups.
    
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
    FirewallManagerCMD -Action Export -ImportExportPath "$env:USERPROFILE\Desktop\fw_rules_ex.csv"
    FirewallManagerCMD -Action Start
    FirewallManagerCMD -Action Stop

    .NOTES
    v0.0.4
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Get", "List", "Show", "Add", "Remove", "Modify", "Enable", "Disable", "Rename", "Export", `
                "Start", "Stop", "DisableAll", "EnableAll", "BlockAllGroups", "AllowAllGroups", "RestoreDefaults")]
        [string]$Action,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Inbound", "Outbound")]
        [string]$Direction,

        [Parameter(Mandatory = $false)]
        [ValidateSet("TCP", "UDP", "ICMPV4", "ICMPV6", "Any")]
        [string]$Protocol,

        [Parameter(Mandatory = $false)]
        [string]$LocalPort = "Any",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$LocalAddress = "Any",

        [Parameter(Mandatory = $false)]
        [string]$RemotePort = "Any",

        [Parameter(Mandatory = $false)]
        [string]$RemoteAddress = "Any",

        [Parameter(Mandatory = $false)]
        [ValidateSet("True", "False")]
        [string]$Enabled,

        [Parameter(Mandatory = $false)]
        [string]$NewName,

        [Parameter(Mandatory = $false)]
        [string]$ImportExportPath,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$Block,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Profile", "Rule")]
        [string]$Scope = "Rule",

        [Parameter(Mandatory = $false)]
        [string]$Group,

        [Parameter(Mandatory = $false)]
        [switch]$AllGroups
    )
    if ($Action -in "List", "Show", "Import", "Export", "Start", "Stop") {
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
        "Export" {
            if ($Scope -eq "Rule") {
                Get-NetFirewallRule | Export-Csv -Path $ImportExportPath -NoTypeInformation -Verbose
            }
            elseif ($Scope -eq "Profile") {
                Get-NetFirewallProfile | Export-Csv -Path $ImportExportPath -NoTypeInformation -Verbose
            }
            else {
                Write-Error "Invalid scope specified. Please use 'Rule' or 'Profile' for the Export action."
            }
        }
        "Start" {
            #netsh advfirewall set allprofiles state on
            #Get-Service -Name mpssvc -Verbose | Start-Service -Verbose -PassThru
            $firewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
            if ($firewallProfiles) {
                $firewallProfiles | ForEach-Object {
                    if (-not $_.Enabled) {
                        Set-NetFirewallProfile -Profile $_.Name -Enabled True -Verbose
                        Write-Verbose -Message "Enabled firewall profile: $($_.Name)."
                    }
                }
            }
            $firewallService = Get-Service -Name "MpsSvc" -ErrorAction SilentlyContinue
            if ($firewallService.Status -ne "Running") {
                Start-Service -Name "MpsSvc" -Verbose
                Write-Verbose -Message "Started firewall service."
            }
        }
        "Stop" {
            #netsh advfirewall set allprofiles state off
            ## reg add hklm\system\currentcontrolset\services\mpssvc /t reg_dword /v start /d 4 /f
            $firewallProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
            if ($firewallProfiles) {
                $firewallProfiles | ForEach-Object {
                    if ($_.Enabled) {
                        Set-NetFirewallProfile -Profile $_.Name -Enabled False -Verbose
                        Write-Verbose -Message "Disabled firewall profile: $($_.Name)."
                    }
                }
            }
        }
        "DisableAll" {
            Disable-NetFirewallProfile -All -Verbose
            Write-Verbose -Message "Disabled all firewall profiles."
        }
        "EnableAll" {
            Enable-NetFirewallProfile -All -Verbose
            Write-Verbose -Message "Enabled all firewall profiles."
        }
        "BlockAllGroups" {
            if ($AllGroups) {
                $Groups = Get-NetFirewallRule | Where-Object { $null -ne $_.Group } | Select-Object -ExpandProperty Group -Unique
                foreach ($Group in $Groups) {
                    Set-NetFirewallProfile -Profile $Group -Enabled False -Verbose
                    Write-Verbose -Message "Disabled firewall profile: $Group."
                }
            }
            elseif ($Group) {
                Set-NetFirewallProfile -Profile $Group -Enabled False -Verbose
                Write-Verbose -Message "Disabled firewall profile: $Group."
            }
            else {
                Write-Error -Message "Please specify a group or use the -AllGroups switch to block all firewall profiles."
            }
        }
        "AllowAllGroups" {
            if ($AllGroups) {
                $groups = Get-NetFirewallRule | Where-Object { $null -ne $_.Group } | Select-Object -ExpandProperty Group -Unique
                foreach ($Group in $Groups) {
                    Set-NetFirewallProfile -Profile $Group -Enabled True -Verbose
                    Write-Verbose -Message "Enabled firewall profile: $Group."
                }
            }
            elseif ($Group) {
                Set-NetFirewallProfile -Profile $Group -Enabled True -Verbose
                Write-Verbose -Message "Enabled firewall profile: $Group."
            }
            else {
                Write-Error -Message "Please specify a group or use the -AllGroups switch to allow all firewall profiles."
            }
        }
        "RestoreDefaults" {
            Write-Warning -Message "Restoring default firewall settings..."
            netsh advfirewall reset
            Write-Verbose -Message "Default firewall settings have been restored."
        }
        default {
            Write-Error -Message "Invalid action. Please use one"
        }
    }
}
