Add-Type -AssemblyName System.Windows.Forms

# Initialize variables
$counter = 0

# Function to update status in the status bar
Function UpdateStatus([string]$message) {
    $statusLabel.Text = $message
}

# Function to reset the counter with a confirmation dialog
Function ResetCounter {
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to reset the counter?", 
        "Confirm Reset", "YesNo", "Question")
    
    if ($result -eq "Yes") {
        SetCounter 0
        UpdateStatus("Counter has been reset.")
    }
}

# Function to set the counter value and update the label
Function SetCounter([int]$value) {
    $global:counter = $value
    $lblCounter.Text = "Counter: $global:counter"
}

# Function for "Contact" menu item
Function ShowContactForm {
    UpdateStatus("You are on the Contact page.")
    # Add Functionality for the "Contact" menu item here
    # For demonstration purposes, let's show a simple message box
    [System.Windows.Forms.MessageBox]::Show("This is the Contact page.")
}

# Function for "Exit" menu item
Function ExitApplication {
    $form.Close()
}

# Function to save the counter value to a file
Function SaveCounter {
    try {
        $global:counter | Out-File -FilePath "counter.txt"
        UpdateStatus("Counter has been saved.")
    }
    catch {
        UpdateStatus("Failed to save the counter.")
    }
}

# Function to load the counter value from a file
Function LoadCounter {
    try {
        if (Test-Path -Path "counter.txt") {
            $global:counter = Get-Content -Path "counter.txt" -ErrorAction Stop
            SetCounter $global:counter
            UpdateStatus("Counter has been loaded.")
        }
        else {
            UpdateStatus("No saved counter found.")
        }
    }
    catch {
        UpdateStatus("Failed to load the counter.")
    }
}

# Function for setting a custom counter value
Function SetCustomCounter {
    $inputBoxForm.ShowDialog()

    if ($inputBoxForm.DialogResult -eq [Windows.Forms.DialogResult]::OK) {
        $result = $null  # Create a variable to hold the parsed value
        if ([int]::TryParse($txtInput.Text, [ref]$result)) {
            SetCounter $result
            UpdateStatus("Counter has been set to $global:counter.")
        }
        else {
            UpdateStatus("Invalid input. Please enter a valid number.")
        }
    }
}

# Function for changing the theme (dark mode)
Function ToggleDarkMode {
    if ($form.BackColor -eq [System.Drawing.Color]::White) {
        $form.BackColor = [System.Drawing.Color]::Black
        $form.ForeColor = [System.Drawing.Color]::White
        $statusBar.BackColor = [System.Drawing.Color]::Black
        $statusBar.ForeColor = [System.Drawing.Color]::White
    }
    else {
        $form.BackColor = [System.Drawing.Color]::White
        $form.ForeColor = [System.Drawing.Color]::Black
        $statusBar.BackColor = [System.Drawing.Color]::White
        $statusBar.ForeColor = [System.Drawing.Color]::Black
    }
}

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell GUI"
$form.Size = New-Object System.Drawing.Size(500, 300)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::White

# Create labels
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Welcome to PowerShell GUI!"
$lblTitle.AutoSize = $true
$lblTitle.Location = New-Object System.Drawing.Point(20, 50)

$lblCounter = New-Object System.Windows.Forms.Label
$lblCounter.Text = "Counter: $global:counter"
$lblCounter.AutoSize = $true
$lblCounter.Location = New-Object System.Drawing.Point(20, 100)

# Create buttons
$btnIncrement = New-Object System.Windows.Forms.Button
$btnIncrement.Text = "Increment"
$btnIncrement.Location = New-Object System.Drawing.Point(20, 150)
$btnIncrement.Add_Click({
        SetCounter ($global:counter + 1)
        UpdateStatus("Counter has been incremented. Current value: $global:counter.")
    })

$btnReset = New-Object System.Windows.Forms.Button
$btnReset.Text = "Reset"
$btnReset.Location = New-Object System.Drawing.Point(120, 150)
$btnReset.Add_Click({
        ResetCounter
    })

