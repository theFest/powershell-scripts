Function Get-ShortenedURL {
    <#
    .SYNOPSIS
    Shortens a URL using various free URL shortening services.

    .DESCRIPTION
    This function shortens a URL by utilizing different free URL shortening services without requiring an API key, supports services like is.gd, snipurl, tinyurl, chilp, clickme, and sooogd.

    .PARAMETER Shortener
    The URL shortening service to use.
    .PARAMETER Link
    Specifies the URL to be shortened.

    .EXAMPLE
    Get-ShortenedURL -Shortener isgd -Link "http://www.google.com"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("isgd", "snipurl", "tinyurl", "chilp", "clickme", "sooogd")]
        [string]$Shortener,

        [Parameter(Mandatory = $true)]
        [string]$Link
    )
    BEGIN {
        $BaseURL = ""
        $WebClient = New-Object Net.WebClient
        $ValidUrl = $true
    }
    PROCESS {
        if (-not ([System.Uri]::TryCreate($Link, [System.UriKind]::Absolute, [ref]$null))) {
            Write-Error -Message "Invalid URL format!"
            $ValidUrl = $false
            return
        }
        switch ($Shortener) {
            "isgd" {
                $BaseURL = "https://is.gd/create.php?format=simple&url=$Link"
            }
            "snipurl" {
                $BaseURL = "http://snipurl.com/site/snip?r=simple&link=$Link"
            }
            "tinyurl" {
                $BaseURL = "http://tinyurl.com/api-create.php?url=$Link"
            }
            "chilp" {
                $BaseURL = "https://chilp.it/api.php?url=$Link"
            }
            "clickme" {
                $BaseURL = "http://cliccami.info/api/resturl/?url=$Link"
            }
            "sooogd" {
                $BaseURL = "https://soo.gd/api.php?api=&short=$Link"
            }
            default {
                Write-Error -Message "Invalid URL shortener specified. Supported options are 'snipurl', 'tinyurl', 'isgd', 'chilp', 'clickme', or 'sooogd'!"
                return
            }
        }
        if ($ValidUrl) {
            $Response = $WebClient.DownloadString("$BaseURL")
            $ShortenedUrl = $Response.Trim()
            [PSCustomObject]@{
                OriginalURL      = $Link
                ShortenedURL     = $ShortenedUrl
                Shortener        = $Shortener
                CreationDateTime = Get-Date
            }
        }
    }
    END {
        if ($WebClient) {
            $WebClient.Dispose()
        }
    }
}
