Function Button {
    <#
    .SYNOPSIS
    Creates a new button control and adds it to a Windows Forms parent form.

    .DESCRIPTION
    Button function creates a button control with customizable properties and adds it to a specified Windows Forms parent form, it supports various parameters to configure the button's appearance, behavior, and event handling.

    .EXAMPLE
    An example

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Control]
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
        [string]
        $Name = "",

        [Parameter(Mandatory)]
        [System.EventHandler]
        $OnClick,

        [Parameter(Mandatory = $false)]
        [System.Drawing.Font]
        $Font = [System.Drawing.SystemFonts]::DefaultFont,

        [Parameter(Mandatory = $false)]
        [ValidateSet("TopLeft", "TopCenter", "TopRight", "MiddleLeft", "MiddleCenter", "MiddleRight", "BottomLeft", "BottomCenter", "BottomRight")]
        [string]
        $TextAlign = "MiddleCenter",

        [Parameter(Mandatory = $false)]
        [ValidateSet("TopLeft", "TopCenter", "TopRight", "MiddleLeft", "MiddleCenter", "MiddleRight", "BottomLeft", "BottomCenter", "BottomRight")]
        [string]
        $Alignment = "MiddleCenter",

        [Parameter(Mandatory = $false)]
        [System.Drawing.Color]
        $ForeColor = [System.Drawing.SystemColors]::ControlText,

        [Parameter(Mandatory = $false)]
        [System.Drawing.Color]
        $BackColor = [System.Drawing.SystemColors]::Control,

        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Flat", "Popup", "Standard", "System")]
        [string]
        $FlatStyle = "None",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Default", "OK", "Cancel", "Yes", "No", "Abort", "Retry", "Ignore")]
        [string]
        $DialogResult = "None",

        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Image", "ImageAboveText", "ImageBeforeText", "ImageOverlay", "ImageAndText")]
        [string]$ImageAlign = "None",

        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Top", "Bottom", "Right", "Left")]
        [string]
        $ImagePosition = "Left",

        [Parameter(Mandatory = $false)]
        [switch]
        $Enabled,

        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Help")]
        [string]
        $HelpButton = "None",

        [Parameter(Mandatory = $false)]
        [string]
        $ToolTipText,

        [Parameter(Mandatory = $false)]
        [switch]
        $UseMnemonic,

        [Parameter(Mandatory = $false)]
        [switch]
        $Visible
    )
    BEGIN {
        Add-Type -AssemblyName System.Windows.Forms
    }
    PROCESS {
        $Button = New-Object System.Windows.Forms.Button
        $Button.Location = New-Object System.Drawing.Point($X, $Y)
        $Button.Size = New-Object System.Drawing.Size($Width, $Height)
        $Button.Text = $Text
        $Button.TextAlign = $TextAlign
        $Button.Font = $Font
        $Button.Name = $Name
        $Button.ForeColor = $ForeColor
        $Button.BackColor = $BackColor
        $Button.FlatStyle = $FlatStyle
        $Button.DialogResult = $DialogResult
        $Button.Enabled = $Enabled
        $button.Visible = $Visible
        $Button.HelpButton = $HelpButton
        $Button.UseMnemonic = $UseMnemonic
        $Button.Anchor = $Alignment
        $Button.ImageAlign = $ImageAlign
        $Button.TextImageRelation = $ImagePosition
        $Button.add_Click($OnClick)
        if ($ToolTipText) {
            $ToolTip = New-Object System.Windows.Forms.ToolTip
            $ToolTip.SetToolTip($Button, $ToolTipText)
        }
        $ParentForm.Controls.Add($Button)
    }
    END {
        if ($ParentForm) {
            return $ParentForm.Controls[$ParentForm.Controls.Count - 1]
        }
        else {
            return $Button
        }
        $Button.Dispose()
    }
}