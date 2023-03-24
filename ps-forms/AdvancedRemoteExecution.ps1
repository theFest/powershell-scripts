## v0.0.0.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
class ComputerCredentials {
    [string]$HostName
    [string]$Username
    [SecureString]$Password
    ComputerCredentials([string]$HostName, [string]$Username, [PSCredential]$Password) {
        $this.HostName = $HostName
        $this.Username = $Username
        $this.Password = $Password.Password
    }
}
Function AdvancedRemoteExecution {
    [CmdletBinding(DefaultParameterSetName = "AdvancedRemoteExecution")]
    param(
        [Parameter(Mandatory = $false, ParameterSetName = "ExecutionMethod", Position = 0)]
        [ValidateSet("CIM", "WMI", "PSRemoting", "PSSession", "DCOM", "PsExec", "PaExec")]
        [string]$ExecutionMethod,
        [Parameter(Mandatory = $false, ParameterSetName = "ComputerInventoryFile", Position = 1)]
        [string]$ComputerInventoryFile = "$env:USERPROFILE\Desktop\list.csv",

        [Parameter(Mandatory = $false, ParameterSetName = "ComputerName", Position = 2)]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $false, ParameterSetName = "ExecutionCommand", Position = 3)]
        [string]$ExecutionCommand,

        [Parameter(Mandatory = $false)]
        [PSCredential]$CredentialsFile,

        [Parameter(Mandatory = $false)]
        [string]$EncryptionKey,

        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "UTF32", "UTF7", "ASCII", "BigEndianUnicode", "Default", "OEM")]
        [System.Text.Encoding]$Encoding = "UTF8",

        [Parameter(Mandatory = $false)]
        [string]$Delimiter = ",",

        [switch]$AsJob
    )
    BEGIN {
        $Computers = @()
        if ($ComputerInventoryFile) {
            $Computers = Import-Csv -Path $ComputerInventoryFile -Encoding $Encoding -Delimiter $Delimiter | ForEach-Object {
                [ComputerCredentials]$SecCreds = New-Object ComputerCredentials ($_.Hostname, $_.Username, (New-Object PSCredential -ArgumentList $_.Username, (ConvertTo-SecureString $_.Password -AsPlainText -Force)))
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
    }
    PROCESS {
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
    }
    END {
        if ($EncryptionKey) {
            Encrypt-File -Path "$env:USERPROFILE\Desktop\executionResults.csv" -EncryptionKey $EncryptionKey
        }
    }
}
##################### MAIN FORM #####################
$form = New-Object Windows.Forms.Form
$form.Text = "Advanced Remote Execution"
$form.Width = 100
$form.Height = 1000
$form.AutoSize = $True
$form.ShowIcon
$form.ShowInTaskbar = $True
$form.MinimumSize.Width = 100
$form.MinimumSize.Height = 800
####################################################
##### Create menu strip #####
$menuStrip = New-Object Windows.Forms.MenuStrip
$form.Controls.Add($menuStrip)
## Create file menu
$fileMenu = New-Object Windows.Forms.ToolStripMenuItem
$fileMenu.Text = "File"
$menuStrip.Items.Add($fileMenu)
## Create open command
$openCommand = New-Object Windows.Forms.ToolStripMenuItem
$openCommand.Text = "Open"
$openCommand.ShortcutKeys = "Ctrl+O"
$openCommand.Add_Click({
        ##--> Code for open command goes here
        Write-Host "Open command clicked"
    })
$fileMenu.DropDownItems.Add($openCommand)
## Create save command
$saveCommand = New-Object Windows.Forms.ToolStripMenuItem
$saveCommand.Text = "Save"
$saveCommand.ShortcutKeys = "Ctrl+S"
$saveCommand.Add_Click({
        ##--> Code for save command goes here
        Write-Host "Save command clicked"
    })
$fileMenu.DropDownItems.Add($saveCommand)
## Create save as command
$saveAsCommand = New-Object Windows.Forms.ToolStripMenuItem
$saveAsCommand.Text = "Save As"
$saveAsCommand.ShortcutKeys = "Ctrl+Shift+S"
$saveAsCommand.Add_Click({
        ##--> Code for save as command goes here
        Write-Host "Save As command clicked"
    })
$fileMenu.DropDownItems.Add($saveAsCommand)
## Create exit command
$exitCommand = New-Object Windows.Forms.ToolStripMenuItem
$exitCommand.Text = "Exit"
$exitCommand.Add_Click({
        ##--> Code for exit command goes here
        Write-Host "Exit command clicked"
        $form.Close()
    })
$fileMenu.DropDownItems.Add($exitCommand)
## Create edit menu item
$editMenuItem = New-Object Windows.Forms.ToolStripMenuItem
$editMenuItem.Text = "Edit"
$menuStrip.Items.Add($editMenuItem)
## Create undo menu item
$undoMenuItem = New-Object Windows.Forms.ToolStripMenuItem
$undoMenuItem.Text = "Undo"
$undoMenuItem.ShortcutKeys = "Ctrl+Z"
$undoMenuItem.Add_Click({
        ##--> Add code here to undo an action
    })
$editMenuItem.DropDownItems.Add($undoMenuItem)
## Create redo menu item
$redoMenuItem = New-Object Windows.Forms.ToolStripMenuItem
$redoMenuItem.Text = "Redo"
$redoMenuItem.ShortcutKeys = "Ctrl+Y"
$redoMenuItem.Add_Click({
        ##--> Add code here to redo an action
    })
$editMenuItem.DropDownItems.Add($redoMenuItem)
# Create separator
$separator = New-Object Windows.Forms.ToolStripSeparator
$editMenuItem.DropDownItems.Add($separator)
## Create cut menu item
$cutMenuItem = New-Object Windows.Forms.ToolStripMenuItem
$cutMenuItem.Text = "Cut"
$cutMenuItem.ShortcutKeys = "Ctrl+X"
$cutMenuItem.Add_Click({
        ##--> Add code here to cut selected text
    })
$editMenuItem.DropDownItems.Add($cutMenuItem)
## Create copy menu item
$copyMenuItem = New-Object Windows.Forms.ToolStripMenuItem
$copyMenuItem.Text = "Copy"
$copyMenuItem.ShortcutKeys = "Ctrl+C"
$copyMenuItem.Add_Click({
        ##--> Add code here to copy selected text
    })
$editMenuItem.DropDownItems.Add($copyMenuItem)
## Create paste menu item
$pasteMenuItem = New-Object Windows.Forms.ToolStripMenuItem
$pasteMenuItem.Text = "Paste"
$pasteMenuItem.ShortcutKeys = "Ctrl+V"
$pasteMenuItem.Add_Click({
        ##--> Add code here to paste text from clipboard
    })
$editMenuItem.DropDownItems.Add($pasteMenuItem)
## Create help menu
$helpMenu = New-Object Windows.Forms.ToolStripMenuItem
$helpMenu.Text = "Help"
$menuStrip.Items.Add($helpMenu)
## Create help command
$helpCommand = New-Object Windows.Forms.ToolStripMenuItem
$helpCommand.Text = "Help"
$helpCommand.ShortcutKeys = "F1"
$helpCommand.Add_Click({
        ##--> Code for help command goes here
        Write-Host "Help command clicked"
    })
$helpMenu.DropDownItems.Add($helpCommand)
## Execution Method
$executionMethodLabel = New-Object Windows.Forms.Label
$executionMethodLabel.Text = "Exec Type"
$executionMethodLabel.Width = 100
$executionMethodLabel.Height = 20
$executionMethodLabel.Location = New-Object Drawing.Point(10, 40)
$form.Controls.Add($executionMethodLabel)
$executionMethodComboBox = New-Object Windows.Forms.ComboBox
$executionMethodComboBox.Items.Add("CIM")
$executionMethodComboBox.Items.Add("WMI")
$executionMethodComboBox.Items.Add("PSRemoting")
$executionMethodComboBox.Items.Add("PSSession")
$executionMethodComboBox.Items.Add("DCOM")
$executionMethodComboBox.Items.Add("PsExec")
$executionMethodComboBox.Items.Add("PaExec")
$executionMethodComboBox.Width = 200
$executionMethodComboBox.Height = 20
$executionMethodComboBox.Location = New-Object Drawing.Point(120, 40)
$form.Controls.Add($executionMethodComboBox)
$computerInventoryFileLabel = New-Object Windows.Forms.Label
$computerInventoryFileLabel.Text = "Inventory File:"
$computerInventoryFileLabel.Width = 150
$computerInventoryFileLabel.Height = 20
$computerInventoryFileLabel.Location = New-Object Drawing.Point(10, 70)
$form.Controls.Add($computerInventoryFileLabel)
$computerInventoryFileTextBox = New-Object Windows.Forms.TextBox
$computerInventoryFileTextBox.Width = 300
$computerInventoryFileTextBox.Height = 20
$computerInventoryFileTextBox.Location = New-Object Drawing.Point(180, 70)
$form.Controls.Add($computerInventoryFileTextBox)
$ComputerInventoryFile = "$env:USERPROFILE\Desktop\list.csv"
$ComputerInventory = Import-Csv -Path $ComputerInventoryFile
foreach ($computer in $ComputerInventory) {
    Write-Host "Hostname: $($computer.Hostname)"
    Write-Host "Username: $($computer.Username)"
    Write-Host "Password: $($computer.Password)"
}
$openFileDialogButton = New-Object Windows.Forms.Button
$openFileDialogButton.Text = "..."
$openFileDialogButton.Width = 30
$openFileDialogButton.Height = 20
$openFileDialogButton.Location = New-Object Drawing.Point(490, 70)
$openFileDialogButton.Add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
        $openFileDialog.InitialDirectory = "$env:USERPROFILE\Desktop\"
        if ($openFileDialog.ShowDialog() -eq "OK") {
            $computerInventoryFileTextBox.Text = $openFileDialog.FileName
        }
    })
