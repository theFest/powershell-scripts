Function New-GitHubIssue {
    <#
    .SYNOPSIS
    Designed to create a new issue in a GitHub repository using the GitHub API.
    
    .DESCRIPTION
    This function automates the process of creating GitHub issues by sending an HTTP POST request to the GitHub API.
    
    .PARAMETER Token
    Mandatory - this is the GitHub authentication token used to authorize the API request.
    .PARAMETER Repository
    Mandatory - specifies the GitHub repository where the issue will be created.
    .PARAMETER Title
    Mandatory - sets the title of the issue to be created.
    .PARAMETER Body
    Mandatory - defines the body or description of the issue to be created.
    
    .EXAMPLE
    "github_pat_xyz" | New-GitHubIssue -Repository "github_user/github_repo" -Title "your_issue_title" -Body "your_issue_description"
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Token,

        [Parameter(Mandatory = $true)]
        [string]$Repository,

        [Parameter(Mandatory = $true)]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [string]$Body
    )
    Write-Verbose -Message "Setting the GitHub API URL for creating issues in a repository..."
    $ApiUrl = "https://api.github.com/repos/$Repository/issues"
    try {
        Write-Verbose -Message "Creating a header with authentication token..."
        $Headers = @{
            "Authorization" = "Bearer $Token"
        }
        Write-Verbose -Message "Creating a JSON body for the issue..."
        $IssueBody = @{
            "title" = $Title
            "body"  = $Body
        } | ConvertTo-Json
        Write-Verbose -Message "Now let's invoke the GitHub API to create a new issue"
        Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -Method Post -Body $IssueBody
        Write-Host "Issue created successfully in repository $Repository." -ForegroundColor Green
    }
    catch {
        Write-Host "An error occurred: $_" -ForegroundColor DarkRed
    }
}
