Function Search-Web {
    <#
    .SYNOPSIS
    Performs a web search using the specified search engine for the provided text.

    .DESCRIPTION
    This function performs a web search using Bing, Google, or Yahoo as the search engine based on the provided text. It can display search results directly in the console or open them in a browser.

    .PARAMETER Text
    Mandatory - specifies the text to be searched.
    .PARAMETER SearchEngine
    NotMandatory - search engine to use, accepted values: Bing, Google, Yahoo. Default is Google.
    .PARAMETER NoBrowser
    NotMandatory - specifies whether to prevent opening search results in a web browser.
    .PARAMETER DetailedOutput
    NotMandatory - specifies whether to display detailed information along with search results.

    .EXAMPLE
    "google.com" | Search-Web -SearchEngine Bing -Verbose -DetailedOutput
    Search-Web -Text "google.com" -SearchEngine Google -NoBrowser -Verbose -DetailedOutput
    Search-Web -Text "google.com" -SearchEngine Yahoo -Verbose -DetailedOutput

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Bing", "Google", "Yahoo")]
        [string]$SearchEngine = "Google",

        [Parameter(Mandatory = $false)]
        [switch]$NoBrowser,

        [Parameter(Mandatory = $false)]
        [switch]$DetailedOutput
    )
    BEGIN {
        Write-Verbose -Message "Initializing Get-SearchResult function..."
    }
    PROCESS {
        switch ($SearchEngine) {
            "Bing" {
                $Lang = (Get-Culture).Parent.Name
                $Url = "http://www.bing.com/search?q=$text+language%3A$Lang"
                break
            }
            "Google" {
                $Url = "http://www.google.com/search?q=$text"
            }
            "Yahoo" {
                $Url = "http://search.yahoo.com/search?p=$text"
            }
        }
        if (-not $NoBrowser -or $DetailedOutput) {
            Write-Verbose -Message "Fetching results from $SearchEngine for '$Text'..."
            $WebRequest = Invoke-WebRequest -Uri $Url
            if ($DetailedOutput) {
                Write-Output "Search Engine: $SearchEngine"
                Write-Output "Search Text: $Text"
                Write-Output "Generated URL: $Url"
                Write-Output "Search Results:`n$($WebRequest.ParsedHtml.Body.InnerText)"
            }
            else {
                Write-Output "`nSearch Results from $SearchEngine for '$Text':`n$($WebRequest.ParsedHtml.Body.InnerText)"
            }
        }
        if (-not $NoBrowser) {
            Write-Verbose -Message "Opening $Url in $SearchEngine"
            Start-Process $Url
        }
        else {
            Write-Verbose -Message "Skipping opening browser as requested."
        }
    }
    END {
        Write-Verbose -Message "Get-SearchResult function completed."
    }
}
