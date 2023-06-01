Function CheckBox {
    <#
    .SYNOPSIS
    Short description
    
    .DESCRIPTION
    Long description
    
    .EXAMPLE
    An example
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Form]
        $ParentForm,

        [Parameter(Mandatory = $true)]
        [int]
        $X,

        [Parameter(Mandatory = $true)]
        [int]
        $Y,

        [Parameter(Mandatory = $true)]
        [int]
        $Width,

        [Parameter(Mandatory = $true)]
        [int]
        $Height,

        [Parameter(Mandatory = $true)]
        [string]
        $Text,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Left", "Center", "Right", "TopLeft", "TopRight", "BottomLeft", "BottomRight")]
        [string]
        $TextAlign = "Left",

        [Parameter(Mandatory = $false)]
        [ValidateSet("TopLeft", "TopCenter", "TopRight", "MiddleLeft", "MiddleCenter", "MiddleRight", "BottomLeft", "BottomCenter", "BottomRight")]
        [string]
        $CheckAlign = "TopLeft",

        [Parameter(Mandatory = $false)]
        [ValidateSet("TopLeft", "TopRight", "BottomLeft", "BottomRight")]
        [string]
        $Alignment = "TopLeft",

        [Parameter(Mandatory = $false)]
        [switch]
        $Checked,

        [Parameter(Mandatory = $false)]
        [switch]
        $Enabled,

        [Parameter(Mandatory = $false)]
        [bool]
        $AutoSize = $false,

        [Parameter(Mandatory = $false)]
        [bool]
        $Visible = $true,

        [Parameter(Mandatory = $false)]
        [string]
        $ToolTipText = "",

        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Flat", "Popup")]
        [string]
        $Appearance = "None",

        [Parameter(Mandatory = $false)]
        [System.Windows.Forms.TextImageRelation]
        $TextImageRelation = "Overlay",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Normal", "HotTrack", "Flat", "Popup")]
        [System.Windows.Forms.FlatStyle]
        $FlatStyle = "Standard",

        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Auto", "Hand", "Help", "AppStarting", "WaitCursor")]
        [string]
        $Cursor = "None"
    )
    BEGIN {
        Add-Type -AssemblyName System.Windows.Forms
    }
    PROCESS {
        $CheckBox = New-Object System.Windows.Forms.CheckBox
        $CheckBox.Location = New-Object System.Drawing.Point($X, $Y)
        $CheckBox.Size = New-Object System.Drawing.Size($Width, $Height)
        $CheckBox.Text = $Text
        $CheckBox.TextAlign = [System.Drawing.ContentAlignment]::$TextAlign
        $CheckBox.FlatStyle = [System.Windows.Forms.FlatStyle]::$FlatStyle
        $CheckBox.Cursor = $Cursor
        $CheckBox.Parent = $ParentForm
        $CheckBox.Enabled = $Enabled
        $CheckBox.CheckAlign = $CheckAlign
        $CheckBox.AutoSize = $AutoSize
        $CheckBox.Visible = $Visible
        $CheckBox.Appearance = [System.Windows.Forms.Appearance]::$Appearance
        switch ($Alignment) {
            "TopLeft" {
                $CheckBox.TextAlign = "TopLeft"
            }
            "TopRight" {
                $CheckBox.TextAlign = "TopRight"
            }
            "BottomLeft" {
                $CheckBox.TextAlign = "BottomLeft"
            }
            "BottomRight" {
                $CheckBox.TextAlign = "BottomRight"
            }
        }
        if ($CheckState -eq "Basic") {
            $CheckBox.ThreeState = $true
        }
        $CheckBox.CheckState = [System.Windows.Forms.CheckState]::$CheckState
        if ($Checked) {
            $CheckBox.Checked = $true
        }
        if (-not $Enabled) {
            $CheckBox.Enabled = $false
        }
        if ($ToolTipText -ne "") {
            $ToolTip = New-Object System.Windows.Forms.ToolTip
            $ToolTip.SetToolTip($CheckBox, $ToolTipText)
        }
        $CheckBox.TextImageRelation = $TextImageRelation
        $ParentForm.Controls.Add($CheckBox)
    }
    END {
        return $CheckBox
        $ParentForm.Controls.Add($CheckBox)
        $CheckBox.Dispose()
    }
}
