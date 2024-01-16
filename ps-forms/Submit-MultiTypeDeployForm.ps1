Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Form = New-Object Windows.Forms.Form
$Form.Text = "FW MultiType Exec"
$Form.Width = 100
$Form.Height = 1000
$Form.AutoSize = $True
$Form.ShowIcon
$Form.ShowInTaskbar = $True
$Form.MinimumSize.Width = 100
$Form.MinimumSize.Height = 800
$MenuStrip = New-Object Windows.Forms.MenuStrip
$Form.Controls.Add($MenuStrip)
$FileMenu = New-Object Windows.Forms.ToolStripMenuItem
$FileMenu.Text = "File"
$MenuStrip.Items.Add($FileMenu)
$OpenCommand = New-Object Windows.Forms.ToolStripMenuItem
$OpenCommand.Text = "Open"
$OpenCommand.ShortcutKeys = "Ctrl+O"
$OpenCommand.Add_Click({
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
        $OpenFileDialog.InitialDirectory = "$env:USERPROFILE\Documents"
        if ($OpenFileDialog.ShowDialog() -eq "OK") {
            $FilePath = $OpenFileDialog.FileName
            $FileContents = Get-Content -Path $FilePath
            [System.Windows.Forms.MessageBox]::Show("File Contents:`n$FileContents", "File Opened")
        }
    })
$FileMenu.DropDownItems.Add($OpenCommand)
$SaveCommand = New-Object Windows.Forms.ToolStripMenuItem
$SaveCommand.Text = "Save"
$SaveCommand.ShortcutKeys = "Ctrl+S"
$SaveCommand.Add_Click({
        $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $SaveFileDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
        $SaveFileDialog.InitialDirectory = "$env:USERPROFILE\Documents"
        if ($SaveFileDialog.ShowDialog() -eq "OK") {
            $FilePath = $SaveFileDialog.FileName
            $FileContents = $TextBox.Text
            $FileContents | Out-File -FilePath $FilePath -Force
            [System.Windows.Forms.MessageBox]::Show("File Saved: $FilePath", "Save Successful")
        }
    })
$FileMenu.DropDownItems.Add($SaveCommand)
$SaveAsCommand = New-Object Windows.Forms.ToolStripMenuItem
$SaveAsCommand.Text = "Save As"
$SaveAsCommand.ShortcutKeys = "Ctrl+Shift+S"
$SaveAsCommand.Add_Click({
        $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
        $SaveFileDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
        $SaveFileDialog.InitialDirectory = "$env:USERPROFILE\Documents"
        if ($SaveFileDialog.ShowDialog() -eq "OK") {
            $FilePath = $SaveFileDialog.FileName
            $FileContents = $TextBox.Text
            $FileContents | Out-File -FilePath $FilePath -Force
            [System.Windows.Forms.MessageBox]::Show("File Saved: $FilePath", "Save As Successful")
        }
    })
$FileMenu.DropDownItems.Add($SaveAsCommand)
$ExitCommand = New-Object Windows.Forms.ToolStripMenuItem
$ExitCommand.Text = "Exit"
$ExitCommand.Add_Click({
        $Confirmation = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to exit?", "Exit Confirmation", "YesNo", "Warning")
        if ($Confirmation -eq "Yes") {
            $Form.Close()
        }
    })
$FileMenu.DropDownItems.Add($ExitCommand)
$EditMenuItem = New-Object Windows.Forms.ToolStripMenuItem
$EditMenuItem.Text = "Edit"
$MenuStrip.Items.Add($EditMenuItem)
$UndoMenuItem = New-Object Windows.Forms.ToolStripMenuItem
$UndoMenuItem.Text = "Undo"
$UndoMenuItem.ShortcutKeys = "Ctrl+Z"
$UndoStack = @()
$UndoMenuItem.Add_Click({
        if ($UndoStack.Count -gt 0) {
            $LastAction = $UndoStack.Pop()
            $RevertedAction = $LastAction -replace 'Reversed:', ''
            $TextBox.Text = $RevertedAction
        }
    })
