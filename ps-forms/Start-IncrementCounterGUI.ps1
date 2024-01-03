Function Start-IncrementCounterGUI {
    <#
    .SYNOPSIS
    Starts an Increment Counter Graphical User Interface (GUI).

    .DESCRIPTION
    This function initiates a GUI to increment and manage a counter visually.

    .PARAMETER Title
    NotMandatory - title of the GUI window.
    .PARAMETER Width
    NotMandatory - specifies the width of the GUI window.
    .PARAMETER Height
    NotMandatory - specifies the height of the GUI window.

    .EXAMPLE
    Start-IncrementCounterGUI -Title "FW IC Counter" -Width 600 -Height 400

    .NOTES
    v0.0.6
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "FW IC GUI",

        [Parameter(Mandatory = $false)]
        [int]$Width = 1366,

        [Parameter(Mandatory = $false)]
        [int]$Height = 768
    )
    BEGIN {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        $global:Counter = 0
    }
    PROCESS {
        $UpdateStatus = {
            param([string]$Message)
            $StatusLabel.Text = $Message
        }
        $SetCounter = {
            param([int]$Value)
            $global:Counter = $Value
            $LblCounter.Text = "Counter: $global:Counter"
        }
        $Form = New-Object System.Windows.Forms.Form
        $Form.Text = $Title
        $Form.Size = New-Object System.Drawing.Size($Width, $Height)
        $Form.StartPosition = "CenterScreen"
        $Form.BackColor = [System.Drawing.Color]::White
        $LblTitle = New-Object System.Windows.Forms.Label
        $LblTitle.Text = "Welcome to FW IC!"
        $LblTitle.AutoSize = $true
        $LblTitle.Location = New-Object System.Drawing.Point(20, 50)
        $LblCounter = New-Object System.Windows.Forms.Label
        $LblCounter.Text = "Counter: $global:Counter"
        $LblCounter.AutoSize = $true
        $LblCounter.Location = New-Object System.Drawing.Point(20, 100)
        $BtnIncrement = New-Object System.Windows.Forms.Button
        $BtnIncrement.Text = "Increment"
        $BtnIncrement.Location = New-Object System.Drawing.Point(20, 150)
        $BtnIncrement.Add_Click({
                & $SetCounter ($global:Counter + 1)
                & $UpdateStatus "Counter has been incremented: $global:Counter"
            })
        $BtnReset = New-Object System.Windows.Forms.Button
        $BtnReset.Text = "Reset"
        $BtnReset.Location = New-Object System.Drawing.Point(120, 150)
        $BtnReset.Add_Click({
                $Result = [System.Windows.Forms.MessageBox]::Show(
                    "Are you sure you want to reset the counter?", 
                    "Confirm Reset", "YesNo", "Question")
                if ($Result -eq "Yes") {
                    & $SetCounter 0
                    & $UpdateStatus "Counter has been reset"
                }
            })
        $Timer = New-Object System.Windows.Forms.Timer
        $Timer.Interval = 1000
        $Timer.Add_Tick({
                $Time = Get-Date -Format "HH:mm:ss"
                $Form.Text = "FW IC - $Time"
            })
        $InputBoxForm = New-Object Windows.Forms.Form
        $InputBoxForm.Text = "Enter a value"
        $InputBoxForm.Size = New-Object System.Drawing.Size(300, 150)
        $InputBoxForm.FormBorderStyle = "FixedSingle"
        $InputBoxForm.StartPosition = "CenterScreen"
        $LblInstructions = New-Object Windows.Forms.Label
        $LblInstructions.Text = "Enter a value:"
        $LblInstructions.Location = New-Object System.Drawing.Point(20, 20)
        $LblInstructions.AutoSize = $true
        $TxtInput = New-Object Windows.Forms.TextBox
        $TxtInput.Location = New-Object System.Drawing.Point(20, 50)
        $TxtInput.Size = New-Object System.Drawing.Size(200, 25)
        $BtnOK = New-Object Windows.Forms.Button
        $BtnOK.Text = "OK"
        $BtnOK.Location = New-Object System.Drawing.Point(20, 90)
        $BtnOK.DialogResult = [Windows.Forms.DialogResult]::OK
        $BtnCancel = New-Object Windows.Forms.Button
        $BtnCancel.Text = "Cancel"
        $BtnCancel.Location = New-Object System.Drawing.Point(100, 90)
        $BtnCancel.DialogResult = [Windows.Forms.DialogResult]::Cancel
        $InputBoxForm.Controls.Add($LblInstructions)
        $InputBoxForm.Controls.Add($TxtInput)
        $InputBoxForm.Controls.Add($BtnOK)
        $InputBoxForm.Controls.Add($BtnCancel)
        $Navbar = New-Object System.Windows.Forms.MenuStrip
        $Navbar.Location = New-Object System.Drawing.Point(0, 0)
        $Navbar.Size = New-Object System.Drawing.Size(500, 24)
        $MenuItemFile = New-Object System.Windows.Forms.ToolStripMenuItem
        $MenuItemFile.Text = "File"
        $MenuItemFile.DropDownItems.Add("Save Counter", $null, {
                try {
                    $global:Counter | Out-File -FilePath "counter.txt" -ErrorAction Stop
                    & $UpdateStatus "Counter has been saved"
                }
                catch {
                    & $UpdateStatus "Failed to save the counter!"
                }
            })
        $MenuItemFile.DropDownItems.Add("Load Counter", $null, {
                try {
                    if (Test-Path -Path "counter.txt") {
                        $global:counter = Get-Content -Path "counter.txt" -ErrorAction Stop
                        & $SetCounter $global:counter
                        & $UpdateStatus "Counter has been loaded"
                    }
                    else {
                        & $UpdateStatus "No saved counter found"
                    }
                }
                catch {
                    & $UpdateStatus "Failed to load the counter!"
                }
            })
        $MenuItemFile.DropDownItems.Add("Exit", $null, { 
                $Form.Close() 
            })
        $MenuItemEdit = New-Object System.Windows.Forms.ToolStripMenuItem
        $MenuItemEdit.Text = "Edit"
        $MenuItemEdit.DropDownItems.Add("Set Custom Counter", $null, {
                $InputBoxForm.ShowDialog()
                if ($InputBoxForm.DialogResult -eq [Windows.Forms.DialogResult]::OK) {
                    $Result = $null
                    if ([int]::TryParse($TxtInput.Text, [ref]$Result)) {
                        & $SetCounter $Result
                        & $UpdateStatus "Counter has been set to $global:Counter"
                    }
                    else {
                        & $UpdateStatus "Invalid input. Please enter a valid number!"
                    }
                }
            })
        $MenuItemView = New-Object System.Windows.Forms.ToolStripMenuItem
        $MenuItemView.Text = "View"
        $MenuItemView.DropDownItems.Add("Toggle Dark Mode", $null, { 
                if ($Form.BackColor -eq [System.Drawing.Color]::White) {
                    $Form.BackColor = [System.Drawing.Color]::Black
                    $Form.ForeColor = [System.Drawing.Color]::White
                    $StatusBar.BackColor = [System.Drawing.Color]::Black
                    $StatusBar.ForeColor = [System.Drawing.Color]::White
                }
                else {
                    $Form.BackColor = [System.Drawing.Color]::White
                    $Form.ForeColor = [System.Drawing.Color]::Black
                    $StatusBar.BackColor = [System.Drawing.Color]::White
                    $StatusBar.ForeColor = [System.Drawing.Color]::Black
                } 
            })
        $MenuItemTools = New-Object System.Windows.Forms.ToolStripMenuItem
        $MenuItemTools.Text = "Tools"
        $MenuItemTools.DropDownItems.Add("Tool", $null, { UpdateStatus("Tool pag(n/a atm)") })
        $MenuItemHelp = New-Object System.Windows.Forms.ToolStripMenuItem
        $MenuItemHelp.Text = "Help"
        $MenuItemHelp.DropDownItems.Add("Contact", $null, {
                & $UpdateStatus "Contact page"
                [System.Windows.Forms.MessageBox]::Show("FW IC Contact")
            })
        $MenuItemHelp.DropDownItems.Add("About", $null, {
                & $UpdateStatus "FW IC About page"
            })
        $Navbar.Items.Add($MenuItemFile)
        $Navbar.Items.Add($MenuItemEdit)
        $Navbar.Items.Add($MenuItemView)
        $Navbar.Items.Add($MenuItemTools)
        $Navbar.Items.Add($MenuItemHelp)
        $StatusBar = New-Object System.Windows.Forms.StatusStrip
        $StatusBar.Location = New-Object System.Drawing.Point(0, 250)
        $StatusBar.Size = New-Object System.Drawing.Size(500, 25)
        $StatusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
        $StatusLabel.Text = "Ready"
        $StatusBar.Items.Add($StatusLabel)
        $Form.Controls.Add($LblTitle)
        $Form.Controls.Add($LblCounter)
        $Form.Controls.Add($BtnIncrement)
        $Form.Controls.Add($BtnReset)
        $Form.Controls.Add($Navbar)
        $Form.Controls.Add($StatusBar)
        $Timer.Start()
        $Form.ShowDialog() | Out-Null
    }
    END {
        $Form.Dispose()
        $Timer.Dispose()
    }
}
