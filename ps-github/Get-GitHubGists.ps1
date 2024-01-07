Function Get-GitHubGists {
    <#
    .SYNOPSIS
    Retrieves and lists all Gists for a GitHub user.

    .DESCRIPTION
    This function fetches all Gists associated with a GitHub user account along with their detail information.

    .PARAMETER Username
    Mandatory - specifies the GitHub username for which Gists will be retrieved.
    .PARAMETER UserToken
    NotMandatory - personal access token for authentication, it's optional for public profiles.

    .EXAMPLE
    Get-GitHubGists -Username "some_github_user"
    Get-GitHubGists -Username "some_github_user" -UserToken "ghp_xyz"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Specify the GitHub username")]
        [ValidateNotNullorEmpty()]
        [Alias("u")]
        [string]$Username,

        [Parameter(Mandatory = $false, HelpMessage = "Provide a GitHub personal access token")]
        [Alias("t")]
        [string]$UserToken
    )
    BEGIN {
        $Headers = @{}
        $BaseURL = "https://api.github.com/users/$Username/gists"
        if ($UserToken) {
            $Headers['Authorization'] = "Bearer $UserToken"
        }
    }
    PROCESS {
        try {
            $Result = Invoke-RestMethod -Uri $BaseURL -Method Get -Headers $Headers -ErrorAction Stop
            if ($Result) {
                Write-Output -InputObject $Result
            }
        }
        catch {
            Write-Verbose -Message "Failed to retrieve Gists for user: $Username"
            Write-Error -Exception $_.Exception.Message
        }
    }
    END {
        Clear-Variable -Name "Headers" -Force -Verbose
    }
}
