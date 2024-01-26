Function Get-GroupPolicyStartupItems {
    <#
    .SYNOPSIS
    Retrieves Group Policy startup items from specified registry hives and keys.

    .DESCRIPTION
    This function retrieves Group Policy startup items from the Windows registry based on the specified registry hive, key, and scope.

    .PARAMETER RegistryHive
    Registry hive(s) to search for Group Policy startup items, valid values are HKLM, HKCU, HKU, HKCR, HKCC, or AllHives.
    .PARAMETER RegistryKey
    Registry key(s) to search for Group Policy startup items, values are SOFTWARE\Microsoft\Windows\CurrentVersion\Run, SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run, or AllKeys.
    .PARAMETER Scope
    Scope(s) to search for Group Policy startup items, values are LocalMachine, CurrentUser, Users, ClassesRoot, CurrentConfig, or AllScopes.
    .PARAMETER IncludeLocalPolicy
    Indicating whether to include local policy items in the results.

    .EXAMPLE
    Get-GroupPolicyStartupItems -RegistryHive AllHives -RegistryKey AllKeys -Scope AllScopes -IncludeLocalPolicy

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("HKLM", "HKCU", "HKU", "HKCR", "HKCC", "AllHives")]
        [string]$RegistryHive = "HKLM",

        [Parameter(Mandatory = $false)]
        [ValidateSet("SOFTWARE\Microsoft\Windows\CurrentVersion\Run", "SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run", "AllKeys")]
        [string]$RegistryKey = "SOFTWARE\Microsoft\Windows\CurrentVersion\Run",

        [Parameter(Mandatory = $false)]
        [ValidateSet("LocalMachine", "CurrentUser", "Users", "ClassesRoot", "CurrentConfig", "AllScopes")]
        [string]$Scope = "LocalMachine",

        [Parameter(Mandatory = $false)]
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
        Write-Error "Invalid registry hive: $RegistryHive"
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
    foreach ($Hive in $HivesToUse) {
        foreach ($Key in $KeysToUse) {
            $FullRegistryPath = Join-Path -Path $Hive -ChildPath $Key
            if (Test-Path -Path "Registry::$FullRegistryPath") {
                try {
                    $PolicyItems = Get-Item -LiteralPath "Registry::$FullRegistryPath" -ErrorAction Stop | Get-ItemProperty
                    foreach ($Item in $PolicyItems.PSObject.Properties) {
                        [PSCustomObject]@{
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
                [PSCustomObject]@{
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
}