$form.Controls.Add($openFileDialogButton)
$computerNameLabel = New-Object Windows.Forms.Label
$computerNameLabel.Text = "Computer Name:"
$computerNameLabel.Width = 150
$computerNameLabel.Height = 20
$computerNameLabel.Location = New-Object Drawing.Point(10, 100)
$form.Controls.Add($computerNameLabel)
$computerNameTextBox = New-Object Windows.Forms.TextBox
$computerNameTextBox.Width = 300
$computerNameTextBox.Height = 20
$computerNameTextBox.Location = New-Object Drawing.Point(180, 100)
$form.Controls.Add($computerNameTextBox)
$executionCommandLabel = New-Object Windows.Forms.Label
$executionCommandLabel.Text = "Execution Command:"
$executionCommandLabel.Width = 150
$executionCommandLabel.Height = 20
$executionCommandLabel.Location = New-Object Drawing.Point(10, 130)
$form.Controls.Add($executionCommandLabel)
$executionCommandComboBox = New-Object Windows.Forms.ComboBox
$executionCommandComboBox.Width = 300
$executionCommandComboBox.Height = 20
$executionCommandComboBox.DropDownStyle = "DropDownList" #"Drop"
$executionCommandComboBox.Items.Add("Get-Process")
$executionCommandComboBox.Items.Add("Get-Service")
$executionCommandComboBox.Items.Add("Get-HotFix")
$executionCommandComboBox.Items.Add("Get-EventLog")
$executionCommandComboBox.Items.Add("Get-WmiObject")
$executionCommandComboBox.Items.Add("Get-NetAdapter")
$executionCommandComboBox.Items.Add("Get-NetIPAddress")
$executionCommandComboBox.SelectedIndex = 0
$executionCommandComboBox.Location = New-Object Drawing.Point(180, 130)
$form.Controls.Add($executionCommandComboBox)

