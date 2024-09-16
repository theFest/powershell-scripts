function Get-RegistryStartupItems {
    <#
    .SYNOPSIS
    Retrieves startup items from the Windows Registry.

    .DESCRIPTION
    This function retrieves startup items from the Windows Registry under the `Run` and `RunOnce` keys. It allows querying both `HKLM` and `HKCU` hives and supports filtering by scope (CurrentUser or AllUsers). The function can also be filtered by item name.

    .EXAMPLE
    Get-RegistryStartupItems -Scope "AllUsers" -Verbose
    Get-RegistryStartupItems -Hive "HKCU" -Scope "CurrentUserOnly"
    Get-RegistryStartupItems -Hive "HKLM" -Path "Software\Microsoft\Windows\CurrentVersion\RunOnce" -Filter "MyApp"

    .NOTES
    v0.2.8
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify the registry hive (HKLM or HKCU)")]
        [ValidateSet("HKLM", "HKCU")]
        [string]$Hive = "HKLM",

        [Parameter(Mandatory = $false, HelpMessage = "Specific registry path to search under. If not provided, the default paths for startup items in both `Run` and `RunOnce` will be used")]
        [ValidateSet(
            "Software\Microsoft\Windows\CurrentVersion\Run",
            "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
            "Software\Microsoft\Windows\CurrentVersion\RunOnce",
            "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce"
        )]
        [string]$Path = $null,

        [Parameter(Mandatory = $false, HelpMessage = "Defines whether to search startup items for the current user only (`CurrentUserOnly`) or for all users (`AllUsers`)")]
        [ValidateSet("CurrentUserOnly", "AllUsers")]
        [string]$Scope = "AllUsers",

        [Parameter(Mandatory = $false, HelpMessage = "Filters the startup items by name. If provided, only items that match the filter will be returned")]
        [string]$Filter = $null
    )
    BEGIN {
        Write-Verbose -Message "Starting to retrieve registry startup items from $Hive with scope $Scope"
        if (-not $Path) {
            $Paths = @(
                "Software\Microsoft\Windows\CurrentVersion\Run",
                "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
                "Software\Microsoft\Windows\CurrentVersion\RunOnce",
                "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce"
            )
        }
        else {
            $Paths = @($Path)
        }
        if ($Scope -eq "CurrentUserOnly") {
            $Hive = "HKCU"
        }
    }
    PROCESS {
        foreach ($CurrentPath in $Paths) {
            $RegistryPath = "Registry::$Hive\$CurrentPath"
            Write-Verbose -Message "Checking registry path: $RegistryPath"
            try {
                if (Test-Path $RegistryPath) {
                    $Items = Get-ItemProperty -Path $RegistryPath -ErrorAction Stop
                    foreach ($Property in $Items.PSObject.Properties) {
                        $Name = $Property.Name
                        $Value = $Property.Value
                        if (-not $Filter -or $Name -like "*$Filter*") {
                            [PSCustomObject]@{
                                Hive         = $Hive
                                Path         = $CurrentPath
                                RegistryPath = $RegistryPath
                                Scope        = $Scope
                                Name         = $Name
                                Value        = $Value
                            }
                        }
                    }
                }
                else {
                    Write-Verbose -Message "Registry path does not exist: $RegistryPath"
                }
            }
            catch {
                Write-Error -Message "Error retrieving items from registry path: $RegistryPath - $_.Exception.Message"
            }
        }
    }
    END {
        Write-Verbose -Message "Completed retrieval of registry startup items"
    }
}
