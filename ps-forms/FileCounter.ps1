Function GetFileCount {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,
        [switch]$Recurse,
        [switch]$IncludeHidden
    )
    $Options = @{}
    if ($Recurse) {
        $Options += @{Recurse = $true }
    }
    if ($IncludeHidden) {
        $Options += @{Force = $true }
    }
    $Files = Get-ChildItem -Path $Path @Options | Where-Object { !$_.PSIsContainer }
    [PSCustomObject]@{
        Path  = $Path
        Count = $Files.Count
    }
}

Add-Type -AssemblyName System.Windows.Forms
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "File Count"
$Form.Width = 300
$Form.Height = 200
$Form.StartPosition = "CenterScreen"

$Label = New-Object System.Windows.Forms.Label
$Label.Location = New-Object System.Drawing.Point(10, 20)
$Label.Size = New-Object System.Drawing.Size(260, 20)
$Label.Text = "Enter the path to count files in:"
$Form.Controls.Add($Label)

$Textbox = New-Object System.Windows.Forms.TextBox
$Textbox.Location = New-Object System.Drawing.Point(10, 50)
$Textbox.Size = New-Object System.Drawing.Size(260, 20)
$Form.Controls.Add($Textbox)

$CheckboxRecurse = New-Object System.Windows.Forms.CheckBox
$CheckboxRecurse.Location = New-Object System.Drawing.Point(10, 80)
$CheckboxRecurse.Size = New-Object System.Drawing.Size(260, 20)
$CheckboxRecurse.Text = "Include subfolders"
$Form.Controls.Add($CheckboxRecurse)

$CheckboxHidden = New-Object System.Windows.Forms.CheckBox
$CheckboxHidden.Location = New-Object System.Drawing.Point(10, 110)
$CheckboxHidden.Size = New-Object System.Drawing.Size(260, 20)
$CheckboxHidden.Text = "Include hidden files"
$Form.Controls.Add($CheckboxHidden)

$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Point(10, 140)
$Button.Size = New-Object System.Drawing.Size(260, 20)
$Button.Text = "Count Files"
$Button.Add_Click({
        $Path = $Textbox.Text
        $Recurse = $CheckboxRecurse.Checked
        $Hidden = $CheckboxHidden.Checked
        $FileCount = GetFileCount -Path $Path -Recurse:$Recurse -IncludeHidden:$Hidden
        [System.Windows.Forms.MessageBox]::Show("There are $($FileCount.Count) files in $($FileCount.Path)")
    })
$Form.Controls.Add($Button)

$Form.ShowDialog() | Out-Null
