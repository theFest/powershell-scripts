# Load the .NET Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create a new form object
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "IE Engine Browser Window"
$Form.Size = New-Object System.Drawing.Size(1600, 900)
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
$Form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font

# Create a search box and a search button
$SearchBox = New-Object System.Windows.Forms.TextBox
$SearchBox.Location = New-Object System.Drawing.Point(10, 10)
$SearchBox.Size = New-Object System.Drawing.Size(400, 20)
$Form.Controls.Add($SearchBox)

# Create an embedded window (in this case, a web browser control)
$WebBrowser = New-Object System.Windows.Forms.WebBrowser
$WebBrowser.ScriptErrorsSuppressed = $true
$WebBrowser.IsWebBrowserContextMenuEnabled = $false
$WebBrowser.Dock = [System.Windows.Forms.DockStyle]::Fill
$WebBrowser.Navigate("https://www.google.com")

# Add the embedded window and the search box to the form's controls
$Form.Controls.Add($WebBrowser)
$Form.Controls.Add($SearchBox)

# Show the form
$Form.ShowDialog()