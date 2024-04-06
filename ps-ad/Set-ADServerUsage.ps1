#Requires -Version 3.0 -Modules ActiveDirectory
Function Set-ADServerUsage {
    <#
    .SYNOPSIS
    Sets the default server usage for Active Directory cmdlets.
    
    .DESCRIPTION
    This function sets the default server usage for Active Directory cmdlets by configuring the PSDefaultParameterValues hashtable with the appropriate server value. By default, it discovers the closest domain controller in the site. Optionally, you can specify to use the primary domain controller (PDC) emulator.
    
    .PARAMETER PrimaryDC
    Use the primary domain controller (PDC) emulator as the default server. If this switch is used, the function sets the PDC emulator as the default server. By default, the closest domain controller in the site is used.
    
    .EXAMPLE
    Set-ADServerUsage -PrimaryDC
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [switch]$PrimaryDC
    )
    BEGIN {
        $DomainController = $null
    }
    PROCESS {
        if ((Get-Command -Name Get-ADDomain -ErrorAction SilentlyContinue) -and (Get-Command -Name Get-ADDomainController -ErrorAction SilentlyContinue)) {
            if ($PrimaryDC) {
                $DomainController = ((Get-ADDomain -ErrorAction SilentlyContinue -WarningAction SilentlyContinue).PDCEmulator)
            }
            else {
                $DomainController = (Get-ADDomainController -Discover -NextClosestSite -ErrorAction SilentlyContinue -WarningAction SilentlyContinue)
            }
            $PSDefaultParameterValues.add('*-AD*:Server', "$DomainController")
        }
    }
    END {
        if (-not $PSDefaultParameterValues) {
            $PSDefaultParameterValues = @{}
        }
        if ($DomainController) {
            Write-Host "Server usage for Active Directory cmdlets set to: $DomainController" -ForegroundColor Green
        }
        else {
            Write-Warning -Message "No domain controller found, Server usage for Active Directory cmdlets not set."
        }
    }
}
