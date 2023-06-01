Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Scheduled Deployment"
$Form.Size = New-Object System.Drawing.Size(600, 500)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false

# Create the navbar
$Navbar = New-Object System.Windows.Forms.MenuStrip
$FileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
$FileMenu.Text = "File"
$ExitMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
$ExitMenuItem.Text = "Exit"
$ExitMenuItem.Add_Click({ $Form.Close() })
$FileMenu.DropDownItems.Add($ExitMenuItem)
$Navbar.Items.Add($FileMenu)
$Form.Controls.Add($Navbar)

# Create the statusbar
$Statusbar = New-Object System.Windows.Forms.StatusStrip
$LblStatus = New-Object System.Windows.Forms.ToolStripStatusLabel
$Statusbar.Items.Add($LblStatus)
$Form.Controls.Add($Statusbar)

## Create labels and textboxes for input fields
# Computer
$LblComputer = New-Object System.Windows.Forms.Label
$LblComputer.Location = New-Object System.Drawing.Point(20, 50)
$LblComputer.Size = New-Object System.Drawing.Size(100, 20)
$LblComputer.Text = "Computer:"
$Form.Controls.Add($LblComputer)

$TxtComputer = New-Object System.Windows.Forms.TextBox
$TxtComputer.Location = New-Object System.Drawing.Point(130, 50)
$TxtComputer.Size = New-Object System.Drawing.Size(200, 20)
$Form.Controls.Add($TxtComputer)

# Username
$LblUsername = New-Object System.Windows.Forms.Label
$LblUsername.Location = New-Object System.Drawing.Point(20, 80)
$LblUsername.Size = New-Object System.Drawing.Size(100, 20)
$LblUsername.Text = "Username:"
$Form.Controls.Add($LblUsername)

$TxtUsername = New-Object System.Windows.Forms.TextBox
$TxtUsername.Location = New-Object System.Drawing.Point(130, 80)
$TxtUsername.Size = New-Object System.Drawing.Size(200, 20)
$Form.Controls.Add($TxtUsername)

# Password
$LblPassword = New-Object System.Windows.Forms.Label
$LblPassword.Location = New-Object System.Drawing.Point(20, 110)
$LblPassword.Size = New-Object System.Drawing.Size(100, 20)
$LblPassword.Text = "Password:"
$Form.Controls.Add($LblPassword)

$TxtPassword = New-Object System.Windows.Forms.TextBox
$TxtPassword.Location = New-Object System.Drawing.Point(130, 110)
$TxtPassword.Size = New-Object System.Drawing.Size(200, 20)
$TxtPassword.PasswordChar = "*"
$Form.Controls.Add($TxtPassword)

# Tool
$LblTool = New-Object System.Windows.Forms.Label
$LblTool.Location = New-Object System.Drawing.Point(20, 140)
$LblTool.Size = New-Object System.Drawing.Size(100, 20)
$LblTool.Text = "Tool:"
$Form.Controls.Add($LblTool)

$CboTool = New-Object System.Windows.Forms.ComboBox
$CboTool.Location = New-Object System.Drawing.Point(130, 140)
$CboTool.Size = New-Object System.Drawing.Size(200, 20)
$CboTool.Items.AddRange(@("Tool 1", "Tool 2", "Tool 3"))
$Form.Controls.Add($CboTool)

# Action
$LblAction = New-Object System.Windows.Forms.Label
$LblAction.Location = New-Object System.Drawing.Point(20, 170)
$LblAction.Size = New-Object System.Drawing.Size(100, 20)
$LblAction.Text = "Action:"
$Form.Controls.Add($LblAction)

$CboAction = New-Object System.Windows.Forms.ComboBox
$CboAction.Location = New-Object System.Drawing.Point(130, 170)
$CboAction.Size = New-Object System.Drawing.Size(200, 20)
$CboAction.Items.AddRange(@("Action 1", "Action 2", "Action 3"))
$CboAction.Add_SelectedIndexChanged({
        # Clear the output window when action is changed
        $txtOutput.Text = ""
    })
$Form.Controls.Add($CboAction)

# Install Path
$LblInstallPath = New-Object System.Windows.Forms.Label
$LblInstallPath.Location = New-Object System.Drawing.Point(20, 200)
$LblInstallPath.Size = New-Object System.Drawing.Size(100, 20)
$LblInstallPath.Text = "Install Path:"
$Form.Controls.Add($LblInstallPath)

$BtnInstallPath = New-Object System.Windows.Forms.Button
$BtnInstallPath.Location = New-Object System.Drawing.Point(130, 200)
$BtnInstallPath.Size = New-Object System.Drawing.Size(30, 20)
$BtnInstallPath.Text = "..."
$BtnInstallPath.Add_Click({
        $Dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $Dialog.ShowDialog() | Out-Null
        $TxtInstallPath.Text = $Dialog.SelectedPath
    })
$Form.Controls.Add($BtnInstallPath)

$TxtInstallPath = New-Object System.Windows.Forms.TextBox
$TxtInstallPath.Location = New-Object System.Drawing.Point(170, 200)
$TxtInstallPath.Size = New-Object System.Drawing.Size(160, 20)
$Form.Controls.Add($TxtInstallPath)

# Capture Time
$LblCaptureTime = New-Object System.Windows.Forms.Label
$LblCaptureTime.Location = New-Object System.Drawing.Point(20, 230)
$LblCaptureTime.Size = New-Object System.Drawing.Size(100, 20)
$LblCaptureTime.Text = "Capture Time:"
$Form.Controls.Add($LblCaptureTime)

$TxtCaptureTime = New-Object System.Windows.Forms.DateTimePicker
$txtCaptureTime.Location = New-Object System.Drawing.Point(130, 230)
$txtCaptureTime.Size = New-Object System.Drawing.Size(200, 20)
$txtCaptureTime.Format = [System.Windows.Forms.DateTimePickerFormat]::Time
$Form.Controls.Add($txtCaptureTime)

# Output Window
$LblOutput = New-Object System.Windows.Forms.Label
$LblOutput.Location = New-Object System.Drawing.Point(20, 260)
$LblOutput.Size = New-Object System.Drawing.Size(100, 20)
$LblOutput.Text = "Output:"
$Form.Controls.Add($LblOutput)

$TxtOutput = New-Object System.Windows.Forms.TextBox
$TxtOutput.Location = New-Object System.Drawing.Point(20, 290)
$TxtOutput.Size = New-Object System.Drawing.Size(400, 120)
$TxtOutput.Multiline = $true
$TxtOutput.ScrollBars = "Vertical"
$Form.Controls.Add($TxtOutput)

# Execute button
$BtnExecute = New-Object System.Windows.Forms.Button
$BtnExecute.Location = New-Object System.Drawing.Point(20, 430)
$BtnExecute.Size = New-Object System.Drawing.Size(100, 30)
$BtnExecute.Text = "Execute"
$BtnExecute.Add_Click({
        $LblStatus.Text = "Executing..."
        # Execute the selected action here
        # Use $txtOutput.AppendText() to add status messages to the output window
        $LblStatus.Text = "Execution complete."
    })
$Form.Controls.Add($BtnExecute)

# Show the form
$Form.ShowDialog() | Out-Null
