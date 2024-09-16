function Get-GroupPolicyStartupItems {
    <#
    .SYNOPSIS
    Retrieves startup items from specified registry hives and keys, including Group Policy and Local Policy settings.

    .DESCRIPTION
    This function searches for startup items in specified registry hives and keys, which are often used to manage applications that start with the system.
    Allows filtering by registry hive, key, and scope, and optionally includes startup items defined in Local Policy. Supports multiple registry hives and keys, including common locations for startup entries, such as `HKLM` and `HKCU`, as well as the `Run` keys under `SOFTWARE\Microsoft\Windows\CurrentVersion`.

    .EXAMPLE
    Get-GroupPolicyStartupItems

    .NOTES
    v0.3.4
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Registry hive to search for startup items")]
        [ValidateSet("HKLM", "HKCU", "HKU", "HKCR", "HKCC", "AllHives")]
        [string]$RegistryHive = "HKLM",

        [Parameter(Mandatory = $false, HelpMessage = "Registry key to search for startup items")]
        [ValidateSet("SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run", "AllKeys")]
        [string]$RegistryKey = "SOFTWARE\Microsoft\Windows\CurrentVersion\Run",

        [Parameter(Mandatory = $false, HelpMessage = "Scope for the registry search")]
        [ValidateSet("LocalMachine", "CurrentUser", "Users", "ClassesRoot", "CurrentConfig", "AllScopes")]
        [string]$Scope = "LocalMachine",

        [Parameter(Mandatory = $false, HelpMessage = "Include Local Policy settings in the search for startup items")]
        [switch]$IncludeLocalPolicy
    )
    $ValidHives = @("HKLM", "HKCU", "HKU", "HKCR", "HKCC")
    if ($RegistryHive -eq "AllHives") {
        $HivesToUse = $ValidHives
    }
    elseif ($ValidHives -contains $RegistryHive) {
        $HivesToUse = @($RegistryHive)
    }
    else {
        Write-Error -Message "Invalid registry hive: $RegistryHive"
        return
    }
    $Keys = @('SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run')
    if ($RegistryKey -eq 'AllKeys') {
        $KeysToUse = $Keys
    }
    elseif ($Keys -contains $RegistryKey) {
        $KeysToUse = @($RegistryKey)
    }
    else {
        Write-Error -Message "Invalid registry key: $RegistryKey"
        return
    }
    $Results = @()
    foreach ($Hive in $HivesToUse) {
        foreach ($Key in $KeysToUse) {
            $FullRegistryPath = Join-Path -Path $Hive -ChildPath $Key
            if (Test-Path -Path "Registry::$FullRegistryPath") {
                try {
                    $PolicyItems = Get-Item -LiteralPath "Registry::$FullRegistryPath" -ErrorAction Stop | Get-ItemProperty
                    foreach ($Item in $PolicyItems.PSObject.Properties) {
                        $Results += [PSCustomObject]@{
                            Path  = $FullRegistryPath
                            Name  = $Item.Name
                            Value = $Item.Value
                            Scope = $Scope
                            Type  = "Group Policy"
                        }
                    }
                }
                catch {
                    Write-Error -Message "Error accessing registry path: $FullRegistryPath - $_"
                }
            }
            else {
                Write-Warning -Message "Registry path not found: $FullRegistryPath"
            }
        }
    }
    if ($IncludeLocalPolicy) {
        $LocalPoliciesPath = Join-Path -Path 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies' -ChildPath 'Explorer'
        if (Test-Path -Path "Registry::$LocalPoliciesPath") {
            $LocalPolicies = Get-Item -LiteralPath "Registry::$LocalPoliciesPath" -ErrorAction SilentlyContinue | Get-ItemProperty
            foreach ($LocalPolicy in $LocalPolicies.PSObject.Properties) {
                $Results += [PSCustomObject]@{
                    Path  = $LocalPoliciesPath
                    Name  = $LocalPolicy.Name
                    Value = $LocalPolicy.Value
                    Scope = 'Local'
                    Type  = "Local Policy"
                }
            }
        }
        else {
            Write-Warning -Message "Local policies registry path not found: $LocalPoliciesPath!"
        }
    }
    $Results | Sort-Object Name | Format-Table -AutoSize
}
