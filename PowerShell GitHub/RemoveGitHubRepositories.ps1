Function RemoveGitHubRepositories {
    <#
    .SYNOPSIS
    Deletes one or more GitHub repositories using the GitHub CLI.

    .DESCRIPTION
    This function uses the GitHub CLI to delete one or more GitHub repositories, with ability to use CSV file containing a list of repository names.

    .PARAMETER Repositories
    NotMandatory - array of repositories to be deleted. Each repository should be in the format "username/reponame".
    .PARAMETER Token
    Mandatory - the authentication token to use for interacting with the GitHub API, classic is recommended.
    .PARAMETER InputFile
    NotMandatory - string that specifies the path of a file containing a list of repositories to delete, one per line.
    .PARAMETER InputDelimiter
    NotMandatory - string that specifies the delimiter character used in the input file. The default value is a comma.
    .PARAMETER IncludeForks
    NotMandatory - if forked repositories should also be included for deletion, by default, this parameter is not enabled and only the repositories owned by the authenticated user are deleted.
    .PARAMETER IncludeArchived
    NotMandatory - if archived repositories should also be included for deletion, by default, this parameter is not enabled and only the active repositories are deleted, if this parameter is used, archived repositories will also be deleted.
    .PARAMETER Confirm
    NotMandatory - switch parameter that prompts the user to confirm each repository deletion.

    .EXAMPLE
    "https://github.com/your_user/repo_1","https://github.com/your_user/repo_1" | RemoveGitHubRepositories -Token "ghp_xyz" -Verbose
    RemoveGitHubRepositories -InputFile "$env:USERPROFILE\Desktop\ght.txt" -Token -Verbose

    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Repositories,

        [Parameter(Mandatory = $true)]
        [string]$Token,

        [Parameter(Mandatory = $false)]
        [string]$InputFile,

        [Parameter(Mandatory = $false)]
        [string]$InputDelimiter = ",",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeForks,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeArchived,

        [Parameter(Mandatory = $false)]
        [switch]$Confirm
    )
    BEGIN {
        Write-Verbose -Message "Checking for Chocolatey..."
        if (-not(Get-Command choco.exe -ErrorAction SilentlyContinue)) {
            try {
                Write-Verbose -Message "Install Chocolatey..."
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            }
            catch {
                Write-Error "Failed to install Chocolatey: $($_.Exception.Message)"
                return
            }
        }
        Write-Verbose -Message "Installing Git and GitHub CLI using Chocolatey..."
        if (-not(Get-Command git -ErrorAction SilentlyContinue)) {
            try {
                choco install git -y
                Write-Output "Git CLI installation successful"
            }
            catch {
                Write-Error "Failed to install Git CLI: $($_.Exception.Message)"
            }
        }
        if (-not(Get-Command gh -ErrorAction SilentlyContinue)) {
            try {
                choco install gh -y
                Write-Output "GitHub CLI installation successful"
            }
            catch {
                Write-Error "Failed to install GitHub CLI: $($_.Exception.Message)"
            }
        }
        Set-Content -Value $Token -Path "$env:USERPROFILE\Desktop\ght.txt" -Force -Verbose
        Start-Process -FilePath "cmd" -ArgumentList "/c gh auth login --with-token < $env:USERPROFILE\Desktop\ght.txt" -WindowStyle Hidden -Wait
        Start-Sleep -Seconds 3
        if ($InputFile) {
            $RepositoriesFromFile = Get-Content $InputFile | ForEach-Object { $_ -split $InputDelimiter } | Where-Object { $_ }
            $Repositories += $RepositoriesFromFile
        }
    }
    PROCESS {
        foreach ($Repo in $Repositories) {
            $Owner, $Name = $Repo.split("/")[-2], $Repo.split("/")[-1]
            $RepoInfo = gh api "/repos/$Owner/$Name"
            if (!$RepoInfo) {
                Write-Warning -Message "Repository $Repo not found"
                continue
            }
            if (!$IncludeForks -and $RepoInfo.fork) {
                Write-Warning -Message "Repository $Repo is a fork and will not be deleted, use '-IncludeForks' to delete forks"
                continue
            }
            if (!$IncludeArchived -and $RepoInfo.archived) {
                Write-Warning -Message "Repository $Repo is archived and will not be deleted, use '-IncludeArchived' to delete archived repositories"
                continue
            }
            $ConfirmationMessage = "Are you sure you want to delete repository '$Owner/$Name'?"
            if (!$Confirm -or (Read-Host -Prompt $ConfirmationMessage -AsSecureString) -as [string] -eq "yes") {
                gh api "/repos/$Owner/$Name" -X DELETE > $null
                Write-Host "Repository $Owner/$Name deleted successfully" -ForegroundColor Green
            }
        }
    }
    END {
        Write-Verbose -Message "Cleaning up, closing connection and exiting!"
        gh auth logout --hostname "github.com"
        Remove-Item -Path "$env:USERPROFILE\Desktop\ght.txt" -Force -Verbose
        Clear-Variable -Name Repositories, Token -Force -ErrorAction SilentlyContinue
    }
}
