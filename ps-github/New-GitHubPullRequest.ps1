function New-GitHubPullRequest {
    <#
    .SYNOPSIS
    Creates a new Pull Request on a GitHub repository.

    .DESCRIPTION
    This function creates a new Pull Request on a GitHub repository based on specified parameters such as repository name, base branch, head branch, title, body, and authentication token.

    .EXAMPLE
    New-GitHubPullRequest -Repository "owner/repository" -BaseBranch "main" -HeadBranch "feature-branch" -Title "New Feature" -Body "Adding a new feature to improve functionality" -Token "YourTokenHere"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Name of the GitHub repository")]
        [string]$Repository,
        
        [Parameter(Mandatory = $true, HelpMessage = "Base branch of the pull request")]
        [string]$BaseBranch,
        
        [Parameter(Mandatory = $true, HelpMessage = "Head branch of the pull request")]
        [string]$HeadBranch,
        
        [Parameter(Mandatory = $true, HelpMessage = "Title of the pull request")]
        [string]$Title,
        
        [Parameter(Mandatory = $true, HelpMessage = "Body content of the pull request")]
        [string]$Body,
        
        [Parameter(Mandatory = $false, HelpMessage = "GitHub authentication token, required for creating pull requests on private repositories")]
        [string]$Token
    )
    if ([string]::IsNullOrWhiteSpace($Repository)) {
        Write-Error -Message "Repository name cannot be empty!"
        return
    }
    $ApiUrl = "https://api.github.com/repos/$Repository/pulls"
    $Headers = @{
        "Accept" = "application/vnd.github.v3+json"
    }
    if (-not [string]::IsNullOrWhiteSpace($Token)) {
        $Headers["Authorization"] = "token $Token"
    }
    $BodyData = @{
        title = $Title
        body  = $Body
        head  = $HeadBranch
        base  = $BaseBranch
    } | ConvertTo-Json
    try {
        $Response = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -Method Post -Body $BodyData -ErrorAction Stop
        [PSCustomObject]@{
            Title     = $Response.title
            Number    = $Response.number
            User      = $Response.user.login
            State     = $Response.state
            CreatedAt = $Response.created_at
            UpdatedAt = $Response.updated_at
            URL       = $Response.html_url
        }
    }
    catch {
        Write-Error -Message "Failed to create pull request. $_!"
    }
}
