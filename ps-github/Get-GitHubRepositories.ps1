Function Get-GitHubRepositories {
    <#
    .SYNOPSIS
    Retrieves GitHub repositories based on visibility for a given user.

    .DESCRIPTION
    This function retrieves GitHub repositories for a specified user with the option to filter by visibility (Public, Private, or All) and sort them based on various criteria.

    .PARAMETER Token
    NotMandatory - the GitHub authentication token. A token is required for Private and All visibility.
    .PARAMETER Username
    NotMandatory - the GitHub username for which to retrieve repositories.
    .PARAMETER SortBy
    NotMandatory - sorting criteria for the repositories. Supported values are "name" and "update_time" (last updated time).
    .PARAMETER Descending
    NotMandatory - indicate whether the sorting order should be reversed.
    .PARAMETER Visibility
    NotMandatory - visibility of repositories to retrieve. Valid values are "Private", "Public", or "All". Default is "All".

    .EXAMPLE
    Get-GitHubRepositories -Username "GitHub_user" -Visibility Public
    Get-GitHubRepositories -Token "ghp_xyz" -Username "GitHub_user" -Visibility All
    Get-GitHubRepositories -Token "ghp_xyz" -Username "GitHub_user" -Visibility Private

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Token,

        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [string]$SortBy = "name",

        [Parameter(Mandatory = $false)]
        [switch]$Descending,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Private", "Public", "All")]
        [string]$Visibility = "All"
    )
    if ($Visibility -eq "Public" -and $Token) {
        Write-Host "A token is not required for Public visibility. Removing the token parameter." -ForegroundColor Yellow
        $Token = $null
    }
    Write-Verbose -Message "Setting the GitHub API URLs based on visibility..."
    $PublicApiUrl = "https://api.github.com/users/$Username/repos?type=public"
    $PrivateApiUrl = "https://api.github.com/user/repos?type=private"
    try {
        $Headers = @{}
        if ($Token) {
            $Headers.Add("Authorization", "Bearer $Token")
        }
        $PublicRepos = @()
        $PrivateRepos = @()
        if ($Visibility -eq "All") {
            $PublicRepos = Invoke-RestMethod -Uri $PublicApiUrl -Headers $Headers -Method Get
            $PrivateRepos = Invoke-RestMethod -Uri $PrivateApiUrl -Headers $Headers -Method Get
        }
        elseif ($Visibility -eq "Public") {
            $PublicRepos = Invoke-RestMethod -Uri $PublicApiUrl -Headers $Headers -Method Get
        }
        else {
            $PrivateRepos = Invoke-RestMethod -Uri $PrivateApiUrl -Headers $Headers -Method Get
        }
        Write-Verbose -Message "Combine public and private repositories"
        $CombinedRepos = $PublicRepos + $PrivateRepos
        Write-Verbose -Message "Sorting repositories based on the chosen sorting criteria"
        if ($SortBy -eq "name") {
            $FilteredRepos = $CombinedRepos | Sort-Object Name
        }
        elseif ($SortBy -eq "update_time") {
            $FilteredRepos = $CombinedRepos | Sort-Object -Property updated_at
        }
        else {
            $FilteredRepos = $CombinedRepos
        }
        Write-Verbose -Message "Optionally reverse the sorting order"
        if ($Descending) {
            $FilteredRepos = $FilteredRepos | Sort-Object -Descending
        }
        Write-Verbose -Message "Output the list of repositories with selected properties"
        $FilteredRepos | Select-Object Name, Description, HTML_url, created_at, updated_at, private
    }
    catch {
        Write-Host "An error occurred: $_" -ForegroundColor Red
    }
}