$executeButton = New-Object Windows.Forms.Button
$executeButton.Text = "Execute"
$executeButton.Width = 100
$executeButton.Height = 30
$executeButton.Location = New-Object Drawing.Point(10, 310)
$executeButton.Add_Click({
        [System.Windows.Forms.MessageBox]::Show("Are you sure, press [x] to exit ???")
        #[System.Windows.Forms.Message]::Create(
        $executionMethod = $executionMethodComboBox.SelectedItem
        $computerInventoryFile = $computerInventoryFileTextBox.Text
        $computerName = $computerNameTextBox.Text
        $executionCommand = $executionCommandTextBox.Text
        $credentialsFile = $credentialsFileTextBox.Text
        $encryptionKey = $encryptionKeyTextBox.Text
        $encoding = $encodingComboBox.SelectedItem
        $delimiter = $delimiterTextBox.Text
        $asJob = $asJobCheckbox.Checked
        $executeScriptFile = $executeScriptFileTextBox.Text
        AdvancedRemoteExecution -ExecutionMethod $executionMethod -ComputerInventoryFile $computerInventoryFile -ComputerName $computerName -ExecutionCommand $executionCommand -CredentialsFile $credentialsFile -EncryptionKey $encryptionKey -Encoding $encoding -Delimiter $delimiter -AsJob $asJob
    })
