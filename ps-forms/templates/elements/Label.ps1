Function Label {
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
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Windows.Forms.Form]
        $ParentForm,

        [Parameter(Mandatory = $true, Position = 0)]
        [int]
        $X,

        [Parameter(Mandatory = $true, Position = 0)]
        [int]
        $Y,

        [Parameter(Mandatory = $true, Position = 0)]
        [int]
        $Width,

        [Parameter(Mandatory = $true, Position = 0)]
        [int]
        $Height,

        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Text,

        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("TopLeft", "TopCenter", "TopRight", "MiddleLeft", "MiddleCenter", "MiddleRight", "BottomLeft", "BottomCenter", "BottomRight")]
        [string]
        $Align = "TopLeft",

        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("None", "Horizontal", "Vertical", "Both")]
        [string]
        $TextAlign = "Left",

        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("Single", "FixedSingle", "Fixed3D", "FixedDialog", "Sizable", "FixedToolWindow", "SizableToolWindow")]
        [string]
        $BorderStyle = "FixedSingle",

        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateRange(1, 100)]
        [int]
        $FontSize = 10,

        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("Regular", "Bold", "Italic", "Underline", "Strikeout", "Bold, Italic", "Bold, Underline", "Bold, Strikeout", "Italic, Underline", "Italic, Strikeout", "Underline, Strikeout", "Bold, Italic, Underline", "Bold, Italic, Strikeout", "Bold, Underline, Strikeout", "Italic, Underline, Strikeout", "Bold, Italic, Underline, Strikeout")]
        [string]
        $FontStyle = "Regular",

        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("Arial", "Calibri", "Consolas", "Courier New", "Times New Roman", "Verdana")]
        [string]
        $FontFamily = "Arial",

        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("None", "AutoEllipsis", "EndEllipsis", "PathEllipsis")]
        [string]
        $TextEllipsis = "None",

        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("None", "Flat", "Raised", "Sunken")]
        [string]
        $FlatStyle = "None",

        [Parameter(Mandatory = $false, Position = 0)]
        [System.Drawing.Color]
        $ForeColor,

        [Parameter(Mandatory = $false, Position = 0)]
        [System.Drawing.Color]
        $BackColor,

        [Parameter(Mandatory = $false, Position = 0)]
        [switch]
        $AutoSize,

        [Parameter(Mandatory = $false, Position = 0)]
        [switch]
        $UseMnemonic
    )
    BEGIN {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
    }
    PROCESS {
        $Label = New-Object System.Windows.Forms.Label
        $Label.Location = New-Object System.Drawing.Point($X, $Y)
        $Label.Size = New-Object System.Drawing.Size($Width, $Height)
        $Label.Text = $Text
        $Label.AutoSize = $AutoSize
        $Label.BackColor = $BackColor
        $Label.ForeColor = $ForeColor
        $Label.UseMnemonic = $UseMnemonic
        $Label.AutoEllipsis = $TextEllipsis -ne "None"
        switch ($Align) {
            "TopLeft" { $Label.TextAlign = [System.Drawing.ContentAlignment]::TopLeft }
            "TopCenter" { $Label.TextAlign = [System.Drawing.ContentAlignment]::TopCenter }
            "TopRight" { $Label.TextAlign = [System.Drawing.ContentAlignment]::TopRight }
            "MiddleLeft" { $Label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft }
            "MiddleCenter" { $Label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter }
            "MiddleRight" { $Label.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight }
            "BottomLeft" { $Label.TextAlign = [System.Drawing.ContentAlignment]::BottomLeft }
            "BottomCenter" { $Label.TextAlign = [System.Drawing.ContentAlignment]::BottomCenter }
            "BottomRight" { $Label.TextAlign = [System.Drawing.ContentAlignment]::BottomRight }
        }
        $Label.Font = New-Object System.Drawing.Font($FontFamily, $FontSize, $FontStyle)
    }
    END {
        $ParentForm.Controls.Add($Label)
        return $Label
        $Label.Dispose()
    }
}
