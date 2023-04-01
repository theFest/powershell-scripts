Function RemoveGitHubRepositories {
    <#
    .SYNOPSIS
    Deletes one or more repositories on GitHub.

    .DESCRIPTION
    This function can be used to delete one or more repositories on GitHub. It uses the GitHub CLI to authenticate and interact with the GitHub API.

    .PARAMETER Repositories
    Mandatory - array of repositories to be deleted. Each repository should be in the format "username/reponame".
    .PARAMETER Token
    Mandatory - the authentication token to use for interacting with the GitHub API.
    .PARAMETER InputFile
    NotMandatory - string that specifies the path of a file containing a list of repositories to delete, one per line.
    .PARAMETER Confirm
    NotMandatory - switch parameter that prompts the user to confirm each repository deletion.
    .PARAMETER InputDelimiter
    NotMandatory - string that specifies the delimiter character used in the input file. The default value is a comma.

    .EXAMPLE
    RemoveGitHubRepositories -Repositories "username/repo1","username/repo2" -Token "ghp_xyz123"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Repositories,

        [Parameter(Mandatory = $true)]
        [string]$Token,

        [Parameter(Mandatory = $false)]
        [string]$InputFile,

        [Parameter(Mandatory = $false)]
        [switch]$Confirm,

        [Parameter(Mandatory = $false)]
        [string]$InputDelimiter = ","
    )
    BEGIN {
        if (-not(Get-Command gh -ErrorAction SilentlyContinue)) {
            Write-Verbose "Installing GitHub CLI..."
            $Ps = [System.Management.Automation.PowerShell]::Create()
            $null = $Ps.AddScript('Invoke-WebRequest https://cli.github.com/packages/gh-stable-windows-amd64.zip -OutFile gh.zip')
            $null = $Ps.AddScript('Expand-Archive gh.zip -DestinationPath $env:LOCALAPPDATA\gh')
            $null = $Ps.AddScript('$env:Path = "$env:LOCALAPPDATA\gh\bin;$env:Path"')
            $null = $Ps.AddScript('gh --version')
            $null = $Ps.Invoke()
            $ps.Dispose()
        }
        Write-Verbose -Message "Checking if token is valid..."
        $CheckToken = gh auth status --token=$Token
        if ($CheckToken.Status -ne "Logged in to github.com") {
            Write-Verbose -Message "Not logged in or invalid token."
        }
        gh auth login -t $Token
    }
    PROCESS {
        if ($InputFile) {
            if (!(Test-Path $InputFile)) {
                throw "Input file '$InputFile' not found."
            }
            $Repositories = Get-Content $InputFile `
            | ConvertFrom-Csv -Delimiter $InputDelimiter `
            | Select-Object -ExpandProperty Repositories
        }
        foreach ($repo in $Repositories) {
            Write-Verbose -Message "Deleting repository $Repo..."
            if ($Confirm) {
                $ConfirmMessage = "Are you sure you want to delete repository $Repo?"
                $Confirmed = $false
                $Confirmed = $Host.UI.PromptForChoice('Confirm', $ConfirmMessage, @( 'Yes', 'No' ), 1)
                if ($Confirmed -eq 1) {
                    continue
                }
            }
            $Url = "repos/$Repo"
            gh api $Url -X DELETE --token=$Token > $null
        }
    }
    END {
        gh auth logout
        Write-Host "All repositories deleted." -ForegroundColor Green
        Clear-Variable -Name Repositories, Token -Force -ErrorAction SilentlyContinue
    }
}
