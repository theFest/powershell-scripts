Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

Function ShowAboutDialog {
    [System.Windows.Forms.MessageBox]::Show("FW File Creation Form`nVersion 0.0.0.8", "About", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

Function ShowHelpDialog {
    [System.Windows.Forms.MessageBox]::Show(@"
This application allows you to create multiple files with custom content.

Enhancements in Version 0.0.0.8:
...
Enjoy creating files with even more features and options!

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
    $Form.Size = New-Object Drawing.Size(815, 755)
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
    $TextBoxContentTemplate.ScrollBars = "Both" # Add auto-scroll functionality
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

    $CheckBoxIncrementalNumbering = New-Object Windows.Forms.CheckBox
    $CheckBoxIncrementalNumbering.Text = "Use Incremental Numbering"
    $CheckBoxIncrementalNumbering.Location = New-Object Drawing.Point(20, 460)
    $CheckBoxIncrementalNumbering.AutoSize = $true
    $CheckBoxIncrementalNumbering.ForeColor = [System.Drawing.Color]::White
    $CheckBoxIncrementalNumbering.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($CheckBoxIncrementalNumbering)

    $CheckBoxRandomizeContent = New-Object Windows.Forms.CheckBox
    $CheckBoxRandomizeContent.Text = "Randomize File Content"
    $CheckBoxRandomizeContent.Location = New-Object Drawing.Point(20, 490)
    $CheckBoxRandomizeContent.AutoSize = $true
    $CheckBoxRandomizeContent.ForeColor = [System.Drawing.Color]::White
    $CheckBoxRandomizeContent.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($CheckBoxRandomizeContent)

    $LabelFileSize = New-Object Windows.Forms.Label
    $LabelFileSize.Text = "File Size (KB):"
    $LabelFileSize.Location = New-Object Drawing.Point(296, 460)
    $LabelFileSize.AutoSize = $true
    $LabelFileSize.ForeColor = [System.Drawing.Color]::White
    $LabelFileSize.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($LabelFileSize)

    $NumericUpDownFileSize = New-Object Windows.Forms.NumericUpDown
    $NumericUpDownFileSize.Location = New-Object Drawing.Point(450, 455)
    $NumericUpDownFileSize.Size = New-Object Drawing.Size(70, 30)
    $NumericUpDownFileSize.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $Form.Controls.Add($NumericUpDownFileSize)

    $CheckBoxCompressFiles = New-Object Windows.Forms.CheckBox
    $CheckBoxCompressFiles.Text = "Compress Files"
    $CheckBoxCompressFiles.Location = New-Object Drawing.Point(20, 520)
    $CheckBoxCompressFiles.AutoSize = $true
    $CheckBoxCompressFiles.ForeColor = [System.Drawing.Color]::White
    $CheckBoxCompressFiles.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($CheckBoxCompressFiles)

    $LabelFilePermissions = New-Object Windows.Forms.Label
    $LabelFilePermissions.Text = "File Permissions:"
    $LabelFilePermissions.Location = New-Object Drawing.Point(296, 490)
    $LabelFilePermissions.AutoSize = $true
    $LabelFilePermissions.ForeColor = [System.Drawing.Color]::White
    $LabelFilePermissions.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($LabelFilePermissions)

    $ComboBoxFilePermissions = New-Object Windows.Forms.ComboBox
    $ComboBoxFilePermissions.Location = New-Object Drawing.Point(450, 485)
    $ComboBoxFilePermissions.Size = New-Object Drawing.Size(200, 30)
    $ComboBoxFilePermissions.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $ComboBoxFilePermissions.Items.Add("Read-Only")
    $ComboBoxFilePermissions.Items.Add("Read-Write")
    $ComboBoxFilePermissions.Items.Add("Full Control")
    $Form.Controls.Add($ComboBoxFilePermissions)

    $CheckBoxEncryption = New-Object Windows.Forms.CheckBox
    $CheckBoxEncryption.Text = "Encrypt Files"
    $CheckBoxEncryption.Location = New-Object Drawing.Point(20, 550)
    $CheckBoxEncryption.AutoSize = $true
    $CheckBoxEncryption.ForeColor = [System.Drawing.Color]::White
    $CheckBoxEncryption.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($CheckBoxEncryption)

    $LabelCreationDateRange = New-Object Windows.Forms.Label
    $LabelCreationDateRange.Text = "Creation Date Range:"
    $LabelCreationDateRange.Location = New-Object Drawing.Point(20, 590)
    $LabelCreationDateRange.AutoSize = $true
    $LabelCreationDateRange.ForeColor = [System.Drawing.Color]::White
    $LabelCreationDateRange.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($LabelCreationDateRange)

    $DateTimePickerStartDate = New-Object Windows.Forms.DateTimePicker
    $DateTimePickerStartDate.Format = [Windows.Forms.DateTimePickerFormat]::Custom
    $DateTimePickerStartDate.CustomFormat = "yyyy-MM-dd HH:mm:ss"
    $DateTimePickerStartDate.Location = New-Object Drawing.Point(200, 585)
    $DateTimePickerStartDate.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $Form.Controls.Add($DateTimePickerStartDate)

    $LabelTo = New-Object Windows.Forms.Label
    $LabelTo.Text = "to"
    $LabelTo.Location = New-Object Drawing.Point(330, 590)
    $LabelTo.AutoSize = $true
    $LabelTo.ForeColor = [System.Drawing.Color]::White
    $LabelTo.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Form.Controls.Add($LabelTo)

    $DateTimePickerEndDate = New-Object Windows.Forms.DateTimePicker
    $DateTimePickerEndDate.Format = [Windows.Forms.DateTimePickerFormat]::Custom
    $DateTimePickerEndDate.CustomFormat = "yyyy-MM-dd HH:mm:ss"
    $DateTimePickerEndDate.Location = New-Object Drawing.Point(415, 585)
    $DateTimePickerEndDate.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Regular)
    $Form.Controls.Add($DateTimePickerEndDate)

    $ButtonCreate = New-Object Windows.Forms.Button
    $ButtonCreate.Text = "Create Files"
    $ButtonCreate.Location = New-Object Drawing.Point(330, 630)
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
        $Prefix = if ($CheckBoxPrefix.Checked) { $TextBoxPrefix.Text } else { "" }
        $Suffix = if ($CheckBoxSuffix.Checked) { $TextBoxSuffix.Text } else { "" }
        $Extension = if ($ComboBoxExtension.SelectedItem) { $ComboBoxExtension.SelectedItem.ToString() } else { "" }
        $NumberOfFiles = [int]$TextBoxNumberOfFiles.Text
        $Overwrite = $CheckBoxOverwrite.Checked
        $OpenFiles = $CheckBoxOpenFiles.Checked
        $ContentTemplate = $TextBoxContentTemplate.Text
        $CreationDate = $DateTimePickerCreationDate.Value
        $IncrementalNumbering = $CheckBoxIncrementalNumbering.Checked
        $RandomizeContent = $CheckBoxRandomizeContent.Checked
        $FileSizeKB = if ($RandomizeContent) { $NumericUpDownFileSize.Value } else { 0 }
        $CompressFiles = $CheckBoxCompressFiles.Checked
        $FilePermissions = if ($ComboBoxFilePermissions.SelectedItem) { $ComboBoxFilePermissions.SelectedItem.ToString() } else { "" }
        $EncryptFiles = $CheckBoxEncryption.Checked
        $CreationDateRange = $CheckBoxCreationDateRange.Checked
        $StartDate = $DateTimePickerStartDate.Value
        $EndDate = $DateTimePickerEndDate.Value
        $FilesCreated = 0
        for ($i = 1; $i -le $NumberOfFiles; $i++) {
            $FileName = "{0}{1}{2}.{3}" -f $Prefix, $i, $Suffix, $Extension
            $FullFilePath = Join-Path -Path $Path -ChildPath $FileName
            if (-not (Test-Path -Path $FullFilePath) -or $Overwrite) {
                if ($ContentTemplate) {
                    $FileContent = $ContentTemplate -replace '\$FileName', $FileName -replace '\$Index', $i
                    if ($RandomizeContent) {
                        $RandomContent = Get-Random -Count $FileSizeKB -InputObject $FileContent.ToCharArray()
                        $FileContent = $RandomContent -join ''
                    }
                    Set-Content -Path $FullFilePath -Value $FileContent -Force
                }
                else {
                    New-Item -ItemType File -Path $FullFilePath -Force | Out-Null
                }
                if ($FilePermissions -eq "Read-Only") {
                (Get-Item $FullFilePath).IsReadOnly = $true
                }
                elseif ($FilePermissions -eq "Read-Write") {
                (Get-Item $FullFilePath).IsReadOnly = $false
                }
                elseif ($FilePermissions -eq "Full Control") {
                    $acl = Get-Acl $FullFilePath
                    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "FullControl", "Allow")
                    $acl.SetAccessRule($rule)
                    Set-Acl -Path $FullFilePath -AclObject $acl
                }
                if ($CreationDate) {
                    $FileInfo = Get-Item -Path $FullFilePath
                    $FileInfo.LastWriteTime = $CreationDate
                    $FileInfo.LastAccessTime = $CreationDate
                    [System.IO.File]::SetCreationTime($FullFilePath, $CreationDate)
                }
                if ($IncrementalNumbering) {
                    $FileName = "{0}{1}{2}.{3}" -f $Prefix, ($i + 1), $Suffix, $Extension
                    $FullFilePath = Join-Path -Path $Path -ChildPath $FileName
                }
                if ($CompressFiles) {
                    $CompressedFilePath = $FullFilePath + ".gz"
                    Write-Host "Compressing file: $FullFilePath"
                    try {
                        $FileContent = Get-Content -Path $FullFilePath -Raw
                        $gzipStream = New-Object IO.Compression.GZipStream([IO.File]::Create($CompressedFilePath), [IO.Compression.CompressionMode]::Compress)
                        $gzipStream.Write($FileContent, 0, $FileContent.Length)
                        $gzipStream.Close()
                    }
                    catch {
                        Write-Host "Error compressing file: $_"
                    }
                }
                if ($EncryptFiles) {
                    $EncryptedFilePath = $FullFilePath + ".enc"
                    Write-Host "Encrypting file: $FullFilePath"
                    try {
                        $FileContent = Get-Content -Path $FullFilePath -Raw
                        $encryptionKey = New-Object Byte[] 32
                        $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::Create()
                        $rng.GetBytes($encryptionKey)
                        $aes = New-Object Security.Cryptography.AesManaged
                        $aes.Key = $encryptionKey
                        $aes.IV = $aes.BlockSize / 8
                        $encryptor = $aes.CreateEncryptor()
                        $memoryStream = New-Object IO.MemoryStream
                        $cryptoStream = New-Object Security.Cryptography.CryptoStream $memoryStream, $encryptor, [Security.Cryptography.CryptoStreamMode]::Write
                        $cryptoStream.Write($FileContent, 0, $FileContent.Length)
                        $cryptoStream.FlushFinalBlock()
                        $cryptoStream.Close()
                        [IO.File]::WriteAllBytes($EncryptedFilePath, $memoryStream.ToArray())
                    }
                    catch {
                        Write-Host "Error encrypting file: $_"
                    }
                }
                if ($CreationDateRange) {
                    $RandomDate = Get-Random -Minimum $StartDate.Ticks -Maximum $EndDate.Ticks
                    $CreationDate = Get-Date -Date ([System.DateTime]::new($RandomDate))
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
            [System.Windows.Forms.MessageBox]::Show("Files created successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        }
        else {
            [System.Windows.Forms.MessageBox]::Show("No files were created. Please check the form fields and try again.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Please fill all fields with valid values!`n(at least choose File Extension from dropdown)", "Error", [Windows.Forms.MessageBoxButtons]::OK, [Windows.Forms.MessageBoxIcon]::Error)
    }
}

FileCreationForm
