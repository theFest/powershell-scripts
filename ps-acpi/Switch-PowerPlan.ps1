function Switch-PowerPlan {
    <#
    .SYNOPSIS
    Allows you to manage power plans on your system.

    .DESCRIPTION
    This function provides options to switch between power plans, list available power plans, and display the current power plan.

    .EXAMPLE
    Switch-PowerPlan -Action "List"
    Switch-PowerPlan -Action "ShowCurrent"
    Switch-PowerPlan -Action "Switch" -PowerPlan "Balanced"

    .NOTES
    v0.1.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Action to perform")]
        [ValidateSet("Switch", "List", "ShowCurrent")]
        [string]$Action = "Switch",

        [Parameter(Mandatory = $false, HelpMessage = "Name of the power plan to switch to")]
        [ValidateSet("Balanced", "High performance", "Power saver", "Ultimate Performance")]
        [string]$PowerPlan
    )
    $Actions = @{
        "List"        = {
            $PowerPlans = Get-CimInstance -Namespace root\cimv2\power -ClassName win32_PowerPlan | Select-Object -Property ElementName, InstanceID
            if (-not $PowerPlans) {
                Write-Error "No power plans found on this system."
                return
            }
            Write-Host "Available Power Plans:" -ForegroundColor Green
            $PowerPlans | ForEach-Object {
                Write-Host " $($_.ElementName)"
            }
        }
        "ShowCurrent" = {
            $CurrentPlan = Get-CimInstance -Namespace root\cimv2\power -ClassName win32_PowerPlan | Where-Object { $_.IsActive -eq $true }
            if ($CurrentPlan) {
                Write-Host "Current Power Plan: $($CurrentPlan.ElementName)" -ForegroundColor Yellow
            }
            else {
                Write-Error "Unable to retrieve the current power plan."
            }
        }
        "Switch"      = {
            if (-not $PowerPlan) {
                $PowerPlans = Get-CimInstance -Namespace root\cimv2\power -ClassName win32_PowerPlan | Select-Object -Property ElementName, InstanceID
                if (-not $PowerPlans) {
                    Write-Error "No power plans found on this system."
                    return
                }
                Write-Host "Available Power Plans:" -ForegroundColor Green
                $PowerPlans | ForEach-Object {
                    Write-Host " $($_.ElementName)"
                }
                $Selection = Read-Host "Enter the name of the power plan to switch to"
                $PowerPlan = $Selection
            }
            $AvailablePlans = Get-CimInstance -Namespace root\cimv2\power -ClassName win32_PowerPlan | Select-Object -Property ElementName, InstanceID
            $TargetPlan = $AvailablePlans | Where-Object { $_.ElementName -eq $PowerPlan }
            if ($TargetPlan) {
                $InstanceId = $TargetPlan.InstanceID -replace "Microsoft:PowerPlan\\{", "" -replace "}", ""
                powercfg /setactive $InstanceId
                Write-Host "Switched to the power plan: $PowerPlan" -ForegroundColor Green
            }
            else {
                Write-Error "Power plan '$PowerPlan' not found!"
            }
        }
    }
    if ($Actions[$Action]) {
        $Actions[$Action].Invoke()
    }
    else {
        Write-Error "Invalid action specified. Please choose 'Switch', 'List', or 'ShowCurrent'."
    }
}
