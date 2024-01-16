Function Switch-PowerPlan {
    <#
    .SYNOPSIS
    Allows you to manage power plans on your system.

    .DESCRIPTION
    This function provides options to switch between power plans, list available power plans, and display the current power plan.

    .PARAMETER Action
    Specifies the action to perform, valid values are "Switch" (default), "List", or "ShowCurrent".
    .PARAMETER PowerPlan
    Name of the power plan to switch to, valid values are "Balanced" (default), "High performance", "Power saver", or "Ultimate Performance".
    .PARAMETER ListPowerPlans
    Switch to list all available power plans.
    .PARAMETER ShowCurrentPlan
    Switch to display the current power plan.

    .EXAMPLE
    Switch-PowerPlan -Action "Switch" -PowerPlan "Balanced"
    Switch-PowerPlan -Action "List"
    Switch-PowerPlan -Action "ShowCurrent"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Switch", "List", "ShowCurrent")]
        [string]$Action = "Switch",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Balanced", "High performance", "Power saver", "Ultimate Performance")]
        [string]$PowerPlan,

        [Parameter(Mandatory = $false)]
        [switch]$ListPowerPlans,

        [Parameter(Mandatory = $false)]
        [switch]$ShowCurrentPlan
    )
    switch ($Action) {
        "List" {
            $PowerPlans = Get-CimInstance -Namespace root\cimv2\power -ClassName win32_PowerPlan | Select-Object -ExpandProperty ElementName
            Write-Host "Available Power Plans:"
            $PowerPlans | ForEach-Object {
                $index = [array]::IndexOf($PowerPlans, $_)
                Write-Host " $index. $_"
            }
            break
        }
        "ShowCurrent" {
            $CurrentPlan = powercfg /query SCHEME_CURRENT SUB_SLEEP STANDBYIDLE
            $CurrentPlanIndex = $CurrentPlan -replace '.*Power Setting Index: (\d+)', '$1'
            Write-Host "Current Power Plan: $CurrentPlanIndex"
            break
        }
        "Switch" {
            if (-not $PowerPlan) {
                $PowerPlans = Get-CimInstance -Namespace root\cimv2\power -ClassName win32_PowerPlan | Select-Object -ExpandProperty ElementName
                Write-Host "Available Power Plans:"
                $PowerPlans | ForEach-Object {
                    $index = [array]::IndexOf($PowerPlans, $_)
                    Write-Host " $index. $_"
                }
                $Selection = Read-Host "Enter the number of the power plan to $Action"
                if ($Selection -ge 0 -and $Selection -lt $PowerPlans.Count) {
                    $PowerPlan = $PowerPlans[$Selection]
                }
                else {
                    Write-Host "Invalid selection. Please choose a number from the available options."
                    return
                }
            }
            $SelectedPowerPlan = Get-CimInstance -Namespace root\cimv2\power -ClassName win32_PowerPlan -Filter "ElementName = '$PowerPlan'"
            powercfg /setactive $SelectedPowerPlan.InstanceID.Replace("Microsoft:PowerPlan\{", "").Replace("}", "")
            Write-Host "Switched to the power plan: $PowerPlan"
            break
        }
        default {
            Write-Host "Invalid action. Please choose from 'Switch', 'List', or 'ShowCurrent'."
            break
        }
    }
}