$form.Controls.Add($executeButton)
$ExecScriptLabel = New-Object Windows.Forms.Label
$ExecScriptLabel.Text = "Execute Script File:"
$ExecScriptLabel.Width = 150
$ExecScriptLabel.Height = 20
$ExecScriptLabel.Location = New-Object Drawing.Point(10, 160)
$form.Controls.Add($ExecScriptLabel)
$ExecScriptTextBox = New-Object Windows.Forms.TextBox
$ExecScriptTextBox.Width = 300
$ExecScriptTextBox.Height = 20
$ExecScriptTextBox.Location = New-Object Drawing.Point(180, 160)
$form.Controls.Add($ExecScriptTextBox)
$ExecScriptButton = New-Object Windows.Forms.Button
$ExecScriptButton.Text = "..."
$ExecScriptButton.Width = 30
$ExecScriptButton.Height = 20
$ExecScriptButton.Location = New-Object Drawing.Point(490, 160)
$ExecScriptButton.Add_Click({
        $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $openFileDialog.Filter = "PS1 files (*.ps1)|*.ps1|All files (*.*)|*.*"
        $openFileDialog.InitialDirectory = "$env:USERPROFILE\Desktop\"
        if ($openFileDialog.ShowDialog() -eq "OK") {
            $executeScriptTextBox.Text = $openFileDialog.FileName
        }
    })
$form.Controls.Add($ExecScriptopenFileDialogButton2)
$ExecScriptButton.Add_Click({
        $executeScript = $ExecScriptTextBox.Text
        # Execute script on remote computer
        Invoke-Command -FilePath $executeScript -ComputerName $computerName
    })

<#
$cmdButton = New-Object Windows.Forms.Button
$cmdButton.Text = "Run Command"
$cmdButton.Width = 100
$cmdButton.Height = 30
$cmdButton.Location = New-Object Drawing.Point(10, 10)
$cmdButton.Add_Click({
        # code to run when button is clicked
        # such as getting the command from the textbox and executing it in the cmd window
    })
$form.Controls.Add($cmdButton)
#>

$cmdTextBox = New-Object Windows.Forms.TextBox
$cmdTextBox.Width = 300
$cmdTextBox.Height = 200
$cmdTextBox.
$cmdTextBox.Location = New-Object Drawing.Point(520, 100)
$form.Controls.Add($cmdTextBox)
$cmdCommand = $cmdTextBox.Text
cmd /c $cmdCommand | Out-String
$cmdLabel = New-Object Windows.Forms.Label
$cmdLabel.Text = "Command:"
$cmdLabel.Width = 100
$cmdLabel.Height = 20
$cmdLabel.Location = New-Object Drawing.Point(10, 10)
$form.Controls.Add($cmdLabel)
$executeScriptButton.Add_Click({
        $selectedItem = $comboBox.SelectedItem
        $runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
        $runspace.Open()
        $pipeline = $runspace.CreatePipeline()
        $pipeline.Commands.Add($selectedItem)
        $results = $pipeline.Invoke()
        $dataGridView.Rows.Clear()
        $dataGridView.Columns.Clear()
        $dataGridView.DataSource = $results
        $dataGridView.AutoResizeColumns()
        $dataGridView.AutoResizeRows()
        $runspace.Close()
    })
