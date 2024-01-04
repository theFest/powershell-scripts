Function New-WebBrowserWindow {
    <#
    .SYNOPSIS
    Creates a new window with an embedded web browser.

    .DESCRIPTION
    This function creates a window with web browser allowing navigation to different search engines and functionalities like title, dimensions, search provider, browsing history, refresh, new tabs and more.

    .PARAMETER Title
    NotMandatory - title of the browser window, default is "PS Browser Window".
    .PARAMETER Width
    NotMandatory - specifies the width of the browser window, default is 1600 pixels.
    .PARAMETER Height
    NotMandatory - specifies the height of the browser window, default is 900 pixels.
    .PARAMETER SearchProvider
    NotMandatory - search provider to be used for initial navigation, available options are: "Google", "Bing", "DuckDuckGo", "Yahoo", "Ask".
    .PARAMETER Resizable
    NotMandatory - specifies whether the browser window is resizable.
    .PARAMETER FullScreen
    NotMandatory - specifies whether the browser window should open in full-screen mode.
    .PARAMETER ClearCache
    NotMandatory - clear the browser cache before closing the window.

    .EXAMPLE
    New-WebBrowserWindow -Resizable -ClearCache
    New-WebBrowserWindow -Width 1600 -Height 1200 -SearchProvider Bing

    .NOTES
    v0.0.4
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Title = "PS Browser Window",

        [Parameter(Mandatory = $false, Position = 1)]
        [int]$Width = 1600,

        [Parameter(Mandatory = $false, Position = 2)]
        [int]$Height = 900,

        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateSet("Google", "Bing", "DuckDuckGo", "Yahoo", "Ask")]
        [string]$SearchProvider = "Google",

        [Parameter(Mandatory = $false)]
        [switch]$Resizable,

        [Parameter(Mandatory = $false)]
        [switch]$FullScreen,

        [Parameter(Mandatory = $false)]
        [switch]$ClearCache
    )
    BEGIN {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        $SearchProviders = @{
            "Google"     = "https://www.google.com"
            "Bing"       = "https://www.bing.com"
            "DuckDuckGo" = "https://www.duckduckgo.com"
            "Yahoo"      = "https://www.yahoo.com"
            "Ask"        = "https://www.ask.com"
        }
        $Tabs = @()
    }
    PROCESS {
        if (-not $SearchProviders.ContainsKey($SearchProvider)) {
            Write-Warning -Message "Invalid search engine selected. Defaulting to Google!"
            $SearchProvider = "Google"
        }
        $SearchURL = $SearchProviders[$SearchProvider]
        $Form = New-Object System.Windows.Forms.Form
        $Form.Text = $Title
        $Form.Width = $Width
        $Form.Height = $Height
        $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
        $Form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
        $Form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
        $TabControl = New-Object System.Windows.Forms.TabControl
        $TabControl.Dock = [System.Windows.Forms.DockStyle]::Fill
        $Form.Controls.Add($TabControl)
        $AddressBar = New-Object System.Windows.Forms.TextBox
        $AddressBar.Dock = [System.Windows.Forms.DockStyle]::Top
        $AddressBar.Text = $SearchURL
        $Form.Controls.Add($AddressBar)
        $ControlButtonsPanel = New-Object System.Windows.Forms.FlowLayoutPanel
        $ControlButtonsPanel.Dock = [System.Windows.Forms.DockStyle]::Top
        $ControlButtonsPanel.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
        $ControlButtonsPanel.BackColor = [System.Drawing.Color]::FromArgb(200, 200, 200)
        $ControlButtonsPanel.Height = 30
        $Buttons = @("Back", "Forward", "Refresh")
        foreach ($BtnText in $Buttons) {
            $Button = New-Object System.Windows.Forms.Button
            $Button.Text = $BtnText
            $Button.ForeColor = [System.Drawing.Color]::Black
            $Button.BackColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
            $Button.Add_Click({
                    $CurrentTab = $TabControl.SelectedIndex
                    $WebBrowser = $Tabs[$CurrentTab]
                    switch ($BtnText) {
                        "Back" { if ($WebBrowser.CanGoBack) { $WebBrowser.GoBack() } }
                        "Forward" { if ($WebBrowser.CanGoForward) { $WebBrowser.GoForward() } }
                        "Refresh" { $WebBrowser.Refresh() }
                    }
                })
            $ControlButtonsPanel.Controls.Add($Button)
        }
        $NewTabButton = New-Object System.Windows.Forms.Button
        $NewTabButton.Text = "New Tab"
        $NewTabButton.ForeColor = [System.Drawing.Color]::Black
        $NewTabButton.BackColor = [System.Drawing.Color]::FromArgb(220, 220, 220)
        $NewTabButton.Add_Click({
                $NewWebBrowser = New-Object System.Windows.Forms.WebBrowser
                $NewWebBrowser.ScriptErrorsSuppressed = $true
                $NewWebBrowser.Dock = [System.Windows.Forms.DockStyle]::Fill
                $NewWebBrowser.Navigate($SearchURL)
                $NewTabPage = New-Object System.Windows.Forms.TabPage
                $NewTabPage.Text = "New Tab"
                $NewTabPage.Controls.Add($NewWebBrowser)
                $TabControl.TabPages.Add($NewTabPage)
                $Tabs += $NewWebBrowser
            })
        $ControlButtonsPanel.Controls.Add($NewTabButton)
        $ToggleButtonsVisibilityButton = New-Object System.Windows.Forms.Button
        $ToggleButtonsVisibilityButton.Text = "Show/Hide Controls"
        $ToggleButtonsVisibilityButton.Dock = [System.Windows.Forms.DockStyle]::Top
        $ToggleButtonsVisibilityButton.Add_Click({
                $ControlButtonsPanel.Visible = -not $ControlButtonsPanel.Visible
            })
        $Form.Controls.Add($ToggleButtonsVisibilityButton)
        $Form.Controls.Add($ControlButtonsPanel)
        $WebBrowser = New-Object System.Windows.Forms.WebBrowser
        $WebBrowser.ScriptErrorsSuppressed = $true
        $WebBrowser.Dock = [System.Windows.Forms.DockStyle]::Fill
        $WebBrowser.Navigate($SearchURL)
        $TabPage = New-Object System.Windows.Forms.TabPage
        $TabPage.Text = "New Tab"
        $TabPage.Controls.Add($WebBrowser)
        $TabControl.TabPages.Add($TabPage)
        $Tabs += $WebBrowser
        $Form.Add_Shown({ $Form.Activate() })
        $Form.ShowDialog()
    }
    END {
        if ($ClearCache) {
            foreach ($Tab in $Tabs) {
                $Tab.Navigate("about:blank")
                $Tab.Document.ExecCommand("ClearAuthenticationCache", $false, $null)
            }
        }
        foreach ($Tab in $Tabs) {
            $Tab.Dispose()
        }
        if ($null -ne $Form) {
            $Form.Dispose()
        }
    }
}
