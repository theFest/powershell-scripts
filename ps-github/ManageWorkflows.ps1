#Requires -Version 5.1
Write-Host "Catch certain types of errors at runtime, such as referencing undefined variables" -ForegroundColor DarkCyan
Set-StrictMode -Version Latest -Verbose
Function ManageWorkflows {
    <#
    .SYNOPSIS
    Simple function for managing workflows in a GitHub repository using GitHub CLI.

    .DESCRIPTION
    This function uses GitHub CLI to manage GitHub workflows in a repository, it can list all the workflows in a repository, enable/disable a workflow, or delete all the workflow runs.

    .PARAMETER Action
    Mandatory - action to be performed on the branches, accepted values are "List", "Enable", "Disable" or "Delete".
    .PARAMETER Repository
    Mandatory - repository URL, parameter is validated to accept only URLs starting with "https://github.com/".
    .PARAMETER Token
    Mandatory - specifies the personal access token for authentication with GitHub.
    .PARAMETER ExportPath
    NotMandatory - declare the path to export the workflow runs if the operation is "Delete".
    .PARAMETER Force
    NotMandatory - forces the command to run without asking for user confirmation if the operation is "Delete".

    .EXAMPLE
    "https://github.com/your_user/your_repo" | ManageWorkflows -Action List -Token "ghp_xyz" -Verbose
    ManageWorkflows -Action Enable -Repository "https://github.com/your_user/your_repo" -Token "ghp_xyz" -Verbose
    ManageWorkflows -Action Disable -Repository "https://github.com/your_user/your_repo" -Token "ghp_xyz" -Verbose
    ManageWorkflows -Action Delete -Repository "https://github.com/your_user/your_repo" -Token "ghp_xyz" -Force -Verbose
    "https://github.com/your_user/your_repo" | ManageWorkflows -Action List -Token "ghp_xyz" -ExportPath "$env:USERPROFILE\Desktop\your_workflows_output.csv" -Verbose

    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Action to be performed, available actions are: 'List', 'Enable', 'Disable', 'Delete'")]
        [ValidateSet("List", "Enable", "Disable", "Delete")]
        [string]$Action,

        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, HelpMessage = "Name of the repository")]
        [ValidateNotNullOrEmpty()]
        [string]$Repository,

        [Parameter(Mandatory = $true, Position = 2, HelpMessage = "GitHub token(PAT) for authentication")]
        [ValidateNotNullOrEmpty()]
        [string]$Token,

        [Parameter(Mandatory = $false, HelpMessage = "Export path for the output or detailed workflows")]
        [ValidateNotNullOrEmpty()]
        [string]$ExportPath,

        [Parameter(Mandatory = $false, HelpMessage = "Forces the action to be performed without prompting for confirmation")]
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
        Write-Verbose -Message "Logged in to GitHub, continuing with selected operation $($Operation)..."
    }
    PROCESS {
        $Owner, $RepositoryName = ($Repository -split '/')[-2, -1]
        $RepositoryPath = "repos/$Owner/$RepositoryName"
        Write-Verbose -Message "Fetching workflows from given repository..."
        $Workflows = gh api "$RepositoryPath/actions/workflows" --paginate | ConvertFrom-Json
        if (!$Workflows.workflows) {
            Write-Verbose -Message "No workflows found!"
            return
        }
        switch ($Action) {
            "List" {
                Write-Verbose -Message "Listing workflows..."
                $Workflows.workflows | Select-Object name, id, state, path | Format-Table -AutoSize
            }
            "Enable" {
                Write-Verbose -Message "Enabling workflows, please wait..."
                foreach ($Workflow in $Workflows.workflows) {
                    if ($Workflow.state -ne "enabled") {
                        Write-Verbose -Message "Enabling workflow ($($Workflow.name)) ($($Workflow.id))"
                        try {
                            $Url = "$RepositoryPath/actions/workflows/$($workflow.id)/enable"
                            gh api $Url -X PUT -H "Authorization: Bearer $Token" -H "Content-Type: application/json"
                            Write-Verbose -Message "Workflow $($Workflow.name) enabled successfully."
                        }
                        catch {
                            Write-Error -Message "Failed to enable workflow $($Workflow.name) ($($Workflow.id)): $($_.Exception.Message)"
                        }
                    }
                    else {
                        Write-Warning -Message "Workflow $($Workflow.name) ($($Workflow.id)) is already enabled"
                    }
                }
            }
            "Disable" {
                Write-Verbose -Message "Disabling workflows, please wait..."
                foreach ($Workflow in $Workflows.workflows) {
                    if ($Workflow.state -ne "disabled") {
                        Write-Verbose -Message "Disabling workflow ($($Workflow.name)) ($($Workflow.id))"
                        $Url = "$RepositoryPath/actions/workflows/$($Workflow.id)/disable"
                        try {
                            gh api $Url -X PUT -H "Authorization: Bearer $Token" -H "Content-Type: application/json"
                            Write-Verbose -Message "Workflow $($Workflow.name) disabled successfully."
                        }
                        catch {
                            Write-Error -Message "Failed to disable workflow $($Workflow.name) ($($Workflow.id)): $($_.Exception.Message)"
                        }
                    }
                    else {
                        Write-Warning -Message "Workflow $($Workflow.name) ($($Workflow.id)) is already disabled"
                    }
                }
            }
            "Delete" {
                Write-Verbose -Message "Extracting repository name from URL using regular expressions..."
                $RepoName = $Repository -replace '.*github\.com/([^/]+)/([^/]+)/?', '$1/$2'
                $Url = "repos/$RepoName/actions/runs"
                Write-Verbose -Message "Fetching workflow runs from given repository..."
                $Runs = gh api $Url -H "Authorization: token $token" | ConvertFrom-Json
                Write-Warning -Message "Deleting all workflows runs before removing workflows..."
                foreach ($Run in $Runs.workflow_runs) {
                    $RunUrl = "repos/$RepoName/actions/runs/$($Run.id)"
                    Write-Verbose "Deleting workflow run with ID $($Run.id)..."
                    try {
                        gh api $RunUrl -X DELETE -H "Authorization: token $Token" > $null
                    }
                    catch {
                        Write-Error "Failed to delete workflow $($Workflow.name) ($($Workflow.id)): $($_.Exception.Message)"
                    }
                }
                Write-Warning -Message "Deleting all workflows for the given repository..."
                $Workflows = gh api "repos/$RepoName/actions/workflows" -H "Authorization: token $Token" | ConvertFrom-Json
                foreach ($Workflow in $Workflows.workflows) {
                    Write-Verbose -Message "Deleting workflow $($Workflow.name)..."
                    $WorkflowUrl = "repos/$RepoName/actions/workflows/$($Workflow.id)"
                    try {
                        gh api $WorkflowUrl -X DELETE -H "Authorization: token $Token" > $null
                    }
                    catch {
                        Write-Error "Failed to delete workflow $($Workflow.name) ($($Workflow.id)): $($_.Exception.Message)"
                    }
                }
                Write-Host "Workflow runs and workflows deleted successfully for repository $RepoName." -ForegroundColor Green
            }
            default {
                throw "Invalid operation: $Operation specified. Use -Operation 'List', 'Enable', 'Disable' or 'Delete'!"
            }
        }
        if ($ExportPath) {
            Write-Verbose -Message "Viewing and exporting available workflow actions..."
            try {
                $Actions = gh api "$RepositoryPath/actions/workflows" | ConvertFrom-Json
            }
            catch {
                Write-Error -Message "Failed to retrieve available actions: $($_.Exception.Message)"
                return
            }
            $Actions.workflows | Select-Object * | Export-Csv -Path $ExportPath -NoTypeInformation -Force -Verbose
        }
    }
    END {
        Write-Verbose -Message "Cleaning up, closing connection and exiting..."
        gh auth logout --hostname "github.com" ; Clear-History -Verbose -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:USERPROFILE\Desktop\ght.txt" -Force -Verbose -ErrorAction SilentlyContinue
        Clear-Variable -Name Repository, Token -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
        Remove-Variable -Name Repository, Token -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
    }
}
