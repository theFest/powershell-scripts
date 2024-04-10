Function Start-GitHubPullRequestViewer {
    <#
    .SYNOPSIS
    Displays GitHub pull requests based on repository, branch, and status.

    .DESCRIPTION
    This function creates a graphical user interface for viewing GitHub pull requests. Users can specify a repository, branch, and status (Open, Closed, or All) to filter the pull requests displayed.

    .EXAMPLE
    Start-GitHubPullRequestViewer
    
    .NOTES
    -GitHub CLI (gh) must be installed and available in the system path for this function to work properly.
    v0.0.1
    #>
    param()
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "GitHub Pull Request Viewer"
    $Form.Size = New-Object System.Drawing.Size(1100, 810)
    $Form.StartPosition = "CenterScreen"
    $Form.BackColor = "#1e1e1e"
    $Controls = @{}
    $Controls['RepositoryLabel'] = New-Object System.Windows.Forms.Label
    $Controls['RepositoryLabel'].Text = "Repository:"
    $Controls['RepositoryLabel'].Location = New-Object System.Drawing.Point(30, 30)
    $Controls['RepositoryLabel'].AutoSize = $true
    $Controls['RepositoryLabel'].ForeColor = "White"
    $Controls['BranchLabel'] = New-Object System.Windows.Forms.Label
    $Controls['BranchLabel'].Text = "Branch:"
    $Controls['BranchLabel'].Location = New-Object System.Drawing.Point(30, 70)
    $Controls['BranchLabel'].AutoSize = $true
    $Controls['BranchLabel'].ForeColor = "White"
    $Controls['StatusLabel'] = New-Object System.Windows.Forms.Label
    $Controls['StatusLabel'].Text = "Status:"
    $Controls['StatusLabel'].Location = New-Object System.Drawing.Point(30, 110)
    $Controls['StatusLabel'].AutoSize = $true
    $Controls['StatusLabel'].ForeColor = "White"
    $Controls['RepositoryInput'] = New-Object System.Windows.Forms.TextBox
    $Controls['RepositoryInput'].Location = New-Object System.Drawing.Point(120, 30)
    $Controls['RepositoryInput'].Size = New-Object System.Drawing.Size(600, 30)
    $Controls['RepositoryInput'].BackColor = "#333333"
    $Controls['RepositoryInput'].ForeColor = "White"
    $Controls['BranchInput'] = New-Object System.Windows.Forms.TextBox
    $Controls['BranchInput'].Location = New-Object System.Drawing.Point(120, 70)
    $Controls['BranchInput'].Size = New-Object System.Drawing.Size(600, 30)
    $Controls['BranchInput'].BackColor = "#333333"
    $Controls['BranchInput'].ForeColor = "White"
    $Controls['StatusComboBox'] = New-Object System.Windows.Forms.ComboBox
    $Controls['StatusComboBox'].Location = New-Object System.Drawing.Point(120, 110)
    $Controls['StatusComboBox'].Size = New-Object System.Drawing.Size(200, 30)
    $Controls['StatusComboBox'].BackColor = "#333333"
    $Controls['StatusComboBox'].ForeColor = "White"
    $Controls['StatusComboBox'].FlatStyle = "Flat"
    $Controls['StatusComboBox'].DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $Controls['StatusComboBox'].Items.AddRange(@('Open', 'Closed', 'All'))
    $Controls['OutputTextBox'] = New-Object System.Windows.Forms.RichTextBox
    $Controls['OutputTextBox'].Location = New-Object System.Drawing.Point(30, 160)
    $Controls['OutputTextBox'].Size = New-Object System.Drawing.Size(1020, 600)
    $Controls['OutputTextBox'].BackColor = "#333333"
    $Controls['OutputTextBox'].ForeColor = "White"
    $Controls['OutputTextBox'].ScrollBars = "Vertical"
    $Controls['OutputTextBox'].Font = New-Object System.Drawing.Font("Consolas", 10)
    $Controls['ZoomInButton'] = New-Object System.Windows.Forms.Button
    $Controls['ZoomInButton'].Location = New-Object System.Drawing.Point(950, 30)
    $Controls['ZoomInButton'].Size = New-Object System.Drawing.Size(90, 40)
    $Controls['ZoomInButton'].Text = "Zoom In"
    $Controls['ZoomInButton'].BackColor = "#007bff"
    $Controls['ZoomInButton'].ForeColor = "White"
    $Controls['ZoomInButton'].FlatStyle = "Flat"
    $Controls['ZoomOutButton'] = New-Object System.Windows.Forms.Button
    $Controls['ZoomOutButton'].Location = New-Object System.Drawing.Point(950, 80)
    $Controls['ZoomOutButton'].Size = New-Object System.Drawing.Size(90, 40)
    $Controls['ZoomOutButton'].Text = "Zoom Out"
    $Controls['ZoomOutButton'].BackColor = "#007bff"
    $Controls['ZoomOutButton'].ForeColor = "White"
    $Controls['ZoomOutButton'].FlatStyle = "Flat"
    $Controls['Button'] = New-Object System.Windows.Forms.Button
    $Controls['Button'].Location = New-Object System.Drawing.Point(750, 110)
    $Controls['Button'].Size = New-Object System.Drawing.Size(150, 40)
    $Controls['Button'].Text = "Load PRs"
    $Controls['Button'].BackColor = "#007bff"
    $Controls['Button'].ForeColor = "White"
    $Controls['Button'].FlatStyle = "Flat"
    foreach ($Control in $Controls.Values) {
        $Form.Controls.Add($Control)
    }
    $Controls['Button'].Add_Click({
            try {
                $Repository = $Controls['RepositoryInput'].Text
                $Branch = $Controls['BranchInput'].Text
                $Status = $Controls['StatusComboBox'].SelectedItem
                if ($Repository -eq "" -or $Branch -eq "") {
                    throw "Repository and Branch fields cannot be empty."
                }
                $Controls['OutputTextBox'].Text = "Loading Pull Requests..."
                $ArgsList = @("pr", "list", "--repo", $Repository, "--head", $Branch)
                if ($Status -ne 'All') {
                    $ArgsList += "--state=$Status"
                }
                $PullRequests = gh $ArgsList
                if ($null -ne $PullRequests) {
                    $FormattedOutput = $PullRequests -replace "(?<=\S)\t", "`t`t" -replace "`r`n", "`r`n`t"
                    $Controls['OutputTextBox'].Text = $FormattedOutput
                }
                else {
                    [System.Windows.Forms.MessageBox]::Show($Message, "No Pull Requests found", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
            catch [System.Management.Automation.CommandNotFoundException] {
                [System.Windows.Forms.MessageBox]::Show($Message, "GitHub CLI (gh) is not installed or not found in the system path!", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
            catch {
                if ($_.Exception.Message -match "Run: gh auth login") {
                    [System.Windows.Forms.MessageBox]::Show($Message, "Please authenticate with GitHub CLI by running 'gh auth login'!", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
                else {
                    [System.Windows.Forms.MessageBox]::Show($Message, $_.Exception.Message, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                }
            }
        })
    $Controls['ZoomInButton'].Add_Click({
            $Controls['OutputTextBox'].ZoomFactor += 0.1
        })
    $Controls['ZoomOutButton'].Add_Click({
            $Controls['OutputTextBox'].ZoomFactor -= 0.1
        })
    $Form.ForeColor = "White"
    $Form.ShowDialog()
}
