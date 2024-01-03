Function New-WebBrowserWindow {
    <#
    .SYNOPSIS
    Creates a new web browser window using System.Windows.Forms.WebBrowser.

    .DESCRIPTION
    This function creates a new window with an embedded web browser control to display web content.

    .PARAMETER Title
    NotMandatory - title of the browser window, default is "PS Browser Window".
    .PARAMETER Width
    NotMandatory - specifies the width of the browser window, default is 1600 pixels.
    .PARAMETER Height
    NotMandatory - specifies the height of the browser window, default is 900 pixels.
    .PARAMETER SearchProvider
    NotMandatory - search provider to be used for initial navigation, valid values are "Google", "Bing", or "DuckDuckGo". Default is "Google".

    .EXAMPLE
    New-WebBrowserWindow
    New-WebBrowserWindow -Width 1600 -Height 1200 -SearchEngine Bing

    .NOTES
    v0.0.2
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
        [ValidateSet("Google", "Bing", "DuckDuckGo")]
        [string]$SearchProvider = "Google"
    )
    BEGIN {
        Add-Type -AssemblyName System.Windows.Forms
        $SearchProviders = @{
            "Google"     = "https://www.google.com"
            "Bing"       = "https://www.bing.com"
            "DuckDuckGo" = "https://www.duckduckgo.com"
        }
    }
    PROCESS {
        if (-not $SearchProviders.ContainsKey($SearchProvider)) {
            Write-Warning -Message "Invalid search engine selected. Defaulting to Google!"
            $SearchProvider = "Google"
        }
        $SearchURL = $SearchProviders[$SearchProvider]
        $Form = New-Object System.Windows.Forms.Form
        $Form.Text = $Title
        $Form.Size = New-Object System.Drawing.Size($Width, $Height)
        $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
        $Form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font
        $WebBrowser = New-Object System.Windows.Forms.WebBrowser
        $WebBrowser.ScriptErrorsSuppressed = $true
        $WebBrowser.Dock = [System.Windows.Forms.DockStyle]::Fill
        $WebBrowser.Navigate($SearchURL)
        $Form.Controls.Add($WebBrowser)
        $Form.ShowDialog()
    }
    END {
        if ($null -ne $WebBrowser) {
            $WebBrowser.Dispose()
        }
        if ($null -ne $Form) {
            $Form.Dispose()
        }
    }
}