$EditMenuItem.DropDownItems.Add($UndoMenuItem)
$RedoMenuItem = New-Object Windows.Forms.ToolStripMenuItem
$RedoMenuItem.Text = "Redo"
$RedoMenuItem.ShortcutKeys = "Ctrl+Y"
$RedoMenuItem.Add_Click({
        if ($RedoStack.Count -gt 0) {
            $RedoAction = $RedoStack.Pop()
            $TextBox.Text += "Redone: $RedoAction"
        }
    })
$EditMenuItem.DropDownItems.Add($RedoMenuItem)
$Separator = New-Object Windows.Forms.ToolStripSeparator
$EditMenuItem.DropDownItems.Add($Separator)
$CutMenuItem = New-Object Windows.Forms.ToolStripMenuItem
$CutMenuItem.Text = "Cut"
$CutMenuItem.ShortcutKeys = "Ctrl+X"
$CutMenuItem.Add_Click({
        $SelectedText = $TextBox.SelectedText
        if ($SelectedText -ne '') {
            [System.Windows.Forms.Clipboard]::SetText($SelectedText)
            $TextBox.Text = $TextBox.Text -replace $SelectedText, ''
        }
    })
$EditMenuItem.DropDownItems.Add($CutMenuItem)
$CopyMenuItem = New-Object Windows.Forms.ToolStripMenuItem
$CopyMenuItem.Text = "Copy"
$CopyMenuItem.ShortcutKeys = "Ctrl+C"
$CopyMenuItem.Add_Click({
        $SelectedText = $TextBox.SelectedText
        if ($SelectedText -ne '') {
            [System.Windows.Forms.Clipboard]::SetText($SelectedText)
        }
    })
$EditMenuItem.DropDownItems.Add($CopyMenuItem)
$PasteMenuItem = New-Object Windows.Forms.ToolStripMenuItem
$PasteMenuItem.Text = "Paste"
$PasteMenuItem.ShortcutKeys = "Ctrl+V"
$PasteMenuItem.Add_Click({
        $ClipboardContent = [System.Windows.Forms.Clipboard]::GetText()
        if ($ClipboardContent -ne '') {
            $TextBox.SelectedText = $ClipboardContent
        }
    })
$EditMenuItem.DropDownItems.Add($PasteMenuItem)
$HelpMenu = New-Object Windows.Forms.ToolStripMenuItem
$HelpMenu.Text = "Help"
$MenuStrip.Items.Add($HelpMenu)
$HelpCommand = New-Object Windows.Forms.ToolStripMenuItem
$HelpCommand.Text = "Help"
$HelpCommand.ShortcutKeys = "F1"
$HelpCommand.Add_Click({
        $HelpForm = New-Object Windows.Forms.Form
        $HelpForm.Text = "Help"
        $HelpForm.Width = 400
        $HelpForm.Height = 300
        $HelpForm.AutoSize = $True
        $HelpForm.MaximizeBox = $False
        $HelpForm.MinimizeBox = $False
        $HelpForm.StartPosition = "CenterScreen"
        $HelpLabel = New-Object Windows.Forms.Label
        $HelpLabel.Text = @"
-------------------------------------------------------------------------------------------------
 Submit-MultiTypeDeployForm                                                             v0.0.0.2
-------------------------------------------------------------------------------------------------
Help section, to be customized with information as needed.
"@
        $HelpLabel.AutoSize = $True
        $HelpLabel.Location = New-Object Drawing.Point(10, 10)
        $HelpForm.Controls.Add($HelpLabel)
        $OKButton = New-Object Windows.Forms.Button
        $OKButton.Text = "OK"
        $OKButton.DialogResult = [Windows.Forms.DialogResult]::OK
        $OKButton.Location = New-Object Drawing.Point(150, 250)
        $HelpForm.Controls.Add($OKButton)
        $HelpForm.ShowDialog()
    })
