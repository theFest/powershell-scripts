function Send-SimulatedKey {
    <#
    .SYNOPSIS
    Simulates key presses and releases.

    .DESCRIPTION
    This function simulates key presses and releases using the SendKeys method from the System.Windows.Forms assembly. It supports a variety of keys and can handle modifier keys (Alt, Ctrl, Shift) as well.

    .EXAMPLE
    Send-SimulatedKey -Key F1

    .NOTES
    v0.4.2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Specifies the key to be simulated")]
        [ValidateSet("Enter", "Backspace", "Tab", "Escape", `
                "Insert", "Shift", "Delete", "Home", "End", "PageUp", "PageDown", `
                "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "PrintScreen", "PauseBreak", `
                "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12")]
        [Alias("k")]
        [string]$Key,
    
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, HelpMessage = "Action to be performed on the key")]
        [ValidateSet("Press", "Release")]
        [Alias("a")]
        [string]$Action = "Press",
    
        [Parameter(Mandatory = $false, HelpMessage = "Number of times to repeat the key action, must be an integer between 1 and 60")]
        [ValidateRange(1, 60)]
        [Alias("r")]
        [int]$Repeat = 1,
    
        [Parameter(Mandatory = $false, HelpMessage = "Modifier keys to be held during the key action, can be an array")]
        [ValidateSet("Alt", "Ctrl", "Shift")]
        [Alias("m")]
        [string[]]$Modifiers = @()
    )
    Add-Type -AssemblyName System.Windows.Forms
    $ModifiersMap = @{
        "Alt"   = "%"
        "Ctrl"  = "^"
        "Shift" = "+"
    }
    $KeyMap = @{
        "Enter"       = "~"
        "Backspace"   = "{BACKSPACE}"
        "Tab"         = "{TAB}"
        "Escape"      = "{ESC}"
        "Insert"      = "{INSERT}"
        "Delete"      = "{DELETE}"
        "Home"        = "{HOME}"
        "End"         = "{END}"
        "PageUp"      = "{PGUP}"
        "PageDown"    = "{PGDN}"
        "ArrowUp"     = "{UP}"
        "ArrowDown"   = "{DOWN}"
        "ArrowLeft"   = "{LEFT}"
        "ArrowRight"  = "{RIGHT}"
        "PrintScreen" = "{PRTSC}"
        "PauseBreak"  = "{BREAK}"
        "F1"          = "{F1}"
        "F2"          = "{F2}"
        "F3"          = "{F3}"
        "F4"          = "{F4}"
        "F5"          = "{F5}"
        "F6"          = "{F6}"
        "F7"          = "{F7}"
        "F8"          = "{F8}"
        "F9"          = "{F9}"
        "F10"         = "{F10}"
        "F11"         = "{F11}"
        "F12"         = "{F12}"
    }
    $ModifiersNotation = ""
    foreach ($Modifier in $Modifiers) {
        $ModifiersNotation += $ModifiersMap[$Modifier]
    }
    $SendKeysKey = $KeyMap[$Key]
    $SendKeysSequence = $ModifiersNotation + $SendKeysKey
    switch ($Action) {
        "Press" {
            for ($i = 0; $i -lt $Repeat; $i++) {
                [System.Windows.Forms.SendKeys]::SendWait($SendKeysSequence)
            }
        }
        "Release" {
            for ($i = 0; $i -lt $Repeat; $i++) {
                [System.Windows.Forms.SendKeys]::SendWait($SendKeysSequence)
            }
        }
    }
}
