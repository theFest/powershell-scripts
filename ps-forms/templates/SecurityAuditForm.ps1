Function SecurityAuditForm {
    param(
        [string]$NmapURL = 'https://nmap.org/dist/nmap-7.92-setup.exe'
    )
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $Form = New-Object Windows.Forms.Form
    $Form.Text = "Security Audit Form"
    $Form.Size = New-Object Drawing.Size(640, 480)
    $Form.BackColor = "Black"
    $Form.ForeColor = "White"
    ## Download Nmap Button
    $BtnDownloadNmap = New-Object Windows.Forms.Button
    $BtnDownloadNmap.Text = "Download Nmap"
    $BtnDownloadNmap.Location = New-Object Drawing.Point(10, 10)
    $BtnDownloadNmap.Size = New-Object Drawing.Size(120, 30)
    $BtnDownloadNmap.BackColor = "DarkGreen"
    $BtnDownloadNmap.Add_Click({
            ## Code to download Nmap here
            Invoke-WebRequest -Uri $NmapURL -OutFile "nmap-setup.exe"
            ## Add code to install Nmap here if needed
        })
    $Form.Controls.Add($BtnDownloadNmap)
    ## Computername Input
    $LblComputername = New-Object Windows.Forms.Label
    $LblComputername.Text = "Computer Name:"
    $LblComputername.Location = New-Object Drawing.Point(10, 50)
    $LblComputername.Size = New-Object Drawing.Size(100, 20)
    $Form.Controls.Add($LblComputername)
    $TxtComputername = New-Object Windows.Forms.TextBox
    $TxtComputername.Location = New-Object Drawing.Point(120, 50)
    $TxtComputername.Size = New-Object Drawing.Size(200, 20)
    $Form.Controls.Add($TxtComputername)
    ## Username Input
    $LblUsername = New-Object Windows.Forms.Label
    $LblUsername.Text = "Username:"
    $LblUsername.Location = New-Object Drawing.Point(10, 80)
    $LblUsername.Size = New-Object Drawing.Size(100, 20)
    $Form.Controls.Add($LblUsername)
    $TxtUsername = New-Object Windows.Forms.TextBox
    $TxtUsername.Location = New-Object Drawing.Point(120, 80)
    $TxtUsername.Size = New-Object Drawing.Size(200, 20)
    $Form.Controls.Add($TxtUsername)
    ## Password Input
    $LblPassword = New-Object Windows.Forms.Label
    $LblPassword.Text = "Password:"
    $LblPassword.Location = New-Object Drawing.Point(10, 110)
    $LblPassword.Size = New-Object Drawing.Size(100, 20)
    $Form.Controls.Add($LblPassword)
    $TxtPassword = New-Object Windows.Forms.TextBox
    $TxtPassword.Location = New-Object Drawing.Point(120, 110)
    $TxtPassword.Size = New-Object Drawing.Size(200, 20)
    $TxtPassword.UseSystemPasswordChar = $true
    $Form.Controls.Add($TxtPassword)
    ## Protocol Dropdown (WinRM)
    $LblProtocol = New-Object Windows.Forms.Label
    $LblProtocol.Text = "Protocol:"
    $LblProtocol.Location = New-Object Drawing.Point(10, 140)
    $LblProtocol.Size = New-Object Drawing.Size(100, 20)
    $Form.Controls.Add($LblProtocol)
    $CmbProtocol = New-Object Windows.Forms.ComboBox
    $CmbProtocol.Location = New-Object Drawing.Point(120, 140)
    $CmbProtocol.Size = New-Object Drawing.Size(200, 20)
    $CmbProtocol.Items.AddRange(@("WinRM", "SSH", "HTTPS"))
    $Form.Controls.Add($CmbProtocol)
    ## Output Window
    $OutputBox = New-Object Windows.Forms.TextBox
    $OutputBox.Multiline = $true
    $OutputBox.ScrollBars = "Vertical"
    $OutputBox.Location = New-Object Drawing.Point(10, 180)
    $OutputBox.Size = New-Object Drawing.Size(560, 160)
    $OutputBox.BackColor = "Black"
    $OutputBox.ForeColor = "White"
    $OutputBox.ReadOnly = $true
    $Form.Controls.Add($OutputBox)
    ## Function to execute the security audit
    Function Invoke-SecurityAudit {
        ## Add code here to perform security audit using Nmap or other tools
        $OutputBox.AppendText("Security Audit started...`r`n")
        ## Sample code to simulate audit process
        Start-Sleep -Seconds 2
        $OutputBox.AppendText("Audit in progress...`r`n")
        Start-Sleep -Seconds 2
        $OutputBox.AppendText("Audit completed.`r`n")
    }
    ## Start Audit Button
    $BtnStartAudit = New-Object Windows.Forms.Button
    $BtnStartAudit.Text = "Start Audit"
    $BtnStartAudit.Location = New-Object Drawing.Point(10, 350)
    $BtnStartAudit.Size = New-Object Drawing.Size(120, 30)
    $BtnStartAudit.BackColor = "DarkGreen"
    $BtnStartAudit.Add_Click({ Invoke-SecurityAudit })
    $Form.Controls.Add($BtnStartAudit)
    ## Show the form
    $Form.ShowDialog()
}

SecurityAuditForm
