Function ManageRepositoryBranches {
    <#
    .SYNOPSIS
    Manage GitHub repository branches.

    .DESCRIPTION
    With this function you can manage branches of GitHub repository's.

    .PARAMETER Action
    Mandatory - description
    .PARAMETER Repository
    Mandatory - description
    .PARAMETER NewBranchName
    Mandatory - description
    .PARAMETER Token
    Mandatory - description

    .EXAMPLE
    ManageRepositoryBranches -Action View "https://github.com/your_user/your_repo" -Token "ghp_xyz"
    ManageRepositoryBranches -Action Create "https://github.com/your_user/your_repo" -Token "ghp_xyz" -NewBranchName "your_new_branch"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, HelpMessage = "Enter 'View' or 'Create'")]
        [ValidateSet("View", "Create")]
        [string]$Action,

        [Parameter(Mandatory, Position = 1, HelpMessage = "Enter the GitHub repository URL")]
        [ValidatePattern('https://github.com/.+/.+')]
        [string]$Repository,

        [Parameter(Mandatory = $false, HelpMessage = "Enter the name of the branch to create (only for 'Create' action)")]
        [ValidateNotNullOrEmpty()]
        [string]$NewBranchName,

        [Parameter(Mandatory = $false, HelpMessage = "Token for auth with GitHub")]
        [ValidateNotNullOrEmpty()]
        [string]$Token
    )
    BEGIN {
        Write-Verbose -Message "Checking for Chocolatey..."
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
        Write-Verbose -Message "Checking if token is valid..."
        Set-Content -Value $Token -Path "$env:USERPROFILE\Desktop\ght.txt" -Force -Verbose
        Start-Process -FilePath "cmd" -ArgumentList "/c gh auth login --with-token < $env:USERPROFILE\Desktop\ght.txt" -WindowStyle Hidden -Wait
        Write-Verbose -Message "Logged in to GitHub, continuing with selected operation $($Operation)..."
    }
    PROCESS {
        Write-Verbose -Message "split the repository URL to get owner and repository name"
        $Owner, $RepoName = ($Repository -split '/')[-2, -1]
        Write-Verbose -Message "set up API endpoints..."
        $BaseApiEndpoint = "https://api.github.com"
        $BranchesEndpoint = "$BaseApiEndpoint/repos/$Owner/$RepoName/branches"
        $RefsEndpoint = "$BaseApiEndpoint/repos/$Owner/$RepoName/git/refs"
        Write-Verbose -Message "set up authentication header..."
        $Headers = @{
            Authorization  = "Bearer $Token"
            'Content-Type' = 'application/json'
        }
        Write-Verbose -Message "perform requested action..."
        switch ($Action) {
            "View" {
                Write-Verbose -Message "get list of branches"
                $Response = Invoke-RestMethod -Uri $BranchesEndpoint -Method Get -Headers $Headers
                Write-Host "Branches in the '$RepoName' repository:"
                foreach ($Branch in $Response) {
                    Write-Host "- $($Branch.name)" -ForegroundColor Green
                }
            }
            "Create" {
                if (-not $NewBranchName) {
                    $NewBranchName = Read-Host "Enter a name for the new branch"
                }
                Write-Verbose -Message "get the default branch using the GitHub API"
                $DefaultBranchUri = "https://api.github.com/repos/$Owner/$RepoName"
                $DefaultBranch = Invoke-RestMethod -Uri $DefaultBranchUri -Method Get -Headers $Headers
                $DefaultBranchName = $DefaultBranch.default_branch
                $DefaultBranchRef = "heads/$defaultBranchName"
                $ResponseUri = "https://api.github.com/repos/$Owner/$RepoName/git/ref/$DefaultBranchRef"
                $Response = Invoke-RestMethod -Uri $ResponseUri -Method Get -Headers $Headers
                $DefaultBranchSha = $Response.object.sha
                Write-Verbose -Message "create new branch using GitHub API..."
                $HeadRef = "refs/heads/$NewBranchName"
                $Payload = @{
                    ref = $HeadRef
                    sha = $DefaultBranchSha
                } | ConvertTo-Json
                Invoke-RestMethod -Uri $RefsEndpoint -Method Post -Headers $Headers -Body $Payload | Out-Null
                Write-Host "New branch '$NewBranchName' created successfully" -ForegroundColor Green
            }
            default {
                Write-Error "Invalid action: '$Action'. Supported actions are: View or Create."
            }
        }
    }
    END {
        Write-Verbose -Message "Cleaning up, closing connection and exiting..."
        gh auth logout --hostname "github.com"
        Clear-History -Verbose -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:USERPROFILE\Desktop\ght.txt" -Force -Verbose -ErrorAction SilentlyContinue
        Clear-Variable -Name Repository, Token, NewBranchName -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
        Remove-Variable -Name Repository, Token, NewBranchName -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
    }
}
