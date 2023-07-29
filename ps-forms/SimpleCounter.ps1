Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "PowerShell GUI"
$form.Size = New-Object System.Drawing.Size(500, 300)
$form.StartPosition = "CenterScreen"

# Create labels
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Welcome to PowerShell GUI!"
$lblTitle.Location = New-Object System.Drawing.Point(20, 20)
$lblTitle.AutoSize = $true

$lblCounter = New-Object System.Windows.Forms.Label
$lblCounter.Text = "Counter: 0"
$lblCounter.Location = New-Object System.Drawing.Point(20, 60)
$lblCounter.AutoSize = $true

# Create buttons
$btnIncrement = New-Object System.Windows.Forms.Button
$btnIncrement.Text = "Increment"
$btnIncrement.Location = New-Object System.Drawing.Point(20, 100)
$btnIncrement.Add_Click({
        $counter++
        $lblCounter.Text = "Counter: $counter"
    })

$btnReset = New-Object System.Windows.Forms.Button
$btnReset.Text = "Reset"
$btnReset.Location = New-Object System.Drawing.Point(120, 100)
$btnReset.Add_Click({
        $counter = 0
        $lblCounter.Text = "Counter: $counter"
    })

# Create a timer for updating the form
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
        $time = Get-Date -Format "HH:mm:ss"
        $form.Text = "PowerShell GUI - $time"
    })

# Add controls to the form
$form.Controls.Add($lblTitle)
$form.Controls.Add($lblCounter)
$form.Controls.Add($btnIncrement)
$form.Controls.Add($btnReset)

# Initialize variables
$counter = 0

# Start the timer
$timer.Start()

# Show the form
$form.ShowDialog()
