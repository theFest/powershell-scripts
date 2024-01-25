Function Get-RegistryStartupItems {
    <#
    .SYNOPSIS
    Retrieves information about Windows startup items in the Windows Registry.

    .DESCRIPTION
    This function retrieves information about startup items from the Windows Registry. It allows you to specify the registry hive, path, scope (current user or all users), and filter the results based on a name substring.

    .PARAMETER Hive
    Specifies the registry hive (HKLM for Local Machine or HKCU for Current User), default is HKLM.
    .PARAMETER Path
    Specifies the registry path for startup items, default is "Software\Microsoft\Windows\CurrentVersion\Run".
    .PARAMETER Scope
    Specifies the scope of the startup items (CurrentUserOnly or AllUsers), default is AllUsers.
    .PARAMETER Filter
    Specifies a substring to filter the results based on the name of the startup items.

    .EXAMPLE
    Get-RegistryStartupItems

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("HKLM", "HKCU")]
        [string]$Hive = "HKLM",

        [Parameter(Mandatory = $false)]
        [ValidateSet(
            "Software\Microsoft\Windows\CurrentVersion\Run",
            "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
            "Software\Microsoft\Windows\CurrentVersion\RunOnce",
            "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce"
        )]
        [string]$Path = $null,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUserOnly", "AllUsers")]
        [string]$Scope = "AllUsers",

        [Parameter(Mandatory = $false)]
        [string]$Filter
    )
    if (-not $Path) {
        $Paths = @(
            "Software\Microsoft\Windows\CurrentVersion\Run",
            "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run",
            "Software\Microsoft\Windows\CurrentVersion\RunOnce",
            "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\RunOnce"
        )
    }
    else {
        $Paths = $Path
    }
    foreach ($CurrentPath in $Paths) {
        $RegistryPath = "Registry::$Hive\$CurrentPath"
        if ($Scope -eq "CurrentUserOnly") {
            $RegistryPath = "Registry::${Hive}CU\$CurrentPath"
        }
        try {
            $Items = Get-ItemProperty -Path $RegistryPath -ErrorAction Stop
            $Items.PSObject.Properties | ForEach-Object {
                $Name = $_.Name
                $Value = $_.Value
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
        catch {
            Write-Error -Message "Error accessing registry path: $RegistryPath!"
        }
    }
}
