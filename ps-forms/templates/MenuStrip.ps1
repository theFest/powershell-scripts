Function MenuStrip {
    <#
    .SYNOPSIS
    n/a atm
    
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

        [Parameter(Mandatory = $true, Position = 1)]
        [int]
        $X,

        [Parameter(Mandatory = $true, Position = 2)]
        [int]
        $Y,

        [Parameter(Mandatory = $true, Position = 3)]
        [int]
        $Width,

        [Parameter(Mandatory = $true, Position = 4)]
        [int]
        $Height,

        [Parameter(Mandatory = $false)]
        [string]
        $Name,

        [Parameter(Mandatory = $false)]
        [ValidateSet("System", "Professional", "Standard", "Custom")]
        [string]
        $Renderer = "System",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Horizontal", "Vertical")]
        [string]
        $Orientation = "Horizontal",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [int]
        $Opacity = 100,

        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "DropDown", "MdiWindowList", "MenuItems", "Shortcuts")]
        [string[]]
        $ShowShortcutKeys = @(),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Drawing.Color]
        $BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Drawing.Color]
        $ForeColor = [System.Drawing.Color]::FromArgb(0, 0, 0),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Windows.Forms.Padding]
        $Margin = [System.Windows.Forms.Padding]::Empty,

        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Default", "MDIList")]
        [string]
        $MergeType = "None",

        [Parameter(Mandatory = $false)]
        [System.Windows.Forms.MenuStrip]
        $MergeTarget,

        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Top", "Bottom")]
        [string]
        $Dock = "None",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [System.Windows.Forms.ToolStripItem[]]
        $MenuItems,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Visible,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [switch]
        $Enabled
    )
    BEGIN {
        Add-Type -AssemblyName System.Windows.Forms
    }
    PROCESS {
        $MenuStrip = New-Object System.Windows.Forms.MenuStrip
        $MenuStrip.Name = $Name
        $MenuStrip.Top = $Top
        $MenuStrip.Left = $Left
        $MenuStrip.Location = New-Object System.Drawing.Point($X, $Y)
        $MenuStrip.Size = New-Object System.Drawing.Size($Width, $Height)
        $MenuStrip.Dock = $Dock
        $MenuStrip.Margin = $Margin
        $MenuStrip.BackColor = $BackColor
        $MenuStrip.ForeColor = $ForeColor
        $MenuStrip.RenderMode = $RenderMode
        $MenuStrip.ShowShortcutKeys = [System.Windows.Forms.MenuStrip+ShortcutKeys]::None
        if ($MenuItems) {
            foreach ($item in $MenuItems) {
                $MenuStrip.Items.Add($item)
            }
        }
        foreach ($key in $ShowShortcutKeys) {
            $MenuStrip.ShowShortcutKeys = $MenuStrip.ShowShortcutKeys -bor ([System.Windows.Forms.MenuStrip+ShortcutKeys]$key)
        }
        $MenuStrip.Visible = $Visible
        $MenuStrip.Enabled = $Enabled
        if ($MergeTarget) {
            $MenuStrip.MergeType = [System.Windows.Forms.MergeType]::$MergeType
            $MenuStrip.MergeTarget = $MergeTarget
        }
    }
    END {
        $ParentForm.Controls.Add($MenuStrip)
        return $MenuStrip
        $MenuStrip.Dispose()
        Remove-Variable -Name MenuStrip -Force -Verbose
    }
}
