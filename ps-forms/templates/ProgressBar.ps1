Function ProgressBar {
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
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [System.Windows.Forms.Form]
        $ParentForm,

        [Parameter(Mandatory = $true, Position = 0)]
        [int]
        $X,

        [Parameter(Mandatory = $true, Position = 0)]
        [int]
        $Y,

        [Parameter(Mandatory = $false, Position = 0)]
        [int]
        $Width = 300,

        [Parameter(Mandatory = $false, Position = 0)]
        [int]
        $Height = 20,

        [Parameter(Mandatory = $false, Position = 0)]
        [System.Drawing.Point]
        $Location = [System.Drawing.Point]::Empty,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Title,

        [Parameter(Mandatory = $true, Position = 1)]
        [switch]
        $Visible,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateRange(0, 100)]
        [int]
        $Minimum = 0,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateRange(0, 100)]
        [int]
        $Maximum = 100,

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateRange(0, 100)]
        [int]
        $Value = 0,

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet("Marquee", "Continuous", "Marquee")]
        [string]
        $Style = "Marquee",

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet("TopLeft", "TopRight", "BottomLeft", "BottomRight", "Center")]
        [string]
        $Alignment = "Center",

        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateRange(0, 10)]
        [int]
        $Padding = 5,

        [Parameter(Mandatory = $false, Position = 3)]
        [switch]
        $ShowPercent,

        [Parameter(Mandatory = $false, Position = 3)]
        [switch]
        $ShowValue,

        [Parameter(Mandatory = $false, Position = 4)]
        [switch]
        $ShowAnimation,

        [Parameter(Mandatory = $false, Position = 5)]
        [System.Drawing.Font]
        $Font = [System.Drawing.SystemFonts]::DefaultFont,

        [Parameter(Mandatory = $false, Position = 6)]
        [System.Drawing.Color]
        $ForeColor = [System.Drawing.SystemColors]::ControlText,

        [Parameter(Mandatory = $false, Position = 6)]
        [System.Drawing.Color]
        $BackColor = [System.Drawing.SystemColors]::Control
    )
    BEGIN {
        Write-Verbose -Message "Loading assembly..."
        Add-Type -AssemblyName System.Windows.Forms
    }
    PROCESS {
        Write-Verbose -Message "Creating a new ProgressBar object and set its properties"
        $ProgressBar = New-Object System.Windows.Forms.ProgressBar
        $ProgressBar.Text = $Title
        $ProgressBar.Style = $Style
        $ProgressBar.Font = $Font
        $ProgressBar.ForeColor = $ForeColor
        $ProgressBar.BackColor = $BackColor
        $ProgressBar.Minimum = $Minimum
        $ProgressBar.Maximum = $Maximum
        $ProgressBar.Value = $Value
        $ProgressBar.Visible = $Visible
        $ProgressBar.Location = New-Object System.Drawing.Point($X, $Y)
        $ProgressBar.Size = New-Object System.Drawing.Size($Width, $Height)
        Write-Verbose -Message "Adding ProgressBar object to the parent form or create a new form if no parent form was provided"
        if ($ParentForm) {
            $ParentForm.Controls.Add($ProgressBar)
        }
        else {
            $Form = New-Object System.Windows.Forms.Form
            $Form.Text = $Title
            $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
            $Form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
            $Form.ClientSize = New-Object System.Drawing.Size($Width, $Height + (2 * $Padding))
            $Form.Controls.Add($ProgressBar)
            $ParentForm = $Form
        }
        Write-Verbose -Message "Adding label to display progress information" 
        $Label = New-Object System.Windows.Forms.Label
        $Label.Font = $Font
        $Label.ForeColor = $ForeColor
        $Label.BackColor = $BackColor
        Write-Verbose -Message "Creating a Label object to display progress information if requested"  
        if ($ShowPercent -or $ShowValue) {
            $Label = New-Object System.Windows.Forms.Label
            $Label.AutoSize = $true
            $Label.Font = $Font
            $Label.ForeColor = $ForeColor
            $Label.BackColor = $BackColor
            Write-Verbose -Message "Position the Label object based on the Alignment parameter"  
            switch ($Alignment) {
                "TopLeft" { $Label.Location = New-Object System.Drawing.Point($Padding, $Padding) }
                "TopRight" { $Label.Location = New-Object System.Drawing.Point($Width - $Label.Width - $Padding, $Padding) }
                "BottomLeft" { $Label.Location = New-Object System.Drawing.Point($Padding, $Height - $Label.Height - $Padding) }
                "BottomRight" { $Label.Location = New-Object System.Drawing.Point($Width - $Label.Width - $Padding, $Height - $Label.Height - $Padding) }
                "Center" { $Label.Location = New-Object System.Drawing.Point(($Width - $Label.Width) / 2, ($Height - $Label.Height) / 2) }
            }
            Write-Verbose -Message "Adding the Label object to the parent form"   
            $ParentForm.Controls.Add($Label)
        }
        Write-Verbose -Message "Adding an animation to the ProgressBar object if requested"   
        if ($ShowAnimation) {
            $Animation = New-Object System.Windows.Forms.Timer
            $Animation.Interval = 50
            $Animation.add_Tick({ $ProgressBar.PerformStep() })
            $Animation.Start()
        }
        Write-Verbose -Message "Showing percent and/or value information if specified"
        if ($ShowPercent) {
            $Label.Text = "{0}%" -f [math]::Round(($ProgressBar.Value / $ProgressBar.Maximum) * 100)
        }
        if ($ShowValue) {
            if ($ShowPercent) {
                $Label.Text += " "
            }
            $Label.Text += "$($ProgressBar.Value) / $($ProgressBar.Maximum)"
        }
    }
    END {
        #$ParentForm.Controls.Add($ProgressBar)
        #return $ProgressBar
        #$ProgressBar.Dispose()
        if ($ParentForm) {
            $ProgressBar.Parent = $ParentForm
        }
        return $ProgressBar
    }
}