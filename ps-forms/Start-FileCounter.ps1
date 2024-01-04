Function Start-FileCounter {
    <#
    .SYNOPSIS
    Count files in a specified directory with options for subfolders and hidden files using PS/FORMS GUI.

    .DESCRIPTION
    This function launches a Windows Form application to count files in a specified directory, it provides options to include subfolders and hidden files in the count.

    .PARAMETER InitialPath
    NotMandatory - specifies the initial directory path. If not provided, the user can input the path via the form.

    .EXAMPLE
    Start-FileCounter

    .NOTES
    0.4.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$InitialPath = ""
    )
    BEGIN {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
    }
    PROCESS {
        $Form = New-Object System.Windows.Forms.Form
        $Form.Text = "FW File Counter"
        $Form.Width = 400
        $Form.Height = 300
        $Form.StartPosition = "CenterScreen"
        $Form.BackColor = "#333333"
        $MenuBar = New-Object System.Windows.Forms.MenuStrip
        $MenuFile = $MenuBar.Items.Add("File")
        $MenuHelp = $MenuBar.Items.Add("Help")
        $MenuItemOpen = New-Object System.Windows.Forms.ToolStripMenuItem
        $MenuItemOpen.Text = "Open"
        $MenuItemOpen.Add_Click({
                $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
                $DialogResult = $FolderBrowser.ShowDialog()
                if ($DialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
                    $Textbox.Text = $FolderBrowser.SelectedPath
                }
            })
        $MenuFile.DropDownItems.Add($MenuItemOpen)
        $MenuItemAbout = New-Object System.Windows.Forms.ToolStripMenuItem
        $MenuItemAbout.Text = "About"
        $MenuItemAbout.Add_Click({
                [System.Windows.Forms.MessageBox]::Show("FW File Counter App`r`nVersion: 0.4.1", "About", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            })
        $MenuHelp.DropDownItems.Add($MenuItemAbout)
        $Form.Controls.Add($MenuBar)
        $Label = New-Object System.Windows.Forms.Label
        $Label.Location = New-Object System.Drawing.Point(10, 30)
        $Label.Size = New-Object System.Drawing.Size(350, 20)
        $Label.ForeColor = "White"
        $Label.Text = "Declare the path to count files in and press Count Files"
        $Form.Controls.Add($Label)
        $Textbox = New-Object System.Windows.Forms.TextBox
        $Textbox.Location = New-Object System.Drawing.Point(10, 60)
        $Textbox.Size = New-Object System.Drawing.Size(250, 20)
        $Textbox.BackColor = "#555555"
        $Textbox.ForeColor = "White"
        $Form.Controls.Add($Textbox)
        $ButtonBrowse = New-Object System.Windows.Forms.Button
        $ButtonBrowse.Location = New-Object System.Drawing.Point(280, 60)
        $ButtonBrowse.Size = New-Object System.Drawing.Size(80, 20)
        $ButtonBrowse.Text = "Browse"
        $ButtonBrowse.BackColor = "#555555"
        $ButtonBrowse.ForeColor = "White"
        $ButtonBrowse.Add_Click({
                $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
                $DialogResult = $FolderBrowser.ShowDialog()
                if ($DialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
                    $Textbox.Text = $FolderBrowser.SelectedPath
                }
            })
        $Form.Controls.Add($ButtonBrowse)
        $CheckboxRecurse = New-Object System.Windows.Forms.CheckBox
        $CheckboxRecurse.Location = New-Object System.Drawing.Point(10, 100)
        $CheckboxRecurse.Size = New-Object System.Drawing.Size(350, 20)
        $CheckboxRecurse.ForeColor = "White"
        $CheckboxRecurse.Text = "Include subfolders"
        $CheckboxRecurse.BackColor = "#333333"
        $Form.Controls.Add($CheckboxRecurse)
        $CheckboxHidden = New-Object System.Windows.Forms.CheckBox
        $CheckboxHidden.Location = New-Object System.Drawing.Point(10, 130)
        $CheckboxHidden.Size = New-Object System.Drawing.Size(350, 20)
        $CheckboxHidden.ForeColor = "White"
        $CheckboxHidden.Text = "Include hidden files"
        $CheckboxHidden.BackColor = "#333333"
        $Form.Controls.Add($CheckboxHidden)
        $Button = New-Object System.Windows.Forms.Button
        $Button.Location = New-Object System.Drawing.Point(10, 170)
        $Button.Size = New-Object System.Drawing.Size(350, 20)
        $Button.Text = "Count Files"
        $Button.BackColor = "#555555"
        $Button.ForeColor = "White"
        $Button.Add_Click({
                $Path = $Textbox.Text
                $Recurse = $CheckboxRecurse.Checked
                $Hidden = $CheckboxHidden.Checked
                $Options = @{}
                if ($Recurse) {
                    $Options += @{ Recurse = $true }
                }
                if ($Hidden) {
                    $Options += @{ Force = $true }
                }
                $Files = Get-ChildItem -Path $Path @Options | Where-Object { !$_.PSIsContainer }
                $FileCount = [PSCustomObject]@{
                    Path  = $Path
                    Count = $Files.Count
                }
                $LabelInfo.Text = "Directory: $($FileCount.Path)`r`nFiles: $($FileCount.Count)"
            })
        $Form.Controls.Add($Button)
        $LabelInfo = New-Object System.Windows.Forms.Label
        $LabelInfo.Location = New-Object System.Drawing.Point(10, 200)
        $LabelInfo.Size = New-Object System.Drawing.Size(350, 40)
        $LabelInfo.ForeColor = "White"
        $LabelInfo.Text = ""
        $Form.Controls.Add($LabelInfo)
        if ($InitialPath -ne "") {
            $Textbox.Text = $InitialPath
        }
        $Form.ShowDialog() | Out-Null
    }
    END {
        if ($null -ne $Form) {
            $Form.Dispose()
        }
    }
}