$HelpMenu.DropDownItems.Add($HelpCommand)
$ExecutionMethodLabel = New-Object Windows.Forms.Label
$ExecutionMethodLabel.Text = "Exec Type"
$ExecutionMethodLabel.Width = 100
$ExecutionMethodLabel.Height = 20
$ExecutionMethodLabel.Location = New-Object Drawing.Point(10, 40)
$Form.Controls.Add($ExecutionMethodLabel)
$ExecutionMethodComboBox = New-Object Windows.Forms.ComboBox
$ExecutionMethodComboBox.Items.Add("CIM")
$ExecutionMethodComboBox.Items.Add("WMI")
$ExecutionMethodComboBox.Items.Add("PSRemoting")
$ExecutionMethodComboBox.Items.Add("PSSession")
$ExecutionMethodComboBox.Items.Add("DCOM")
$ExecutionMethodComboBox.Items.Add("PsExec")
$ExecutionMethodComboBox.Items.Add("PaExec")
$ExecutionMethodComboBox.Width = 200
$ExecutionMethodComboBox.Height = 20
$ExecutionMethodComboBox.Location = New-Object Drawing.Point(120, 40)
$Form.Controls.Add($ExecutionMethodComboBox)
$ComputerInventoryFileLabel = New-Object Windows.Forms.Label
$ComputerInventoryFileLabel.Text = "Inventory File:"
$ComputerInventoryFileLabel.Width = 150
$ComputerInventoryFileLabel.Height = 20
$ComputerInventoryFileLabel.Location = New-Object Drawing.Point(10, 70)
$Form.Controls.Add($ComputerInventoryFileLabel)
$ComputerInventoryFileTextBox = New-Object Windows.Forms.TextBox
$ComputerInventoryFileTextBox.Width = 300
$ComputerInventoryFileTextBox.Height = 20
$ComputerInventoryFileTextBox.Location = New-Object Drawing.Point(180, 70)
$Form.Controls.Add($ComputerInventoryFileTextBox)
if (!$ComputerInventoryFile) {
    $ComputerInventory = Import-Csv -Path $ComputerInventoryFile
    foreach ($Computer in $ComputerInventory) {
        Write-Host "Hostname: $($Computer.Hostname)"
        Write-Host "Username: $($Computer.Username)"
        Write-Host "Password: $($Computer.Password)"
    }
}
$OpenFileDialogButton = New-Object Windows.Forms.Button
$OpenFileDialogButton.Text = "..."
$OpenFileDialogButton.Width = 30
$OpenFileDialogButton.Height = 20
$OpenFileDialogButton.Location = New-Object Drawing.Point(490, 70)
$OpenFileDialogButton.Add_Click({
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
        $OpenFileDialog.InitialDirectory = "$env:USERPROFILE\Desktop\"
        if ($OpenFileDialog.ShowDialog() -eq "OK") {
            $ComputerInventoryFileTextBox.Text = $OpenFileDialog.FileName
        }
    })
