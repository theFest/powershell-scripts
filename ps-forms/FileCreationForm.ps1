Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Function ShowAboutDialog {
    [System.Windows.Forms.MessageBox]::Show("FW File Creation Form`nVersion 0.0.0.6", "About", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

Function ShowHelpDialog {
    [System.Windows.Forms.MessageBox]::Show(@"
This application allows you to create multiple files with custom content.

Enhancements in Version 0.0.0.6:
- Added support for setting custom Prefix, Suffix, and Extension.
- Improved styling and layout.
- Clock dynamically placed on the right side of the status bar.
"@, "Help", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

Function FileCreationForm {
    param (
        [string]$DefaultPath = "$env:USERPROFILE\Desktop",
        [string]$DefaultPrefix = "",
        [string]$DefaultSuffix = "",
        [string]$DefaultExtension = "txt",
        [int]$DefaultNumberOfFiles = 5
    )
    $Form = New-Object Windows.Forms.Form
    $Form.Text = "FW File Creation Form"
    $Form.Size = New-Object Drawing.Size(815, 600)
    $Form.StartPosition = [Windows.Forms.FormStartPosition]::CenterScreen
    $Form.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40)
    $Form.ForeColor = [System.Drawing.Color]::White

    $Style = [System.Windows.Forms.FlatStyle]::Flat

    $MenuBar = New-Object System.Windows.Forms.MenuStrip
    $MenuBar.ForeColor = [System.Drawing.Color]::White
    $MenuBar.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
    $MenuBar.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)

    $FileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
    $FileMenu.Text = "&File"

    $HelpMenu = New-Object System.Windows.Forms.ToolStripMenuItem
    $HelpMenu.Text = "&Help"

    $FileMenuItem_CreateFiles = New-Object System.Windows.Forms.ToolStripMenuItem
    $FileMenuItem_CreateFiles.Text = "Create Files"
    $FileMenuItem_CreateFiles.Add_Click({ CreateFiles })
    $FileMenu.DropDownItems.Add($FileMenuItem_CreateFiles)

    $FileMenuItem_Browse = New-Object System.Windows.Forms.ToolStripMenuItem
    $FileMenuItem_Browse.Text = "Browse..."
    $FileMenuItem_Browse.Add_Click({
            $FolderBrowserDialog = New-Object Windows.Forms.FolderBrowserDialog
            $Result = $FolderBrowserDialog.ShowDialog()

            if ($Result -eq [Windows.Forms.DialogResult]::OK) {
                $TextBoxPath.Text = $FolderBrowserDialog.SelectedPath
            }
        })
    $FileMenu.DropDownItems.Add($FileMenuItem_Browse)

    $FileMenuItem_Exit = New-Object System.Windows.Forms.ToolStripMenuItem
    $FileMenuItem_Exit.Text = "Exit"
    $FileMenuItem_Exit.Add_Click({ $Form.Close() })
    $FileMenu.DropDownItems.Add($FileMenuItem_Exit)

    $HelpMenuItem_About = New-Object System.Windows.Forms.ToolStripMenuItem
    $HelpMenuItem_About.Text = "About"
    $HelpMenuItem_About.Add_Click({ ShowAboutDialog })
    $HelpMenu.DropDownItems.Add($HelpMenuItem_About)

    $HelpMenuItem_Help = New-Object System.Windows.Forms.ToolStripMenuItem
    $HelpMenuItem_Help.Text = "Help"
    $HelpMenuItem_Help.Add_Click({ ShowHelpDialog })
    $HelpMenu.DropDownItems.Add($HelpMenuItem_Help)

    $MenuBar.Items.Add($FileMenu)
    $MenuBar.Items.Add($HelpMenu)

    $Form.Controls.Add($MenuBar)

    $LabelPath = New-Object Windows.Forms.Label
    $LabelPath.Text = "Path:"
    $LabelPath.Location = New-Object Drawing.Point(20, 42)
    $LabelPath.AutoSize = $true
    $LabelPath.ForeColor = [System.Drawing.Color]::White
    $LabelPath.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($LabelPath)

    $TextBoxPath = New-Object Windows.Forms.TextBox
    $TextBoxPath.Text = $DefaultPath
    $TextBoxPath.Location = New-Object Drawing.Point(100, 40)
    $TextBoxPath.Size = New-Object Drawing.Size(550, 30)
    $TextBoxPath.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $Form.Controls.Add($TextBoxPath)

    $ButtonBrowse = New-Object Windows.Forms.Button
    $ButtonBrowse.Text = "Browse..."
    $ButtonBrowse.Location = New-Object Drawing.Point(670, 40)
    $ButtonBrowse.Size = New-Object Drawing.Size(100, 30)
    $ButtonBrowse.FlatStyle = $style
    $ButtonBrowse.BackColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
    $ButtonBrowse.ForeColor = [System.Drawing.Color]::White
    $ButtonBrowse.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $ButtonBrowse.Add_Click({
            $FolderBrowserDialog = New-Object Windows.Forms.FolderBrowserDialog
            $Result = $FolderBrowserDialog.ShowDialog()

            if ($Result -eq [Windows.Forms.DialogResult]::OK) {
                $TextBoxPath.Text = $FolderBrowserDialog.SelectedPath
            }
        })
    $Form.Controls.Add($ButtonBrowse)

    $CheckBoxPrefix = New-Object Windows.Forms.CheckBox
    $CheckBoxPrefix.Text = "Prefix:"
    $CheckBoxPrefix.Location = New-Object Drawing.Point(20, 80)
    $CheckBoxPrefix.AutoSize = $true
    $CheckBoxPrefix.Checked = $false
    $CheckBoxPrefix.ForeColor = [System.Drawing.Color]::White
    $CheckBoxPrefix.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($CheckBoxPrefix)

    $TextBoxPrefix = New-Object Windows.Forms.TextBox
    $TextBoxPrefix.Text = $DefaultPrefix
    $TextBoxPrefix.Location = New-Object Drawing.Point(100, 75)
    $TextBoxPrefix.Size = New-Object Drawing.Size(200, 30)
    $TextBoxPrefix.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $Form.Controls.Add($TextBoxPrefix)

    $CheckBoxSuffix = New-Object Windows.Forms.CheckBox
    $CheckBoxSuffix.Text = "Suffix:"
    $CheckBoxSuffix.Location = New-Object Drawing.Point(320, 80)
    $CheckBoxSuffix.AutoSize = $true
    $CheckBoxSuffix.Checked = $false
    $CheckBoxSuffix.ForeColor = [System.Drawing.Color]::White
    $CheckBoxSuffix.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($CheckBoxSuffix)

    $TextBoxSuffix = New-Object Windows.Forms.TextBox
    $TextBoxSuffix.Text = $DefaultSuffix
    $TextBoxSuffix.Location = New-Object Drawing.Point(400, 75)
    $TextBoxSuffix.Size = New-Object Drawing.Size(200, 30)
    $TextBoxSuffix.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $Form.Controls.Add($TextBoxSuffix)

    $LabelExtension = New-Object Windows.Forms.Label
    $LabelExtension.Text = "Extension:"
    $LabelExtension.Location = New-Object Drawing.Point(20, 130)
    $LabelExtension.AutoSize = $true
    $LabelExtension.ForeColor = [System.Drawing.Color]::White
    $LabelExtension.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($LabelExtension)

    $ComboBoxExtension = New-Object Windows.Forms.ComboBox
    $ComboBoxExtension.Location = New-Object Drawing.Point(130, 125)
    $ComboBoxExtension.Size = New-Object Drawing.Size(100, 30)
    $ComboBoxExtension.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $Form.Controls.Add($ComboBoxExtension)

    $LabelNumberOfFiles = New-Object Windows.Forms.Label
    $LabelNumberOfFiles.Text = "Number of Files:"
    $LabelNumberOfFiles.Location = New-Object Drawing.Point(296, 130)
    $LabelNumberOfFiles.AutoSize = $true
    $LabelNumberOfFiles.ForeColor = [System.Drawing.Color]::White
    $LabelNumberOfFiles.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($LabelNumberOfFiles)

    $TextBoxNumberOfFiles = New-Object Windows.Forms.TextBox
    $TextBoxNumberOfFiles.Text = $DefaultNumberOfFiles
    $TextBoxNumberOfFiles.Location = New-Object Drawing.Point(450, 125)
    $TextBoxNumberOfFiles.Size = New-Object Drawing.Size(50, 30)
    $TextBoxNumberOfFiles.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $Form.Controls.Add($TextBoxNumberOfFiles)

    $CheckBoxOverwrite = New-Object Windows.Forms.CheckBox
    $CheckBoxOverwrite.Text = "Overwrite existing files"
    $CheckBoxOverwrite.Location = New-Object Drawing.Point(20, 180)
    $CheckBoxOverwrite.AutoSize = $true
    $CheckBoxOverwrite.Checked = $true
    $CheckBoxOverwrite.ForeColor = [System.Drawing.Color]::White
    $CheckBoxOverwrite.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($CheckBoxOverwrite)

    $CheckBoxOpenFiles = New-Object Windows.Forms.CheckBox
    $CheckBoxOpenFiles.Text = "Open files after creation"
    $CheckBoxOpenFiles.Location = New-Object Drawing.Point(20, 210)
    $CheckBoxOpenFiles.AutoSize = $true
    $CheckBoxOpenFiles.ForeColor = [System.Drawing.Color]::White
    $CheckBoxOpenFiles.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($CheckBoxOpenFiles)

    $LabelContentTemplate = New-Object Windows.Forms.Label
    $LabelContentTemplate.Text = "Content Template:"
    $LabelContentTemplate.Location = New-Object Drawing.Point(20, 250)
    $LabelContentTemplate.AutoSize = $true
    $LabelContentTemplate.ForeColor = [System.Drawing.Color]::White
    $LabelContentTemplate.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($LabelContentTemplate)

    $TextBoxContentTemplate = New-Object Windows.Forms.TextBox
    $TextBoxContentTemplate.Location = New-Object Drawing.Point(20, 280)
    $TextBoxContentTemplate.Multiline = $true
    $TextBoxContentTemplate.Size = New-Object Drawing.Size(760, 120)
    $TextBoxContentTemplate.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $Form.Controls.Add($TextBoxContentTemplate)

    $LabelCreationDate = New-Object Windows.Forms.Label
    $LabelCreationDate.Text = "Creation Date:"
    $LabelCreationDate.Location = New-Object Drawing.Point(20, 420)
    $LabelCreationDate.AutoSize = $true
    $LabelCreationDate.ForeColor = [System.Drawing.Color]::White
    $LabelCreationDate.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($LabelCreationDate)

    $DateTimePickerCreationDate = New-Object Windows.Forms.DateTimePicker
    $DateTimePickerCreationDate.Format = [Windows.Forms.DateTimePickerFormat]::Custom
    $DateTimePickerCreationDate.CustomFormat = "yyyy-MM-dd HH:mm:ss"
    $DateTimePickerCreationDate.Location = New-Object Drawing.Point(150, 415)
    $DateTimePickerCreationDate.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $Form.Controls.Add($DateTimePickerCreationDate)

    $ButtonCreate = New-Object Windows.Forms.Button
    $ButtonCreate.Text = "Create Files"
    $ButtonCreate.Location = New-Object Drawing.Point(330, 470)
    $ButtonCreate.Size = New-Object Drawing.Size(150, 40)
    $ButtonCreate.FlatStyle = $Style
    $ButtonCreate.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
    $ButtonCreate.ForeColor = [System.Drawing.Color]::White
    $ButtonCreate.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $ButtonCreate.Add_Click({ CreateFiles })
    $Form.Controls.Add($ButtonCreate)

    $StatusBar = New-Object System.Windows.Forms.StatusStrip
    $StatusBar.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $StatusBar.ForeColor = [System.Drawing.Color]::White
    $StatusBarLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $StatusBarLabel.AutoSize = $false
    $StatusBarLabel.Spring = $true
    $StatusBarLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
    $StatusBar.Items.Add($StatusBarLabel)
    $Form.Controls.Add($StatusBar)

    $ClockTimer = New-Object System.Windows.Forms.Timer
    $ClockTimer.Interval = 1000
    $ClockTimer.Add_Tick({
            $StatusBarLabel.Text = "Current Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        })
    $ClockTimer.Start()

    $Form.Add_Shown({ $Form.Activate() })
    PopulateExtensionComboBox

    $Form.ShowDialog()
}

Function PopulateExtensionComboBox {
    $StandardExtensions = @("ps1", "py", "sh", "txt", "exe", "docx", "xlsx", "csv", "pdf", "jpg", "png", "zip", "mp3", "mp4")
    $ComboBoxExtension.Items.AddRange($StandardExtensions)
}

Function ValidateFormFields {
    if ([string]::IsNullOrWhiteSpace($TextBoxPath.Text) -or
        ($CheckBoxPrefix.Checked -and [string]::IsNullOrWhiteSpace($TextBoxPrefix.Text)) -or
        ($CheckBoxSuffix.Checked -and [string]::IsNullOrWhiteSpace($TextBoxSuffix.Text)) -or
        [string]::IsNullOrWhiteSpace($ComboBoxExtension.SelectedItem) -or
        [string]::IsNullOrWhiteSpace($TextBoxNumberOfFiles.Text) -or
        ($TextBoxNumberOfFiles.Text -match '\D')) {
        return $false
    }
    return $true
}

Function CreateFiles {
    if (ValidateFormFields) {
        $Path = $TextBoxPath.Text
        $Prefix = $TextBoxPrefix.Text
        $Suffix = $TextBoxSuffix.Text
        $Extension = $ComboBoxExtension.SelectedItem
        $NumberOfFiles = [int]$TextBoxNumberOfFiles.Text
        $OverwriteExisting = $CheckBoxOverwrite.Checked
        $OpenFiles = $CheckBoxOpenFiles.Checked
        $ContentTemplate = $TextBoxContentTemplate.Text
        $CreationDate = $DateTimePickerCreationDate.Value
        $FilesCreated = 0
        for ($i = 1; $i -le $NumberOfFiles; $i++) {
            $FileName = "{0}{1}{2}.{3}" -f $Prefix, $i, $Suffix, $Extension
            $FullFilePath = Join-Path -Path $Path -ChildPath $FileName
            if (-not (Test-Path -Path $FullFilePath) -or $OverwriteExisting) {
                if ($ContentTemplate) {
                    $FileContent = $ContentTemplate -replace '\$FileName', $FileName -replace '\$Index', $i
                    Set-Content -Path $FullFilePath -Value $FileContent -Force
                }
                else {
                    New-Item -ItemType File -Path $FullFilePath -Force | Out-Null
                }
                if ($CreationDate) {
                    $FileInfo = Get-Item -Path $FullFilePath
                    $FileInfo.LastWriteTime = $CreationDate
                    $FileInfo.LastAccessTime = $CreationDate
                    [System.IO.File]::SetCreationTime($FullFilePath, $CreationDate)
                }
                $FilesCreated++
            }
            if ($OpenFiles) {
                Invoke-Item -Path $FullFilePath
            }
        }
        if ($FilesCreated -gt 0) {
            [System.Windows.Forms.MessageBox]::Show("Files created successfully!", "Success", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("No files were created. Please check the form fields and try again.", "Error", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Please fill all fields with valid values.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
    }
}

FileCreationForm
