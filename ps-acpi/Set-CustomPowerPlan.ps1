Function Set-CustomPowerPlan {
    <#
    .SYNOPSIS
    Sets a custom power plan with specified parameters.

    .DESCRIPTION
    This function duplicates the current active power plan, changes its name, and applies custom power settings.

    .PARAMETER NewPlanName
    The name for the new custom power plan.
    .PARAMETER PowerButtonOnBattery
    The action to take when the power button is pressed on battery.
    Options: 1 - Do nothing, 2 - Sleep, 3 - Hibernate, 4 - Shut down, 5 - Turn off the display, 6 - Log off, 7 - Switch user.
    .PARAMETER PowerButtonPluggedIn
    The action to take when the power button is pressed while plugged in.
    Options: 1 - Do nothing, 2 - Sleep, 3 - Hibernate, 4 - Shut down, 5 - Turn off the display, 6 - Log off, 7 - Switch user.
    .PARAMETER SleepButtonOnBattery
    The action to take when the sleep button is pressed on battery.
    Options: 0 - Do nothing, 1 - Sleep, 2 - Hibernate, 3 - Shut down, 4 - Turn off the display, 5 - Log off, 6 - Switch user, 7 - Disconnect session.
    .PARAMETER SleepButtonPluggedIn
    The action to take when the sleep button is pressed while plugged in.
    Options: 0 - Do nothing, 1 - Sleep, 2 - Hibernate, 3 - Shut down, 4 - Turn off the display, 5 - Log off, 6 - Switch user, 7 - Disconnect session.
    .PARAMETER LidClosedOnBattery
    The action to take when the laptop lid is closed on battery.
    Options: 0 - Do nothing, 1 - Sleep, 2 - Hibernate, 3 - Shut down, 4 - Turn off the display, 5 - Log off, 6 - Switch user, 7 - Disconnect session.
    .PARAMETER LidClosedPluggedIn
    The action to take when the laptop lid is closed while plugged in.
    Options: 0 - Do nothing, 1 - Sleep, 2 - Hibernate, 3 - Shut down, 4 - Turn off the display, 5 - Log off, 6 - Switch user, 7 - Disconnect session.
    .PARAMETER TurnOffDisplayOnBattery
    The time, in minutes, before turning off the display on battery.
    .PARAMETER TurnOffDisplayPluggedIn
    The time, in minutes, before turning off the display while plugged in.
    .PARAMETER SleepModeOnBattery
    The time, in minutes, before entering sleep mode on battery.
    .PARAMETER SleepModePluggedIn
    The time, in minutes, before entering sleep mode while plugged in.
    
    .EXAMPLE
    Set-CustomPowerPlan -NewPlanName "your_plan_name"
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$NewPlanName,

        [Parameter(Mandatory = $false)]
        [ValidateSet(1, 2, 3, 4, 5, 6, 7)]
        [int]$PowerButtonOnBattery = 3,

        [Parameter(Mandatory = $false)]
        [ValidateSet(1, 2, 3, 4, 5, 6, 7)]
        [int]$PowerButtonPluggedIn = 3,

        [Parameter(Mandatory = $false)]
        [ValidateSet(0, 1, 2, 3, 4, 5, 6, 7)]
        [int]$SleepButtonOnBattery = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet(0, 1, 2, 3, 4, 5, 6, 7)]
        [int]$SleepButtonPluggedIn = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet(0, 1, 2, 3, 4, 5, 6, 7)]
        [int]$LidClosedOnBattery = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet(0, 1, 2, 3, 4, 5, 6, 7)]
        [int]$LidClosedPluggedIn = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet(0, 1, 2, 3, 4, 5, 6, 7)]
        [int]$TurnOffDisplayOnBattery = 15,

        [Parameter(Mandatory = $false)]
        [ValidateSet(0, 1, 2, 3, 4, 5, 6, 7)]
        [int]$TurnOffDisplayPluggedIn = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet(0, 1, 2, 3, 4, 5, 6, 7)]
        [int]$SleepModeOnBattery = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet(0, 1, 2, 3, 4, 5, 6, 7)]
        [int]$SleepModePluggedIn = 0
    )
    Write-Verbose -Message "Get currently active plan..."
    $OriginalPlan = $(powercfg -getactivescheme).Split()[3]
    Write-Verbose -Message "Duplicating current active plan..."
    $Duplicate = powercfg -duplicatescheme $OriginalPlan
    Write-Verbose -Message "Changing name of duplicated plan"
    powercfg -changename ($Duplicate).Split()[3] "$NewPlanName"
    Write-Verbose -Message "Setting new plan as active plan..."
    powercfg -setactive ($Duplicate).Split()[3]
    Write-Verbose -Message "Get the new plan..."
    $NewPlan = $(powercfg -getactivescheme).Split()[3]
    $PowerGUID = '4f971e89-eebd-4455-a8de-9e59040e7347'
    $PowerButtonGUID = '7648efa3-dd9c-4e3e-b566-50f929386280'
    $LidClosedGUID = '5ca83367-6e45-459f-a27b-476b1d01c936'
    $SleepGUID = '238c9fa8-0aad-41ed-83f4-97be242c8f20'
    function SettingExists ($Plan, $SubGroup, $Setting) {
        $Result = powercfg -query $Plan $SubGroup $Setting 2>&1
        return ($Result -notlike "*does not exist*")
    }
    Write-Verbose -Message "POWER BUTTON part..."
    if (SettingExists $NewPlan $PowerGUID $PowerButtonGUID) {
        cmd /c "powercfg /setdcvalueindex $NewPlan $PowerGUID $PowerButtonGUID $PowerButtonOnBattery"
        cmd /c "powercfg /setacvalueindex $NewPlan $PowerGUID $PowerButtonGUID $PowerButtonPluggedIn"
    }
    else {
        Write-Host "Power button settings do not exist for the specified plan"
    }
    Write-Verbose -Message "SLEEP BUTTON part..."
    if (SettingExists $NewPlan $PowerGUID $SleepGUID) {
        cmd /c "powercfg /setdcvalueindex $NewPlan $PowerGUID $SleepGUID $SleepButtonOnBattery"
        cmd /c "powercfg /setacvalueindex $NewPlan $PowerGUID $SleepGUID $SleepButtonPluggedIn"
    }
    else {
        Write-Host "Sleep button settings do not exist for the specified plan"
    }
    Write-Verbose -Message "LID CLOSED part..."
    if (SettingExists $NewPlan $PowerGUID $LidClosedGUID) {
        cmd /c "powercfg /setdcvalueindex $NewPlan $PowerGUID $LidClosedGUID $LidClosedOnBattery"
        cmd /c "powercfg /setacvalueindex $NewPlan $PowerGUID $LidClosedGUID $LidClosedPluggedIn"
    }
    else {
        Write-Host "Lid closed settings do not exist for the specified plan"
    }
    Write-Verbose -Message "Plan general settings"
    powercfg -change -monitor-timeout-dc $TurnOffDisplayOnBattery
    powercfg -change -monitor-timeout-ac $TurnOffDisplayPluggedIn
    powercfg -change -standby-timeout-ac $SleepModePluggedIn
    powercfg -change -standby-timeout-dc $SleepModeOnBattery
    cmd /c "powercfg /s $NewPlan"
}
