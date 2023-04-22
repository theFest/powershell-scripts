Function RepositoryInformer {
    <#
    .SYNOPSIS
    Retrieves information about a organizational GitHub repositories.
    
    .DESCRIPTION
    This function retrieves detailed information about all repositories of the GitHub organization.
    
    .PARAMETER Token
    Mandatory - personal access token to use for authentication with the GitHub API.
    .PARAMETER OrgName
    Mandatory - name of the organization to retrieve repository information for.
    .PARAMETER ExportResults
    NotMandatory - export the results to a CSV file, also use it to define output destination.
    .PARAMETER OpenTranscript
    NotMandatory - whether to open the transcript file after the command is executed, will be opened in default program.
    
    .EXAMPLE
    "your_org" | RepositoryInformer -Token "github_pat_xyz" -ExportResults "$env:USERPROFILE\Desktop\repo_info.csv" -Verbose
    RepositoryInformer -Token "github_pat_xyz" -OrgName "your_org" -ExportResults "$env:USERPROFILE\Desktop\repo_info.csv" -OpenTranscript -Verbose
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Token,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OrgName,

        [Parameter(Mandatory = $false)]
        [string]$ExportResults,

        [Parameter(Mandatory = $false)]
        [switch]$OpenTranscript
    )
    BEGIN {
        Start-Transcript -Path "$env:TEMP\repo_info.txt" -Force -Verbose
        Write-Verbose -Message "Checking for Chocolatey, Git and GitHub CLI..."
        if (-not(Get-Command choco.exe -ErrorAction SilentlyContinue)) {
            try {
                Write-Verbose -Message "Installing Chocolatey..."
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            }
            catch {
                Write-Error "Failed to install Chocolatey: $($_.Exception.Message)"
                return
            }
        }
        Write-Verbose -Message "Installing Git and GitHub CLI using Chocolatey"
        if (-not(Get-Command git -ErrorAction SilentlyContinue)) {
            try {
                choco install git -y
                Write-Host "Git CLI installation successful" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to install Git CLI: $($_.Exception.Message)"
            }
        }
        if (-not(Get-Command gh -ErrorAction SilentlyContinue)) {
            try {
                choco install gh -y
                Write-Host "GitHub CLI installation successful" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to install GitHub CLI: $($_.Exception.Message)"
            }
        }
        Write-Verbose -Message "encrypting PAT and store it in a file..."
        $SecPAT = ConvertTo-SecureString -String $Token -AsPlainText -Force
        $SecPAT | Export-Clixml -Path "$env:USERPROFILE\Desktop\ght.xml"
        Write-Verbose -Message "reading the PAT from the file..."
        $SecPAT = Import-Clixml -Path "$env:USERPROFILE\Desktop\ght.xml"
        $Token = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecPAT))
        Write-Verbose -Message "defining an empty array to hold repository information"
        $RepoInfo = @()
        Write-Verbose -Message "preparing and setting headers for the API request...."
        $Headers = @{
            "Authorization" = "Bearer $Token"
            "Accept"        = "application/vnd.github.v3+json"
        }
    }
    PROCESS {
        Write-Verbose -Message "fething all repositories in the organization..."
        $Url = "https://api.github.com/orgs/$OrgName/repos?per_page=1000"
        $Repos = Invoke-RestMethod -Uri $Url -Headers $Headers
        $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        foreach ($Repo in $Repos) {
            Write-Host "Getting information for $($Repo.name)..." -ForegroundColor Yellow
            $RepoUrl = $Repo.url
            $RepoData = Invoke-RestMethod -Uri $RepoUrl -Headers $Headers
            $Branches = Invoke-RestMethod -Uri "$RepoUrl/branches" -Headers $Headers
            $OpenIssues = Invoke-RestMethod -Uri "$RepoUrl/issues?state=open" -Headers $Headers
            $ClosedIssues = Invoke-RestMethod -Uri "$RepoUrl/issues?state=closed" -Headers $Headers
            $OpenPullRequests = Invoke-RestMethod -Uri "$RepoUrl/pulls?state=open" -Headers $Headers
            $ClosedPullRequests = Invoke-RestMethod -Uri "$RepoUrl/pulls?state=closed" -Headers $Headers
            $Commits = Invoke-RestMethod -Uri "$RepoUrl/commits" -Headers $Headers
            $Contributors = Invoke-RestMethod -Uri "$RepoUrl/contributors" -Headers $Headers
            $Stargazers = Invoke-RestMethod -Uri "$RepoUrl/stargazers" -Headers $Headers
            $Forks = Invoke-RestMethod -Uri "$RepoUrl/forks" -Headers $Headers
            $Watchers = Invoke-RestMethod -Uri "$RepoUrl/subscribers" -Headers $Headers
            $Releases = Invoke-RestMethod -Uri "$RepoUrl/releases" -Headers $Headers
            $CreatedDate = [DateTime]::Parse($RepoData.created_at)
            $PushedDate = [DateTime]::Parse($RepoData.pushed_at)
            $License = "None"
            if ($RepoData.license) {
                $License = $RepoData.license.spdx_id
            }
            $RepoInfo += [PSCustomObject]@{
                Name                 = $Repo.name
                Description          = $Repo.description
                LastUpdated          = $Repo.updated_at
                DefaultBranch        = $Repo.default_branch
                Language             = $Repo.language
                URL                  = $Repo.html_url
                Size                 = $Repo.size
                IsArchived           = $Repo.archived
                IsFork               = $Repo.fork
                IsPrivate            = $Repo.private
                HasDownloads         = $Repo.has_downloads
                HasIssues            = $Repo.has_issues
                HasPages             = $Repo.has_pages
                HasProjects          = $Repo.has_projects
                HasWiki              = $Repo.has_wiki
                Homepage             = $Repo.homepage
                ForkCount            = $Forks.count
                Commits              = $Commits.count
                ReleaseCount         = $Releases.count
                BranchCount          = $Branches.count
                OpenIssueCount       = $OpenIssues.count
                ClosedIssuesCount    = $ClosedIssues.count
                OpenPullRequestCount = $OpenPullRequests.count
                ClosedPullRequests   = $ClosedPullRequests.count
                WatcherCount         = $Watchers.count
                StarCount            = $Stargazers.count
                ContributorCount     = $Contributors.count
                License              = $License
                PushedDate           = $PushedDate.ToString("yyyy-MM-dd")
                CreatedDate          = $CreatedDate.ToString("yyyy-MM-dd")
            }
        }
    }
    END {
        Write-Verbose -Message "Cleaning up, closing connection and exiting..."
        Clear-History -Verbose -ErrorAction SilentlyContinue
        Write-Host "Total number of repositories: $($RepoInfo.count)" -ForegroundColor Green
        Remove-Item -Path "$env:USERPROFILE\Desktop\ght.xml" -Force -Verbose -ErrorAction SilentlyContinue
        Clear-Variable -Name Token, OrgName -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
        Remove-Variable -Name Token, OrgName -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
        if ($ExportResults) {
            Write-Verbose -Message "outputting the repository information to a CSV file..."
            $RepoInfo | Export-Csv -Path $ExportResults -NoTypeInformation
        }
        $StopWatch.Stop()
        $ElapsedTime = $StopWatch.Elapsed.ToString("hh\:mm\:ss")
        Write-Host "Elapsed time: $ElapsedTime" -ForegroundColor DarkCyan
        Stop-Transcript
        if ($OpenTranscript) {
            Invoke-Item -Path "$env:TEMP\repo_info.txt" -Verbose
        }
    }
} 