$credentialsFileLabel = New-Object Windows.Forms.Label
$credentialsFileLabel.Text = "Credentials File:"
$credentialsFileLabel.Width = 150
$credentialsFileLabel.Height = 20
$credentialsFileLabel.Location = New-Object Drawing.Point(10, 190)
$form.Controls.Add($credentialsFileLabel)
$credentialsFileTextBox = New-Object Windows.Forms.TextBox
$credentialsFileTextBox.Width = 300
$credentialsFileTextBox.Height = 20
$credentialsFileTextBox.Location = New-Object Drawing.Point(180, 190)
$form.Controls.Add($credentialsFileTextBox)
$encryptionKeyLabel = New-Object Windows.Forms.Label
$encryptionKeyLabel.Text = "Encryption Key:"
$encryptionKeyLabel.Width = 150
$encryptionKeyLabel.Height = 20
$encryptionKeyLabel.Location = New-Object Drawing.Point(10, 220)
$form.Controls.Add($encryptionKeyLabel)
$encryptionKeyTextBox = New-Object Windows.Forms.TextBox
$encryptionKeyTextBox.Width = 300
$encryptionKeyTextBox.Height = 20
$encryptionKeyTextBox.Location = New-Object Drawing.Point(180, 220)
$form.Controls.Add($encryptionKeyTextBox)
$encodingLabel = New-Object Windows.Forms.Label
$encodingLabel.Text = "Encoding:"
$encodingLabel.Width = 150
$encodingLabel.Height = 20
$encodingLabel.Location = New-Object Drawing.Point(10, 250)
$form.Controls.Add($encodingLabel)
$encodingComboBox = New-Object Windows.Forms.ComboBox
$encodingComboBox.Items.Add("UTF8")
$encodingComboBox.Items.Add("UTF32")
$encodingComboBox.Items.Add("UTF7")
$encodingComboBox.Items.Add("ASCII")
$encodingComboBox.Items.Add("BigEndianUnicode")
$encodingComboBox.Items.Add("Default")
$encodingComboBox.Items.Add("OEM")
$encodingComboBox.Width = 200
$encodingComboBox.Height = 20
$encodingComboBox.Location = New-Object Drawing.Point(180, 250)
$form.Controls.Add($encodingComboBox)
$asJobCheckbox = New-Object Windows.Forms.CheckBox
$asJobCheckbox.Text = "As Job"
$asJobCheckbox.Width = 150
$asJobCheckbox.Height = 20
$asJobCheckbox.Location = New-Object Drawing.Point(10, 280)
$form.Controls.Add($asJobCheckbox)
$dataGridView = New-Object Windows.Forms.DataGridView
$dataGridView.Width = 760
$dataGridView.Height = 560
$dataGridView.Location = New-Object Drawing.Point(10, 350)
$DataGridView.AllowUserToAddRows = $true
$DataGridView.ColumnCount = 6
#$DataGridView.ColumnHeadersDefaultCellStyle.WrapMode = $false
#$DataGridView.ColumnHeadersDefaultCellStyle.Alignment = $True
#$DataGridView.AutoSizeColumnsMode = $True
$DataGridView.Columns[0].Name = "Panel"
$DataGridView.Columns[1].Name = "User"
$DataGridView.Columns[2].Name = "Pass"
$DataGridView.Columns[3].Name = "Connectivity"
$DataGridView.Columns[4].Name = "OutputResult"
$DataGridView.Columns[5].Name = "CommandExecuted"
$form.Controls.Add($dataGridView)
$FetchButton = New-Object Windows.Forms.Button
$FetchButton.Text = "Fetch VPN"
$FetchButton.Width = 100
$FetchButton.Height = 30
$FetchButton.Location = New-Object Drawing.Point(660, 310)
$FetchButton.Add_Click({
        AdvancedRemoteExecution -ExecutionMethod $executionMethod -ComputerInventoryFile $computerInventoryFile -ComputerName $computerName -ExecutionCommand $executionCommand -CredentialsFile $credentialsFile -EncryptionKey $encryptionKey -Encoding $encoding -Delimiter $delimiter -AsJob $asJob
    })
$form.Controls.Add($FetchButton)
$StatusBarObject = New-Object System.Windows.Forms.StatusBar
$StatusBarObject.Name = "StatusBar"
$StatusBarObject.Text = "Ready"
$form.Controls.Add($StatusBarObject)
$form.Add_KeyDown({ if ($_.KeyCode -eq "Enter") { $ExecuteButton.PerformClick() } })
$form.Add_KeyDown({ if ($_.KeyCode -eq "Escape") { $form.Close() } })
$form.Topmost = $True
$form.Add_Shown({ $form.Activate() })
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Minimum = 0
$progressBar.Maximum = $Computers.Count
$progressBar.Width = 300
$progressBar.Height = 20
$progressBar.Location = New-Object Drawing.Point(10, 915)
$form.Controls.Add($progressBar)
$form.ShowDialog()