$Form.Controls.Add($OpenFileDialogButton)
$ComputerNameLabel = New-Object Windows.Forms.Label
$ComputerNameLabel.Text = "Computer Name:"
$ComputerNameLabel.Width = 150
$ComputerNameLabel.Height = 20
$ComputerNameLabel.Location = New-Object Drawing.Point(10, 100)
$Form.Controls.Add($ComputerNameLabel)
$ComputerNameTextBox = New-Object Windows.Forms.TextBox
$ComputerNameTextBox.Width = 300
$ComputerNameTextBox.Height = 20
$ComputerNameTextBox.Location = New-Object Drawing.Point(180, 100)
$Form.Controls.Add($ComputerNameTextBox)
$ExecutionCommandLabel = New-Object Windows.Forms.Label
$ExecutionCommandLabel.Text = "Execution Command:"
$ExecutionCommandLabel.Width = 150
$ExecutionCommandLabel.Height = 20
$ExecutionCommandLabel.Location = New-Object Drawing.Point(10, 130)
$Form.Controls.Add($ExecutionCommandLabel)
$ExecutionCommandComboBox = New-Object Windows.Forms.ComboBox
$ExecutionCommandComboBox.Width = 300
$ExecutionCommandComboBox.Height = 20
$ExecutionCommandComboBox.DropDownStyle = "DropDownList"
$ExecutionCommandComboBox.Items.Add("Get-Process")
$ExecutionCommandComboBox.Items.Add("Get-Service")
$ExecutionCommandComboBox.Items.Add("Get-HotFix")
$ExecutionCommandComboBox.Items.Add("Get-EventLog")
$ExecutionCommandComboBox.Items.Add("Get-WmiObject")
$ExecutionCommandComboBox.Items.Add("Get-NetAdapter")
$ExecutionCommandComboBox.Items.Add("Get-NetIPAddress")
$ExecutionCommandComboBox.SelectedIndex = 0
$ExecutionCommandComboBox.Location = New-Object Drawing.Point(180, 130)
$Form.Controls.Add($ExecutionCommandComboBox)
$ExecuteButton = New-Object Windows.Forms.Button
$ExecuteButton.Text = "Execute"
$ExecuteButton.Width = 100
$ExecuteButton.Height = 30
$ExecuteButton.Location = New-Object Drawing.Point(10, 310)
$ExecuteButton.Add_Click({
        [System.Windows.Forms.MessageBox]::Show("Are you sure, press [x] to exit ???")
        $ExecutionMethod = $ExecutionMethodComboBox.SelectedItem
        $ComputerInventoryFile = $ComputerInventoryFileTextBox.Text
        $ComputerName = $ComputerNameTextBox.Text
        $ExecutionCommand = $ExecutionCommandTextBox.Text
        $CredentialsFile = $CredentialsFileTextBox.Text
        $Encoding = $EncodingComboBox.SelectedItem
        $Delimiter = $DelimiterTextBox.Text
        $AsJob = $AsJobCheckbox.Checked
        param(
            [Parameter(Mandatory = $false, ParameterSetName = "ExecutionMethod", Position = 0)]
            [ValidateSet("CIM", "WMI", "PSRemoting", "PSSession", "DCOM", "PsExec", "PaExec")]
            [string]$ExecutionMethod,
            
            [Parameter(Mandatory = $false, ParameterSetName = "ComputerInventoryFile", Position = 1)]
            [string]$ComputerInventoryFile,

            [Parameter(Mandatory = $false, ParameterSetName = "ComputerName", Position = 2)]
            [string[]]$ComputerName,

            [Parameter(Mandatory = $false, ParameterSetName = "ExecutionCommand", Position = 3)]
            [string]$ExecutionCommand,

            [Parameter(Mandatory = $false)]
            [PSCredential]$CredentialsFile,

            [Parameter(Mandatory = $false)]
            [ValidateSet("UTF8", "UTF32", "UTF7", "ASCII", "BigEndianUnicode", "Default", "OEM")]
            [System.Text.Encoding]$Encoding,

            [Parameter(Mandatory = $false)]
            [string]$Delimiter = ",",

            [switch]$AsJob
        )
        $Computers = @()
        if ($ComputerInventoryFile) {
            $Computers = Import-Csv -Path $ComputerInventoryFile -Encoding $Encoding -Delimiter $Delimiter | ForEach-Object {
                $SecCreds = New-Object ($_.Hostname, $_.Username, (New-Object PSCredential -ArgumentList $_.Username, (ConvertTo-SecureString $_.Password -AsPlainText -Force)))
                $SecCreds
            }
        }
        else {
            $Computers = $ComputerName
        }
        $Results = @()
        $Computers | ForEach-Object {
            $PingResults = Test-Connection -ComputerName $_ -Count 1 -AsJob
            Wait-Job -Job $PingResults -Verbose
            $PingResults = Receive-Job -Job $PingResults
            $Result = [PSCustomObject]@{
                HostName = $_
                Status   = if ($PingResults.StatusCode -eq 0) { "Online" } else { "Offline" }
            }
            $Results += $Result
        }
        $Results | Export-Csv -Path "$env:USERPROFILE\Desktop\pingResults.csv" -Force -NoTypeInformation
        $Results | Format-Table -Property HostName, Status
        $PingResultJob = Get-Job | Write-Output
        $PingResultJob | Remove-Job -Force -Verbose
        switch ($ExecutionMethod) {
            "CIM" {
                foreach ($Computer in $Computers) {
                    $Session = New-CimSession -ComputerName $Computer.HostName -Credential $Computer.Credential
                    $Results = Invoke-CimMethod -CimSession $Session -MethodName $ExecutionCommand
                    $Session | Remove-CimSession
                }
            }
            "WMI" {
                foreach ($Computer in $Computers) {
                    $Connection = New-CimInstance -ComputerName $Computer.HostName -Credential $Computer.Credential
                    $Results = Invoke-WmiMethod -InputObject $Connection -Name $ExecutionCommand
                }
            }
            "PSRemoting" {
                foreach ($Computer in $Computers) {
                    $Session = New-PSSession -ComputerName $Computer.HostName -Credential $Computer.Credential
                    $Results = Invoke-Command -Session $Session -ScriptBlock { $ExecutionCommand }
                    Remove-PSSession $Session
                }
            }
            "PSSession" {
                foreach ($Computer in $Computers) {
                    $Session = New-PSSession -ComputerName $Computer.HostName -Credential $Computer.Credential
                    $Results = Invoke-Command -Session $Session -ScriptBlock { $ExecutionCommand }
                    Remove-PSSession $Session
                }
            }
            "DCOM" {
                foreach ($Computer in $Computers) {
                    $Connection = New-Object -ComObject $ExecutionCommand -ArgumentList $Computer.HostName, $Computer.Credential
                    $Results = $Connection.Execute()
                }
            }
            "PsExec" {
                foreach ($Computer in $Computers) {
                    $Results = PsExec.exe \$Computer.HostName -u $Computer.Username -p $Computer.Password $ExecutionCommand
                }
            }
            "PaExec" {
                foreach ($Computer in $Computers) {
                    $Results = PaExec.exe \$Computer.HostName -u $Computer.Username -p $Computer.Password $ExecutionCommand
                }
            }
        }
        $Results | Export-Csv -Path "$env:USERPROFILE\Desktop\executionResults.csv" -Force -NoTypeInformation
        $Results | Format-Table -Property HostName, Status, CommandOutput
    })
