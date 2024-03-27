Function Get-GitHubPullRequests {
    <#
    .SYNOPSIS
    Retrieves Pull Requests from a GitHub repository.

    .DESCRIPTION
    This function retrieves Pull Requests from a GitHub repository based on specified parameters such as repository name, branch, state, and authentication token.

    .PARAMETER Repository
    Specifies the name of the GitHub repository.
    .PARAMETER Branch
    Branch of the repository, change if needed as default is "master".
    .PARAMETER State
    State of the Pull Requests to retrieve, values are "open", "closed", or "all".
    .PARAMETER Token
    The GitHub authentication token, required if the repository is private.

    .EXAMPLE
    Get-GitHubPullRequests -Repository "quarkusio/quarkus" -Branch "main" -State all

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $false)]
        [string]$Branch = "master",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("open", "closed", "all")]
        [string]$State = "open",
        
        [Parameter(Mandatory = $false)]
        [string]$Token
    )
    if ([string]::IsNullOrWhiteSpace($Repository)) {
        Write-Error -Message "Repository name cannot be empty!"
        return
    }
    $ApiUrl = "https://api.github.com/repos/$Repository/pulls?state=$State&base=$Branch"
    $Headers = @{}
    if (-not [string]::IsNullOrWhiteSpace($Token)) {
        $Headers["Authorization"] = "token $Token"
    }
    try {
        $Response = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -Method Get -ErrorAction Stop
        if ($Response -is [array]) {
            $Response | ForEach-Object {
                [PSCustomObject]@{
                    Title     = $_.title
                    Number    = $_.number
                    User      = $_.user.login
                    State     = $_.state
                    CreatedAt = $_.created_at
                    UpdatedAt = $_.updated_at
                    URL       = $_.html_url
                }
            }
        }
        else {
            Write-Warning -Message "No pull requests found!?"
        }
    }
    catch {
        Write-Error -Message "Failed to retrieve pull requests. $_!"
    }
}
