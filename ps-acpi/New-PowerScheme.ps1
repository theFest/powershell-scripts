Function New-PowerScheme {
    <#
    .SYNOPSIS
    Creates a new power plan by duplicating an existing power scheme.

    .DESCRIPTION
    This function creates a new power plan by duplicating an existing power scheme based on the specified power scheme GUID, then renames the new power plan with the provided name.

    .PARAMETER PlanName
    Specifies the name for the new power plan.

    .PARAMETER powerSchemeGuid
    Specifies the base power scheme GUID to duplicate from, default value is "381b4222-f694-41f0-9685-ff5bb260df2e".
    "381b4222-f694-41f0-9685-ff5bb260df2e" == Balanced
    "a1841308-3541-4fab-bc81-f71556f20b4a" == Power saver
    "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" == High performance

    .EXAMPLE
    New-PowerScheme -PlanName "your_plan_name"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specify the name for the new power plan")]
        [string]$PlanName,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the base power scheme GUID to duplicate from")]
        [ValidateSet("381b4222-f694-41f0-9685-ff5bb260df2e", "a1841308-3541-4fab-bc81-f71556f20b4a", "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c")]
        [string]$PowerSchemeGuid = "381b4222-f694-41f0-9685-ff5bb260df2e"
    )
    try {
        $NewPlanGuid = [guid]::NewGuid().ToString()
        $CreatePlanCommand = "powercfg -duplicatescheme $PowerSchemeGuid $NewPlanGuid"
        Invoke-Expression -Command $CreatePlanCommand
        $RenamePlanCommand = "powercfg -changename $NewPlanGuid $PlanName"
        Invoke-Expression -Command $RenamePlanCommand
        Write-Host "New power plan '$PlanName' created with GUID: $NewPlanGuid" -ForegroundColor Green
    }
    catch {
        Write-Error -Message "Error: $_"
    }
    finally {
        $ListPlanCommand = "powercfg /list"
        Invoke-Expression -Command $ListPlanCommand
    }
}