$Form.Controls.Add($ExecuteButton)
$ExecScriptLabel = New-Object Windows.Forms.Label
$ExecScriptLabel.Text = "Execute Script File:"
$ExecScriptLabel.Width = 150
$ExecScriptLabel.Height = 20
$ExecScriptLabel.Location = New-Object Drawing.Point(10, 160)
$Form.Controls.Add($ExecScriptLabel)
$ExecScriptTextBox = New-Object Windows.Forms.TextBox
$ExecScriptTextBox.Width = 300
$ExecScriptTextBox.Height = 20
$ExecScriptTextBox.Location = New-Object Drawing.Point(180, 160)
$Form.Controls.Add($ExecScriptTextBox)
$ExecScriptButton = New-Object Windows.Forms.Button
$ExecScriptButton.Text = "..."
$ExecScriptButton.Width = 30
$ExecScriptButton.Height = 20
$ExecScriptButton.Location = New-Object Drawing.Point(490, 160)
$ExecScriptButton.Add_Click({
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Filter = "PS1 files (*.ps1)|*.ps1|All files (*.*)|*.*"
        $OpenFileDialog.InitialDirectory = "$env:USERPROFILE\Desktop\"
        if ($OpenFileDialog.ShowDialog() -eq "OK") {
            $ExecuteScriptTextBox.Text = $OpenFileDialog.FileName
        }
    })
