Function ManageRepositoryBranches {
    <#
    .SYNOPSIS
    GitHub repository branches manager.

    .DESCRIPTION
    With this function you can manage branches of GitHub repository's.

    .PARAMETER Action
    Mandatory - action to be performed on the branches, accepted values are "View", "Create", or "Delete".
    .PARAMETER Repository
    Mandatory - repository URL, parameter is validated to accept only URLs starting with "https://github.com/".
    .PARAMETER Token
    NotMandatory - specifies the personal access token for authentication with GitHub.
    .PARAMETER NewBranchName
    NotMandatory - name of the new branch or branches to be created.
    .PARAMETER DeleteBranchName
    NotMandatory - names of the branche or branches to be deleted.

    .EXAMPLE
    "https://github.com/your_user/your_repo" | ManageRepositoryBranches -Action View -Token "ghp_xyz"
    ManageRepositoryBranches -Action Create -Repository "https://github.com/your_user/your_repo" -Token "ghp_xyz" -NewBranchName "your_new_branch_1", "your_new_branch_2"
    ManageRepositoryBranches -Action Delete -Repository "https://github.com/your_user/your_repo" -Token "ghp_xyz" -DeleteBranchName "your_new_branch_1", "your_new_branch_2"

    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Enter 'View', 'Create' or 'Delete'")]
        [ValidateSet("View", "Create", "Delete")]
        [string]$Action,

        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, HelpMessage = "Enter the GitHub repository URL")]
        [ValidatePattern('https://github.com/.+/.+')]
        [string]$Repository,

        [Parameter(Mandatory = $false, HelpMessage = "Token for auth with GitHub to be able to do actions/operation")]
        [ValidateNotNullOrEmpty()]
        [string]$Token,

        [Parameter(Mandatory = $false, HelpMessage = "Enter the name of the branch to create (only for 'Create' action)")]
        [ValidateNotNullOrEmpty()]
        [string[]]$NewBranchName,

        [Parameter(Mandatory = $false, HelpMessage = "Array of branch names to delete (only for 'Delete' action)")]
        [ValidateNotNullOrEmpty()]
        [string[]]$DeleteBranchName
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
        Write-Verbose -Message "checking if token is valid..."
        Set-Content -Value $Token -Path "$env:USERPROFILE\Desktop\ght.txt" -Force -Verbose
        Start-Process -FilePath "cmd" -ArgumentList "/c gh auth login --with-token < $env:USERPROFILE\Desktop\ght.txt" -WindowStyle Hidden -Wait
        Write-Verbose -Message "logged in to GitHub, continuing with selected operation $($Operation)..."
    }
    PROCESS {
        Write-Verbose -Message "splitting the repository URL to get owner and repository name"
        $Owner, $RepoName = ($Repository -split '/')[-2, -1]
        Write-Verbose -Message "setting up API endpoints..."
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
                Write-Host "Branches in the '$RepoName' repository:" -ForegroundColor Yellow
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
                $NewBranchName | ForEach-Object {
                    $BranchName = $_
                    Write-Verbose -Message "create new branch '$BranchName' using GitHub API..."
                    $HeadRef = "refs/heads/$BranchName"
                    $Payload = @{
                        ref = $HeadRef
                        sha = $DefaultBranchSha
                    } | ConvertTo-Json
                    Invoke-RestMethod -Uri $RefsEndpoint -Method Post -Headers $Headers -Body $Payload | Out-Null
                    Write-Host "New branch '$BranchName' created successfully" -ForegroundColor Green
                }
            }
            "Delete" {
                if (-not $DeleteBranchName) {
                    $DeleteBranchName = @((Read-Host "Enter the name of the branch to delete").Trim())
                }
                $BranchesEndpoint = "$BaseApiEndpoint/repos/$Owner/$RepoName/branches"
                $Response = Invoke-RestMethod -Uri $BranchesEndpoint -Method Get -Headers $Headers
                $BranchesToDelete = @()
                foreach ($BranchName in $DeleteBranchName) {
                    if ($BranchName -notin $Response.name) {
                        Write-Error "Branch '$BranchName' not found in '$RepoName' repository"
                    }
                    else {
                        $BranchesToDelete += $BranchName
                    }
                }
                if ($BranchesToDelete.Count -eq 0) {
                    return
                }
                foreach ($BranchName in $BranchesToDelete) {
                    $ApiEndpoint = "$BaseApiEndpoint/repos/$Owner/$RepoName/git/refs/heads/$BranchName"
                    $Response = Invoke-RestMethod -Uri $ApiEndpoint -Method Delete -Headers $Headers
                    Write-Host "Branch '$BranchName' deleted successfully" -ForegroundColor Green
                }
            }
            default {
                Write-Error "Invalid action: '$Action'. Supported actions are: 'View', 'Create' or 'Delete'."
            }
        }
    }
    END {
        Write-Verbose -Message "Cleaning up, closing connection and exiting..."
        gh auth logout --hostname "github.com"
        Clear-History -Verbose -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:USERPROFILE\Desktop\ght.txt" -Force -Verbose -ErrorAction SilentlyContinue
        Clear-Variable -Name Repository, Token, NewBranchName, DeleteBranchName -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
        Remove-Variable -Name Repository, Token, NewBranchName, DeleteBranchName -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
    }
}
