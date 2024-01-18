Function Get-ServicesStartupType {
    <#
    .SYNOPSIS
    Get services based on startup type, scope, and optional criteria.

    .DESCRIPTION
    This function retrieves services based on specified startup type, scope, and optional criteria. It provides detailed information about each service and a summary based on the start types.

    .PARAMETER StartType
    Specifies the startup type of services to filter. Valid values are "Automatic", "Manual", "Disabled", or "AllStartTypes", default value is "Automatic".
    .PARAMETER Scope
    Specifies the scope of services to filter. Valid values are "LocalMachine" or "AllScopes", default value is "LocalMachine".
    .PARAMETER CanPauseAndContinue
    Switch parameter to include only services that support pause and continue operations.

    .EXAMPLE
    Get-ServicesStartupType -StartType Automatic -Scope AllScopes -CanPauseAndContinue

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("Automatic", "Manual", "Disabled", "AllStartTypes")]
        [string]$StartType = "Automatic",

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("LocalMachine", "AllScopes")]
        [string]$Scope = "LocalMachine",

        [Parameter(Mandatory = $false)]
        [switch]$CanPauseAndContinue
    )
    BEGIN {
        $ServiceObjects = @()
    }
    PROCESS {
        $Services = Get-Service
        $FilteredServices = $Services | Where-Object {
            ($_.StartType -eq $StartType -or $StartType -eq "AllStartTypes") -and
            ($CanPauseAndContinue.IsPresent -eq $false -or $_.CanPauseAndContinue)
        }
        foreach ($Service in $FilteredServices) {
            $ServiceObjects += [PSCustomObject]@{
                Path                = $Service.DisplayName
                Name                = $Service.ServiceName
                StartType           = $Service.StartType
                CanPauseAndContinue = $Service.CanPauseAndContinue
                Status              = $Service.Status
                Description         = $Service.Description
                DisplayName         = $Service.DisplayName
                Scope               = $Scope
                Type                = "Service"
            }
        }
    }
    END {
        if ($ServiceObjects.Count -eq 0) {
            Write-Warning "No services found with the specified criteria."
        }
        else {
            Write-Output -InputObject $ServiceObjects
            Write-Host "`nService Information Summary" -ForegroundColor Green
            $ServiceObjects | Group-Object StartType | ForEach-Object {
                "$($_.Name) Start Type: $($_.Count)"
            }
        }
    }
}
