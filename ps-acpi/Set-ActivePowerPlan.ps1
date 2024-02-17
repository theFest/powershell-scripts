Function Set-ActivePowerPlan {
    <#
    .SYNOPSIS
    Sets the active power plan on a Windows system.

    .DESCRIPTION
    This function allows you to set the active power plan on a Windows system, you can either choose from the available power plans or specify the GUID of the power plan directly.

    .PARAMETER PlanGuid
    Specifies the GUID of the power plan to set as active.
    .PARAMETER ListAvailable
    Lists the available power plans along with their details.
    .PARAMETER ShowDetails
    Shows detailed information about available power plans when listing them.

    .EXAMPLE
    Set-ActivePowerPlan -ListAvailable -ShowDetails
    Set-ActivePowerPlan -PlanGuid "f5d358d9-3705-4965-b21a-0a482b67bd74"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Specify the GUID of the power plan to set as active")]
        [string]$PlanGuid,

        [Parameter(Mandatory = $false, HelpMessage = "List available power plans")]
        [switch]$ListAvailable,

        [Parameter(Mandatory = $false, HelpMessage = "Show detailed information about available power plans")]
        [switch]$ShowDetails
    )
    BEGIN {
        Write-Verbose -Message "Setting Active Power Plan..."
        if ($ListAvailable) {
            Write-Host "Getting Power Plans..." -ForegroundColor Cyan
            $PowerPlans = Get-CimInstance -Namespace root/cimv2/power -ClassName Win32_PowerPlan
            if ($null -eq $PowerPlans) {
                Write-Warning -Message "No power plans found!"
                return
            }
            Write-Host "Available Power Plans:" -ForegroundColor Cyan
            $NumberedPlans = $PowerPlans | ForEach-Object {
                [PSCustomObject]@{
                    Number      = $script:i++
                    Guid        = $_.InstanceID -replace '.*\{(.+?)\}.*', '$1'
                    PlanName    = $_.ElementName
                    Description = $_.Description
                    IsActive    = $_.IsActive
                }
            }
            $NumberedPlans | Format-Table -AutoSize
            if ($ShowDetails) {
                $NumberedPlans | ForEach-Object {
                    Write-Host ("Details for Power Plan {0}:" -f $_.Number) -ForegroundColor Cyan
                    $_ | Format-List | Out-String | Write-Host
                    Write-Host ('-' * 40) -ForegroundColor Cyan
                }
            }
            $SelectedNumber = Read-Host "Enter the number of the Power Plan you want to set as active"
            $SelectedPowerPlan = $NumberedPlans | Where-Object { $_.Number -eq $SelectedNumber }
            if (-not $SelectedPowerPlan) {
                Write-Host "Invalid selection. Setting active plan operation canceled!" -ForegroundColor Yellow
                return
            }
            $PlanGuid = $SelectedPowerPlan.Guid
        }
    }
    PROCESS {
        try {
            powercfg /s $PlanGuid
            Write-Host "Active power plan set to: $PlanGuid" -ForegroundColor DarkCyan
        }
        catch {
            Write-Error -Message "Error setting active power plan: $_"
        }
    }
    END {
        Write-Verbose -Message "Completed"
    }
}