# Create a timer for updating the form
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
        $time = Get-Date -Format "HH:mm:ss"
        $form.Text = "PowerShell GUI - $time"
    })

# Custom input box form
$inputBoxForm = New-Object Windows.Forms.Form
$inputBoxForm.Text = "Enter a value"
$inputBoxForm.Size = New-Object System.Drawing.Size(300, 150)
$inputBoxForm.FormBorderStyle = "FixedSingle"
$inputBoxForm.StartPosition = "CenterScreen"

# Label to display instructions
$lblInstructions = New-Object Windows.Forms.Label
$lblInstructions.Text = "Enter a value:"
$lblInstructions.Location = New-Object System.Drawing.Point(20, 20)
$lblInstructions.AutoSize = $true

# TextBox for user input
$txtInput = New-Object Windows.Forms.TextBox
$txtInput.Location = New-Object System.Drawing.Point(20, 50)
$txtInput.Size = New-Object System.Drawing.Size(200, 25)

# OK button to accept input
$btnOK = New-Object Windows.Forms.Button
$btnOK.Text = "OK"
$btnOK.Location = New-Object System.Drawing.Point(20, 90)
$btnOK.DialogResult = [Windows.Forms.DialogResult]::OK

# Cancel button to close the input box without saving the input
$btnCancel = New-Object Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Location = New-Object System.Drawing.Point(100, 90)
$btnCancel.DialogResult = [Windows.Forms.DialogResult]::Cancel

# Add controls to the form
$inputBoxForm.Controls.Add($lblInstructions)
$inputBoxForm.Controls.Add($txtInput)
$inputBoxForm.Controls.Add($btnOK)
$inputBoxForm.Controls.Add($btnCancel)


# Create a navigation bar
$navbar = New-Object System.Windows.Forms.MenuStrip
$navbar.Location = New-Object System.Drawing.Point(0, 0)
$navbar.Size = New-Object System.Drawing.Size(500, 24)

# Create menu items
$menuItemFile = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItemFile.Text = "File"
$menuItemFile.DropDownItems.Add("Save Counter", $null, { SaveCounter })
$menuItemFile.DropDownItems.Add("Load Counter", $null, { LoadCounter })
$menuItemFile.DropDownItems.Add("Exit", $null, { ExitApplication })

$menuItemEdit = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItemEdit.Text = "Edit"
$menuItemEdit.DropDownItems.Add("Set Custom Counter", $null, { SetCustomCounter })

$menuItemView = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItemView.Text = "View"
$menuItemView.DropDownItems.Add("Toggle Dark Mode", $null, { ToggleDarkMode })

$menuItemTools = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItemTools.Text = "Tools"
$menuItemTools.DropDownItems.Add("Some Tool", $null, { UpdateStatus("You are on the Some Tool page.") })

$menuItemHelp = New-Object System.Windows.Forms.ToolStripMenuItem
$menuItemHelp.Text = "Help"
$menuItemHelp.DropDownItems.Add("Contact", $null, { ShowContactForm })
$menuItemHelp.DropDownItems.Add("About", $null, { UpdateStatus("This is the About page.") })

# Add menu items to the navigation bar
$navbar.Items.Add($menuItemFile)
$navbar.Items.Add($menuItemEdit)
$navbar.Items.Add($menuItemView)
$navbar.Items.Add($menuItemTools)
$navbar.Items.Add($menuItemHelp)

# Create a status bar
$statusBar = New-Object System.Windows.Forms.StatusStrip
$statusBar.Location = New-Object System.Drawing.Point(0, 250)
$statusBar.Size = New-Object System.Drawing.Size(500, 25)

$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready"
$statusBar.Items.Add($statusLabel)

# Add controls to the form
$form.Controls.Add($lblTitle)
$form.Controls.Add($lblCounter)
$form.Controls.Add($btnIncrement)
$form.Controls.Add($btnReset)
$form.Controls.Add($navbar)
$form.Controls.Add($statusBar)

# Start the timer
$timer.Start()

# Display the form
$form.ShowDialog() | Out-Null