$Form.Controls.Add($ExecScriptopenFileDialogButton2)
$ExecScriptButton.Add_Click({
        $ExecuteScript = $ExecScriptTextBox.Text
        Invoke-Command -FilePath $ExecuteScript -ComputerName $ComputerName
    })
$ExecuteScriptButton.Add_Click({
        $SelectedItem = $ComboBox.SelectedItem
        $Runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
        $Runspace.Open()
        $Pipeline = $Runspace.CreatePipeline()
        $Pipeline.Commands.Add($selectedItem)
        $Results = $Pipeline.Invoke()
        $DataGridView.Rows.Clear()
        $DataGridView.Columns.Clear()
        $DataGridView.DataSource = $results
        $DataGridView.AutoResizeColumns()
        $DataGridView.AutoResizeRows()
        $Runspace.Close()
    })
$EncodingLabel = New-Object Windows.Forms.Label
$EncodingLabel.Text = "Encoding:"
$EncodingLabel.Width = 150
$EncodingLabel.Height = 20
$EncodingLabel.Location = New-Object Drawing.Point(10, 190)
$Form.Controls.Add($EncodingLabel)
$EncodingComboBox = New-Object Windows.Forms.ComboBox
$EncodingComboBox.Items.Add("UTF8")
$EncodingComboBox.Items.Add("UTF32")
$EncodingComboBox.Items.Add("UTF7")
$EncodingComboBox.Items.Add("ASCII")
$EncodingComboBox.Items.Add("BigEndianUnicode")
$EncodingComboBox.Items.Add("Default")
$EncodingComboBox.Items.Add("OEM")
$EncodingComboBox.Width = 200
$EncodingComboBox.Height = 20
$EncodingComboBox.Location = New-Object Drawing.Point(180, 190)
$Form.Controls.Add($EncodingComboBox)
$AsJobCheckbox = New-Object Windows.Forms.CheckBox
$AsJobCheckbox.Text = "As Job"
$AsJobCheckbox.Width = 150
$AsJobCheckbox.Height = 20
$AsJobCheckbox.Location = New-Object Drawing.Point(10, 280)
$Form.Controls.Add($AsJobCheckbox)
$DataGridView = New-Object Windows.Forms.DataGridView
$DataGridView.Width = 760
$DataGridView.Height = 560
$DataGridView.Location = New-Object Drawing.Point(10, 350)
$DataGridView.AllowUserToAddRows = $true
$DataGridView.ColumnCount = 6
$DataGridView.Columns[0].Name = "Panel"
$DataGridView.Columns[1].Name = "User"
$DataGridView.Columns[2].Name = "Pass"
$DataGridView.Columns[3].Name = "Connectivity"
$DataGridView.Columns[4].Name = "OutputResult"
$DataGridView.Columns[5].Name = "CommandExecuted"
$Form.Controls.Add($DataGridView)
$StatusBarObject = New-Object System.Windows.Forms.StatusBar
$StatusBarObject.Name = "StatusBar"
$StatusBarObject.Text = "Ready"
$Form.Controls.Add($StatusBarObject)
$Form.Add_KeyDown({ if ($_.KeyCode -eq "Enter") { $ExecuteButton.PerformClick() } })
$Form.Add_KeyDown({ if ($_.KeyCode -eq "Escape") { $Form.Close() } })
$Form.Topmost = $True
$Form.Add_Shown({ $Form.Activate() })
$ProgressBar = New-Object System.Windows.Forms.ProgressBar
$ProgressBar.Minimum = 0
$ProgressBar.Maximum = $Computers.Count
$ProgressBar.Width = 300
$ProgressBar.Height = 20
$ProgressBar.Location = New-Object Drawing.Point(10, 915)
$Form.Controls.Add($ProgressBar)
$Form.ShowDialog()
