Function New-WebBrowserWindow {
    <#
    .SYNOPSIS
    Creates a new window with an embedded web browser.

    .DESCRIPTION
    This function creates a window containing a web browser. It allows users to specify various parameters such as the title, dimensions, search provider, and more.

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
    v0.0.3
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
        $SearchProviders = @{
            "Google"     = "https://www.google.com"
            "Bing"       = "https://www.bing.com"
            "DuckDuckGo" = "https://www.duckduckgo.com"
            "Yahoo"      = "https://www.yahoo.com"
            "Ask"        = "https://www.ask.com"
        }
    }
    PROCESS {
        if (-not $SearchProviders.ContainsKey($SearchProvider)) {
            Write-Warning -Message "Invalid search engine selected. Defaulting to Google!"
            $SearchProvider = "Google"
        }
        $SearchURL = $SearchProviders[$SearchProvider]
        $Form = New-Object System.Windows.Forms.Form
        if ($FullScreen) {
            $Form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
        }
        else {
            $Form.Size = New-Object System.Drawing.Size($Width, $Height)
            $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
        }
        if (-not $Resizable) {
            $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
        }
        $Form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font
        $Form.Text = $Title
        $WebBrowser = New-Object System.Windows.Forms.WebBrowser
        $WebBrowser.ScriptErrorsSuppressed = $true
        $WebBrowser.Dock = [System.Windows.Forms.DockStyle]::Fill
        $WebBrowser.Navigate($SearchURL)
        $Form.Controls.Add($WebBrowser)
        $Form.Add_Shown({ $Form.Activate() })
        $Form.ShowDialog()
    }
    END {
        if ($ClearCache) {
            $WebBrowser.Navigate("about:blank")
            $WebBrowser.Document.ExecCommand("ClearAuthenticationCache", $false, $null)
        }
        if ($null -ne $WebBrowser) {
            $WebBrowser.Dispose()
        }
        if ($null -ne $Form) {
            $Form.Dispose()
        }
    }
}
