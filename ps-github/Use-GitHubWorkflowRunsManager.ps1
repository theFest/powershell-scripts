Function Use-GitHubWorkflowRunsManager {
    <#
    .SYNOPSIS
    Simple function used to manage workflow runs for a repository on GitHub.

    .DESCRIPTION
    This function requires a GitHub repository name, a personal access token, and an action to perform, user can choose to view, delete, or stop the workflow runs for a given repository.

    .PARAMETER Action
    Action to be performed on the branches, accepted values are "View", "Delete", or "Stop".
    .PARAMETER Repository
    Repository URL, parameter is validated to accept only URLs starting with "https://github.com/".
    .PARAMETER Token
    Specifies the personal access token for authentication with GitHub.
    .PARAMETER WorkflowRunIds
    Action to be performed on the branches, accepted values are "View", "Create", or "Delete".
    .PARAMETER Force
    Action to be performed on the branches, accepted values are "View", "Create", or "Delete".

    .EXAMPLE
    "https://github.com/your_user/your_repo" | Use-GitHubWorkflowRunsManager -Action View -Token "ghp_xyz" -Verbose
    Use-GitHubWorkflowRunsManager -Action Delete -Repository "https://github.com/your_user/your_repo" -Token "ghp_xyz" -Force
    Use-GitHubWorkflowRunsManager -Action Stop -Repository "https://github.com/your_user/your_repo" -Token "ghp_xyz" -WorkflowRunId "12345", "67890"

    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("View", "Delete", "Stop")]
        [string]$Action,

        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Repository,

        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$Token,

        [Parameter(Mandatory = $false, Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string[]]$WorkflowRunIds,

        [Parameter(Mandatory = $false, Position = 4)]
        [switch]$Force
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
        Write-Verbose -Message "Logged in to GitHub, continuing with selected operation $($Action)..."
    }
    PROCESS {
        $BaseUrl = 'https://api.github.com'
        $Headers = @{
            Authorization = 'Bearer ' + $Token
            Accept        = 'application/vnd.github.v3+json'
        }
        if ($Repository -like 'https://github.com/*') {
            $Repository = ($Repository -split '/')[3..4] -join '/'
        }
        $ApiUrl = $BaseUrl + '/repos/' + $Repository + '/actions/runs'
        try {
            $WorkflowRuns = Invoke-RestMethod -Uri $ApiUrl -Headers $Headers -Method Get -ErrorAction Stop
        }
        catch {
            Write-Error "Failed to retrieve workflow runs: $_"
            return
        }
        switch ($Action) {
            "View" {
                Write-Verbose -Message "Listing all Workflow Runs from all branches..."
                Write-Output -InputObject $WorkflowRuns.workflow_runs `
                | Format-Table id, created_at, updated_at, status, conclusion, name, event
            }
            "Delete" {
                $WorkflowRunIds = @()
                if ($WorkflowRunId) {
                    $WorkflowRunIds = $WorkflowRunId
                }
                else {
                    if (-not $Force) {
                        $ConfirmMessage = "Are you sure you want to delete all workflow runs for repository $Repository?"
                        $Confirmed = $false
                        $Confirmed = $Host.UI.PromptForChoice('Confirm', $ConfirmMessage, @( 'Yes', 'No' ), 1)
                        if ($Confirmed -eq 1) {
                            return
                        }
                    }
                    $WorkflowRunIds = $WorkflowRuns.workflow_runs.id
                }
                Write-Warning -Message "Deleting workflow runs..."
                foreach ($WorkflowRunId in $WorkflowRunIds) {
                    $WorkflowRunUrl = $BaseUrl + '/repos/' + $Repository + '/actions/runs/' + $WorkflowRunId
                    Write-Verbose -Message "Workflow Run URL: $WorkflowRunUrl"
                    try {
                        Invoke-RestMethod -Uri $workflowRunUrl -Headers $Headers -Method Delete -ErrorAction Stop -Verbose
                        Write-Host "Deleted workflow run '$WorkflowRunId'" -ForegroundColor Green
                    }
                    catch {
                        Write-Error "Failed to delete workflow run '$WorkflowRunId': $_"
                        continue
                    }
                }
            }
            "Stop" {
                $WorkflowRunIds = @()
                if ($WorkflowRunId) {
                    $WorkflowRunIds = $WorkflowRunId
                }
                else {
                    if (-not $Force) {
                        $ConfirmMessage = "Are you sure you want to stop all workflow runs for repository $Repository?"
                        $Confirmed = $false
                        $Confirmed = $Host.UI.PromptForChoice('Confirm', $ConfirmMessage, @( 'Yes', 'No' ), 1)
                        if ($Confirmed -eq 1) {
                            return
                        }
                    }
                    $WorkflowRunIds = $WorkflowRuns.workflow_runs.id
                }
                Write-Warning -Message "Stopping workflow runs..."
                foreach ($WorkflowRunId in $WorkflowRunIds) {
                    $WorkflowRunUrl = $BaseUrl + '/repos/' + $Repository + '/actions/runs/' + $WorkflowRunId + '/cancel'
                    Write-Verbose -Message "Workflow Run URL: $WorkflowRunUrl"
                    try {
                        $Response = Invoke-RestMethod -Uri $workflowRunUrl -Headers $Headers -Method Post -ErrorAction Stop
                        Write-Verbose -Message "Stopping Workflow runs...."
                        foreach ($WorkflowRun in $Response) {
                            Write-Host "Stopped WorkflowRuns: `n$($WorkflowRun.name)" -ForegroundColor Green
                        }
                    }
                    catch {
                        Write-Error "Failed to stop workflow run '$WorkflowRunId': $_"
                        continue
                    }
                }
            }
            default {
                throw "Invalid operation: $Action specified. Use -Action 'View', 'Delete' or 'Stop'!"
            }
        }
    }
    END {
        Write-Verbose -Message "Cleaning up, closing connection and exiting..."
        gh auth logout --hostname "github.com" ; Clear-History -Verbose -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:USERPROFILE\Desktop\ght.txt" -Force -Verbose -ErrorAction SilentlyContinue
        Clear-Variable -Name Repository, Token, WorkflowRunIds -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
        Remove-Variable -Name Repository, Token, WorkflowRunIds -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
    }
}
