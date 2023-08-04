Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Function FileCreationForm {
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
    $Form.BackColor = [System.Drawing.Color]::FromArgb(41, 41, 41)
    $Form.ForeColor = [System.Drawing.Color]::White 
    
    $Style = [System.Windows.Forms.FlatStyle]::Flat

    $LabelPath = New-Object Windows.Forms.Label
    $LabelPath.Text = "Path:"
    $LabelPath.Location = New-Object Drawing.Point(20, 25)
    $LabelPath.AutoSize = $true
    $Form.Controls.Add($LabelPath)

    $TextBoxPath = New-Object Windows.Forms.TextBox
    $TextBoxPath.Text = $DefaultPath
    $TextBoxPath.Location = New-Object Drawing.Point(100, 25)
    $TextBoxPath.Size = New-Object Drawing.Size(550, 30)
    $Form.Controls.Add($TextBoxPath)

    $ButtonBrowse = New-Object Windows.Forms.Button
    $ButtonBrowse.Text = "Browse..."
    $ButtonBrowse.Location = New-Object Drawing.Point(660, 25)
    $ButtonBrowse.Size = New-Object Drawing.Size(100, 30)
    $ButtonBrowse.FlatStyle = $style
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
    $CheckBoxPrefix.Add_CheckStateChanged({
            $TextBoxPrefix.Enabled = $CheckBoxPrefix.Checked
        })
    $Form.Controls.Add($CheckBoxPrefix)

    $TextBoxPrefix = New-Object Windows.Forms.TextBox
    $TextBoxPrefix.Text = $DefaultPrefix
    $TextBoxPrefix.Location = New-Object Drawing.Point(100, 80)
    $TextBoxPrefix.Size = New-Object Drawing.Size(300, 30)
    $TextBoxPrefix.Enabled = $false
    $Form.Controls.Add($TextBoxPrefix)
    $TextBoxPrefix.Enabled = $true

    $CheckBoxSuffix = New-Object Windows.Forms.CheckBox
    $CheckBoxSuffix.Text = "Suffix:"
    $CheckBoxSuffix.Location = New-Object Drawing.Point(420, 80)
    $CheckBoxSuffix.AutoSize = $true
    $CheckBoxSuffix.Checked = $false
    $CheckBoxSuffix.Add_CheckStateChanged({
            $TextBoxSuffix.Enabled = $CheckBoxSuffix.Checked
        })
    $Form.Controls.Add($CheckBoxSuffix)

    $TextBoxSuffix = New-Object Windows.Forms.TextBox
    $TextBoxSuffix.Text = $DefaultSuffix
    $TextBoxSuffix.Location = New-Object Drawing.Point(500, 80)
    $TextBoxSuffix.Size = New-Object Drawing.Size(300, 30)
    $TextBoxSuffix.Enabled = $false
    $Form.Controls.Add($TextBoxSuffix)

    $LabelExtension = New-Object Windows.Forms.Label
    $LabelExtension.Text = "Extension:"
    $LabelExtension.Location = New-Object Drawing.Point(20, 130)
    $LabelExtension.AutoSize = $true
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
    $Form.Controls.Add($LabelNumberOfFiles)

    $TextBoxNumberOfFiles = New-Object Windows.Forms.TextBox
    $TextBoxNumberOfFiles.Text = $DefaultNumberOfFiles
    $TextBoxNumberOfFiles.Location = New-Object Drawing.Point(520, 130)
    $TextBoxNumberOfFiles.Size = New-Object Drawing.Size(100, 30)
    $Form.Controls.Add($TextBoxNumberOfFiles)

    $CheckBoxOverwrite = New-Object Windows.Forms.CheckBox
    $CheckBoxOverwrite.Text = "Overwrite existing files"
    $CheckBoxOverwrite.Location = New-Object Drawing.Point(20, 180)
    $CheckBoxOverwrite.Size = New-Object Drawing.Size(100, 30)
    $CheckBoxOverwrite.Checked = $true
    $Form.Controls.Add($CheckBoxOverwrite)

    $CheckBoxOpenFiles = New-Object Windows.Forms.CheckBox
    $CheckBoxOpenFiles.Text = "Open files after creation"
    $CheckBoxOpenFiles.Location = New-Object Drawing.Point(20, 220)
    $CheckBoxOpenFiles.Size = New-Object Drawing.Size(100, 30)
    $Form.Controls.Add($CheckBoxOpenFiles)

    $LabelContentTemplate = New-Object Windows.Forms.Label
    $LabelContentTemplate.Text = "Content Template:"
    $LabelContentTemplate.Location = New-Object Drawing.Point(20, 260)
    $LabelContentTemplate.AutoSize = $true
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
    $ButtonCreate.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $ButtonCreate.Add_Click({
            if ([string]::IsNullOrWhiteSpace($TextBoxPath.Text) -or
                [string]::IsNullOrWhiteSpace($TextBoxExtension.Text) -or
                [string]::IsNullOrWhiteSpace($TextBoxNumberOfFiles.Text) -or
                -not [int]::TryParse($TextBoxNumberOfFiles.Text, [ref]$null) -or
            ([string]::IsNullOrWhiteSpace($TextBoxContentTemplate.Text) -and $CheckBoxOpenFiles.Checked)) {
                [System.Windows.Forms.MessageBox]::Show("Please fill all fields with valid values.", "Error", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
            }
            else {
                $Prefix = if ($CheckBoxPrefix.Checked) { $TextBoxPrefix.Text } else { "" }
                $Suffix = if ($CheckBoxSuffix.Checked) { $TextBoxSuffix.Text } else { "" }
                CreateFiles -Path $textBoxPath.Text `
                    -Prefix $Prefix `
                    -Suffix $Suffix `
                    -Extension $TextBoxExtension.Text `
                    -NumberOfFiles ([int]$TextBoxNumberOfFiles.Text) `
                    -OverwriteExisting $CheckBoxOverwrite.Checked `
                    -OpenFiles $CheckBoxOpenFiles.Checked `
                    -ContentTemplate $TextBoxContentTemplate.Text `
                    -CreationDate $DateTimePickerCreationDate.Value
                [System.Windows.Forms.MessageBox]::Show("Files created successfully!", "Success", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Information)
            }
        })
    $Form.Controls.Add($ButtonCreate)
    $Form.ShowDialog()
}
Function CreateFiles {
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
