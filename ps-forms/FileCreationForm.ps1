Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Function ShowAboutDialog {
    [System.Windows.Forms.MessageBox]::Show("File Creation Form`nVersion 0.0.0.3", "About", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

Function ShowHelpDialog {
    [System.Windows.Forms.MessageBox]::Show(@"
This application allows you to create multiple files with custom content.
Fill in the details and click 'Create Files' to begin.
If 'Open files after creation' is checked, the files will be opened after they are created.
You can also provide a content template to apply custom content to each file.
The 'Creation Date' field lets you set the creation date of the files.

Enhancements in Version 2.0:
- Added support for setting custom Prefix, Suffix, and Extension.
- Improved error handling and validation.
- Enhanced UI and overall user experience.
- Displays current time in the status bar.
"@, "Help", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

Function FileCreationForm {
    [CmdletBinding()]
    param (
        [string]$DefaultPath = "$env:USERPROFILE\Desktop",
        [string]$DefaultPrefix = "File",
        [string]$DefaultSuffix = "",
        [string]$DefaultExtension = "txt",
        [int]$DefaultNumberOfFiles = 5
    )
    $Form = New-Object Windows.Forms.Form
    $Form.Text = "File Creation Form"
    $Form.Size = New-Object Drawing.Size(840, 580)
    $Form.StartPosition = [Windows.Forms.FormStartPosition]::CenterScreen
    $Form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $Form.ForeColor = [System.Drawing.Color]::White

    $Style = [System.Windows.Forms.FlatStyle]::Flat

    $MenuBar = New-Object System.Windows.Forms.MenuStrip
    $MenuBar.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $FileMenu = New-Object System.Windows.Forms.ToolStripMenuItem
    $HelpMenu = New-Object System.Windows.Forms.ToolStripMenuItem

    $FileMenu.Text = "&File"
    $HelpMenu.Text = "&Help"

    $FileMenuItem_CreateFiles = New-Object System.Windows.Forms.ToolStripMenuItem
    $FileMenuItem_Browse = New-Object System.Windows.Forms.ToolStripMenuItem
    $FileMenuItem_Exit = New-Object System.Windows.Forms.ToolStripMenuItem

    $FileMenuItem_CreateFiles.Text = "Create Files"
    $FileMenuItem_Browse.Text = "Browse..."
    $FileMenuItem_Exit.Text = "Exit"

    $FileMenuItem_CreateFiles.Add_Click({
            if (ValidateFormFields) {
                $StatusBarLabel.Text = "Creating files..."
                $StatusBar.Refresh()
                CreateFiles -Path $TextBoxPath.Text `
                    -Prefix $TextBoxPrefix.Text `
                    -Suffix $TextBoxSuffix.Text `
                    -Extension $TextBoxExtension.Text `
                    -NumberOfFiles ([int]$TextBoxNumberOfFiles.Text) `
                    -OverwriteExisting $CheckBoxOverwrite.Checked `
                    -OpenFiles $CheckBoxOpenFiles.Checked `
                    -ContentTemplate $TextBoxContentTemplate.Text `
                    -CreationDate $DateTimePickerCreationDate.Value
                $StatusBarLabel.Text = "Files created successfully!"
            }
        })

    $FileMenuItem_Browse.Add_Click({
            $FolderBrowserDialog = New-Object Windows.Forms.FolderBrowserDialog
            $Result = $FolderBrowserDialog.ShowDialog()

            if ($Result -eq [Windows.Forms.DialogResult]::OK) {
                $TextBoxPath.Text = $FolderBrowserDialog.SelectedPath
            }
        })

    $FileMenuItem_Exit.Add_Click({
            $Form.Close()
        })

    $FileMenu.DropDownItems.Add($FileMenuItem_CreateFiles)
    $FileMenu.DropDownItems.Add($FileMenuItem_Browse)
    $FileMenu.DropDownItems.Add($FileMenuItem_Exit)

    $HelpMenuItem_About = New-Object System.Windows.Forms.ToolStripMenuItem
    $HelpMenuItem_Help = New-Object System.Windows.Forms.ToolStripMenuItem

    $HelpMenuItem_About.Text = "About"
    $HelpMenuItem_Help.Text = "Help"

    $HelpMenuItem_About.Add_Click({ ShowAboutDialog })
    $HelpMenuItem_Help.Add_Click({ ShowHelpDialog })

    $HelpMenu.DropDownItems.Add($HelpMenuItem_About)
    $HelpMenu.DropDownItems.Add($HelpMenuItem_Help)

    $MenuBar.Items.Add($FileMenu)
    $MenuBar.Items.Add($HelpMenu)

    $Form.Controls.Add($MenuBar)

    $LabelPath = New-Object Windows.Forms.Label
    $LabelPath.Text = "Path:"
    $LabelPath.Location = New-Object Drawing.Point(20, 25)
    $LabelPath.AutoSize = $true
    $LabelPath.Padding = New-Object System.Windows.Forms.Padding(10, 10, 10, 10)
    $LabelPath.ForeColor = [System.Drawing.Color]::White
    $Form.Controls.Add($LabelPath)

    $TextBoxPath = New-Object Windows.Forms.TextBox
    $TextBoxPath.Text = $DefaultPath
    $TextBoxPath.Location = New-Object Drawing.Point(100, 30)
    $TextBoxPath.Size = New-Object Drawing.Size(550, 30)
    $Form.Controls.Add($TextBoxPath)

    $ButtonBrowse = New-Object Windows.Forms.Button
    $ButtonBrowse.Text = "Browse..."
    $ButtonBrowse.Location = New-Object Drawing.Point(700, 25)
    $ButtonBrowse.Size = New-Object Drawing.Size(100, 50)
    $ButtonBrowse.FlatStyle = $style
    $ButtonBrowse.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
    $ButtonBrowse.ForeColor = [System.Drawing.Color]::White
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
    $CheckBoxPrefix.Add_CheckStateChanged({
            $TextBoxPrefix.Enabled = $CheckBoxPrefix.Checked
        })
    $Form.Controls.Add($CheckBoxPrefix)

    $TextBoxPrefix = New-Object Windows.Forms.TextBox
    $TextBoxPrefix.Text = $DefaultPrefix
    $TextBoxPrefix.Location = New-Object Drawing.Point(100, 80)
    $TextBoxPrefix.Size = New-Object Drawing.Size(300, 30)
    $Form.Controls.Add($TextBoxPrefix)

    $CheckBoxSuffix = New-Object Windows.Forms.CheckBox
    $CheckBoxSuffix.Text = "Suffix:"
    $CheckBoxSuffix.Location = New-Object Drawing.Point(420, 80)
    $CheckBoxSuffix.AutoSize = $true
    $CheckBoxSuffix.Checked = $false
    $CheckBoxSuffix.ForeColor = [System.Drawing.Color]::White
    $CheckBoxSuffix.Add_CheckStateChanged({
            $TextBoxSuffix.Enabled = $CheckBoxSuffix.Checked
        })
    $Form.Controls.Add($CheckBoxSuffix)

    $TextBoxSuffix = New-Object Windows.Forms.TextBox
    $TextBoxSuffix.Text = $DefaultSuffix
    $TextBoxSuffix.Location = New-Object Drawing.Point(500, 80)
    $TextBoxSuffix.Size = New-Object Drawing.Size(300, 30)
    $Form.Controls.Add($TextBoxSuffix)

    $LabelExtension = New-Object Windows.Forms.Label
    $LabelExtension.Text = "Extension:"
    $LabelExtension.Location = New-Object Drawing.Point(20, 130)
    $LabelExtension.AutoSize = $true
    $LabelExtension.ForeColor = [System.Drawing.Color]::White
    $Form.Controls.Add($LabelExtension)

    $TextBoxExtension = New-Object Windows.Forms.TextBox
    $TextBoxExtension.Text = $DefaultExtension
    $TextBoxExtension.Location = New-Object Drawing.Point(100, 130)
    $TextBoxExtension.Size = New-Object Drawing.Size(300, 30)
    $Form.Controls.Add($TextBoxExtension)

    $LabelNumberOfFiles = New-Object Windows.Forms.Label
    $LabelNumberOfFiles.Text = "Number of Files:"
    $LabelNumberOfFiles.Location = New-Object Drawing.Point(420, 130)
    $LabelNumberOfFiles.AutoSize = $true
    $LabelNumberOfFiles.ForeColor = [System.Drawing.Color]::White
    $Form.Controls.Add($LabelNumberOfFiles)

    $TextBoxNumberOfFiles = New-Object Windows.Forms.TextBox
    $TextBoxNumberOfFiles.Text = $DefaultNumberOfFiles
    $TextBoxNumberOfFiles.Location = New-Object Drawing.Point(520, 130)
    $TextBoxNumberOfFiles.Size = New-Object Drawing.Size(100, 30)
    $Form.Controls.Add($TextBoxNumberOfFiles)

    $CheckBoxOverwrite = New-Object Windows.Forms.CheckBox
    $CheckBoxOverwrite.Text = "Overwrite existing files"
    $CheckBoxOverwrite.Location = New-Object Drawing.Point(20, 180)
    $CheckBoxOverwrite.Size = New-Object Drawing.Size(200, 30)
    $CheckBoxOverwrite.Checked = $true
    $CheckBoxOverwrite.ForeColor = [System.Drawing.Color]::White
    $Form.Controls.Add($CheckBoxOverwrite)

    $CheckBoxOpenFiles = New-Object Windows.Forms.CheckBox
    $CheckBoxOpenFiles.Text = "Open files after creation"
    $CheckBoxOpenFiles.Location = New-Object Drawing.Point(20, 220)
    $CheckBoxOpenFiles.Size = New-Object Drawing.Size(200, 30)
    $CheckBoxOpenFiles.ForeColor = [System.Drawing.Color]::White
    $Form.Controls.Add($CheckBoxOpenFiles)

    $LabelContentTemplate = New-Object Windows.Forms.Label
    $LabelContentTemplate.Text = "Content Template:"
    $LabelContentTemplate.Location = New-Object Drawing.Point(20, 260)
    $LabelContentTemplate.AutoSize = $true
    $LabelContentTemplate.ForeColor = [System.Drawing.Color]::White
    $Form.Controls.Add($LabelContentTemplate)

    $TextBoxContentTemplate = New-Object Windows.Forms.TextBox
    $TextBoxContentTemplate.Location = New-Object Drawing.Point(150, 260)
    $TextBoxContentTemplate.Multiline = $true
    $TextBoxContentTemplate.Size = New-Object Drawing.Size(650, 100)
    $Form.Controls.Add($TextBoxContentTemplate)

    $LabelCreationDate = New-Object Windows.Forms.Label
    $LabelCreationDate.Text = "Creation Date:"
    $LabelCreationDate.Location = New-Object Drawing.Point(20, 380)
    $LabelCreationDate.AutoSize = $true
    $LabelCreationDate.ForeColor = [System.Drawing.Color]::White
    $Form.Controls.Add($LabelCreationDate)

    $DateTimePickerCreationDate = New-Object Windows.Forms.DateTimePicker
    $DateTimePickerCreationDate.Format = [Windows.Forms.DateTimePickerFormat]::Custom
    $DateTimePickerCreationDate.CustomFormat = "yyyy-MM-dd HH:mm:ss"
    $DateTimePickerCreationDate.Location = New-Object Drawing.Point(150, 380)
    $Form.Controls.Add($DateTimePickerCreationDate)

    $ButtonCreate = New-Object Windows.Forms.Button
    $ButtonCreate.Text = "Create Files"
    $ButtonCreate.Location = New-Object Drawing.Point(330, 460)
    $ButtonCreate.Size = New-Object Drawing.Size(150, 40)
    $ButtonCreate.FlatStyle = $Style
    $ButtonCreate.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
    $ButtonCreate.ForeColor = [System.Drawing.Color]::White
    $ButtonCreate.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $ButtonCreate.Add_Click({
            if (ValidateFormFields) {
                $StatusBarLabel.Text = "Creating files..."
                $StatusBar.Refresh()
                CreateFiles -Path $textBoxPath.Text `
                    -Prefix $TextBoxPrefix.Text `
                    -Suffix $TextBoxSuffix.Text `
                    -Extension $TextBoxExtension.Text `
                    -NumberOfFiles ([int]$TextBoxNumberOfFiles.Text) `
                    -OverwriteExisting $CheckBoxOverwrite.Checked `
                    -OpenFiles $CheckBoxOpenFiles.Checked `
                    -ContentTemplate $TextBoxContentTemplate.Text `
                    -CreationDate $DateTimePickerCreationDate.Value
                $StatusBarLabel.Text = "Files created successfully!"
            }
        })
    $Form.Controls.Add($ButtonCreate)

    $StatusBar = New-Object System.Windows.Forms.StatusStrip
    $StatusBar.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $StatusBar.ForeColor = [System.Drawing.Color]::White
    $StatusBarLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $StatusBarLabel.Text = "Current Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $StatusBar.Items.Add($StatusBarLabel)
    $Form.Controls.Add($StatusBar)

    $Form.Add_Shown({ $Form.Activate() })

    $Form.ShowDialog()
}

Function ValidateFormFields {
    if ([string]::IsNullOrWhiteSpace($TextBoxPath.Text) -or
        [string]::IsNullOrWhiteSpace($TextBoxExtension.Text) -or
        [string]::IsNullOrWhiteSpace($TextBoxNumberOfFiles.Text) -or
        -not [int]::TryParse($TextBoxNumberOfFiles.Text, [ref]$null) -or
        ([string]::IsNullOrWhiteSpace($TextBoxContentTemplate.Text) -and $CheckBoxOpenFiles.Checked)) {
        [System.Windows.Forms.MessageBox]::Show("Please fill all fields with valid values.", "Error", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
        return $false
    }
    return $true
}

Function CreateFiles {
    [CmdletBinding()]
    param (
        [string]$Path,
        [string]$Prefix,
        [string]$Suffix,
        [string]$Extension,
        [int]$NumberOfFiles,
        [bool]$OverwriteExisting,
        [bool]$OpenFiles,
        [string]$ContentTemplate,
        [datetime]$CreationDate
    )
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
        }
        if ($OpenFiles) {
            Invoke-Item -Path $FullFilePath
        }
    }
}

FileCreationForm
