Function Set-RemovableStorageAccess {
    <#
    .SYNOPSIS
    Sets or queries the policy for removable storage device access.

    .DESCRIPTION
    This function allows you to enable or disable the policy for removable storage devices access on Windows systems. It also provides an option to query the current state of the policy.

    .PARAMETER Action
    Specifies the action to be performed, values are "Enable", "Disable", or "Query".

    .EXAMPLE
    Set-RemovableStorageAccess -Action Query
    Set-RemovableStorageAccess -Action Enable
    Set-RemovableStorageAccess -Action Disable
        
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Enable", "Disable", "Query")]
        [string]$Action
    )
    $RegKeyPath = 'HKLM:\Software\Policies\Microsoft\Windows\RemovableStorageDevices\{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}'
    $TestRegistryValue = {
        param($Regkey, $Name)
        $Exists = Get-ItemProperty -Path $Regkey -Name $Name -ErrorAction SilentlyContinue
        if ($null -ne $Exists -and $Exists.Length -ne 0) {
            Write-Host "The policy is Enabled..." -BackgroundColor Green -ForegroundColor Black
        }
        else {
            Write-Host "The policy is Disabled..." -BackgroundColor Green -ForegroundColor Black
        }
    }
    $CreateRegistryValue = {
        param($Regkey, $Name)
        
        if (!(Test-Path -Path $Regkey)) {
            New-Item -Path $Regkey -Force | Out-Null
        }
        New-ItemProperty -Path $Regkey -Name $Name -Value 1 -PropertyType 'DWord' -Force | Out-Null
    }
    $DeleteRegistryValue = {
        param($Regkey)
        if (Test-Path -Path $Regkey) {
            Remove-Item -Path $Regkey -Recurse -Force | Out-Null
        }
    }
    switch ($Action) {
        "Enable" {
            & $CreateRegistryValue -Regkey $RegKeyPath -Name 'Deny_Read'
            & $CreateRegistryValue -Regkey $RegKeyPath -Name 'Deny_Write'
            Write-Host "Policy is set to Enabled..." -BackgroundColor Green
            break
        }
        "Disable" {
            & $DeleteRegistryValue -Regkey $RegKeyPath
            Write-Host "Policy is set to Disabled..." -BackgroundColor Red
            break
        }
        "Query" {
            & $TestRegistryValue -Regkey $RegKeyPath -Name 'Deny_Read'
            break
        }
        default {
            Write-Warning -Message "Invalid action, use 'Enable', 'Disable', or 'Query'"
            break
        }
    }
}
