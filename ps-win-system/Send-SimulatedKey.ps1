Function Send-SimulatedKey {
    <#
    .SYNOPSIS
    This function sends keyboard keys to the active window using the .NET framework's System.Windows.Forms.SendKeys class.
    
    .DESCRIPTION
    This function allows you to send keyboard keys to the active window in a controlled manner.
    You can specify the key to be sent, the action (press or release), the number of times to repeat the action, and the key modifiers to be used (Alt, Ctrl, or Shift).
    
    .PARAMETER Key
    Mandatory - specifies the key to be sent. The valid values are predefined in ValidateSet option.
    .PARAMETER Action
    NotMandatory - the action to be performed on the key. The valid values are "Press" and "Release". If not specified, the default value is "Press".
    .PARAMETER Repeat
    NotMandatory - number of times to repeat the action. The value must be in the range of 1 to 60. If not specified, the default value is 1.
    .PARAMETER Modifiers
    NotMandatory - specifies the key modifiers to be used when sending the key. The valid values are "Alt", "Ctrl", and "Shift".
    
    .EXAMPLE
    Send-SimulatedKey -Key "Enter" -Repeat 5
    Send-SimulatedKey -Key "Tab" -Modifiers "Ctrl"
    Send-SimulatedKey -Key "Shift" -Action "Release"
    Send-SimulatedKey -Key "F5" -Modifiers "Ctrl", "Alt" -Repeat 3
    Send-SimulatedKey -Key "Tab" -Action "Press" -Repeat 2 -Modifiers @("Shift")
    Send-SimulatedKey -Key "Enter" -Repeat 1 ; Read-Host "I will autocomplete Hosts input by adding 'ENTER'"
    
    .NOTES
    v0.1.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [ValidateSet("Enter", "Backspace", "Tab", "Escape", `
                "Insert", "Shift", "Delete", "Home", "End", "PageUp", "PageDown", `
                "ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight", "PrintScreen", "PauseBreak", `
                "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12")]
        [string]$Key,
    
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, Position = 1)]
        [ValidateSet("Press", "Release")]
        [string]$Action = "Press",
    
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 2)]
        [ValidateRange(1, 60)]
        [int]$Repeat = 1,
    
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 3)]
        [ValidateSet("Alt", "Ctrl", "Shift")]
        [string[]]$Modifiers = @()
    )
    Add-Type -AssemblyName System.Windows.Forms
    switch ($Action) {
        "Press" {
            for ($i = 0; $i -lt $Repeat; $i++) {
                foreach ($Modifier in $Modifiers) {
                    [System.Windows.Forms.SendKeys]::SendWait("+$Modifier")
                }
                [System.Windows.Forms.SendKeys]::SendWait("$Key")
                foreach ($Modifier in $Modifiers) {
                    [System.Windows.Forms.SendKeys]::SendWait("-$Modifier")
                }
            }
        }
        "Release" {
            for ($i = 0; $i -lt $Repeat; $i++) {
                [System.Windows.Forms.SendKeys]::SendWait("-$Key")
            }
        }
    }
}