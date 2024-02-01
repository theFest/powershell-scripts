#Requires -Version 5.1
Set-StrictMode -Version Latest -Verbose
Function Use-GitHubFollowersManager {
    <#
    .SYNOPSIS
    Simple followers management of a your GitHub account.

    .DESCRIPTION
    This function uses GitHub CLI to add a new follower or remove an existing follower, it can also check followers of an account and output the results to the console and/or a CSV file.

    .PARAMETER Action
    Action to be performed, values are 'CheckFollowers', 'AddFollower', or 'RemoveFollower'.
    .PARAMETER Username
    Your GitHub account username whose followers are to be managed.
    .PARAMETER Token
    Valid personal access token for the GitHub account.
    .PARAMETER FollowerUsername
    GitHub account username to be added or removed from the follower list.
    .PARAMETER OutputFile
    Path and filename for the CSV file to which the list of followers should be output.

    .EXAMPLE
    "your_GitHub_user" | Use-GitHubFollowersManager -Action CheckFollowers -Token "ghp_xyz" -Verbose
    Use-GitHubFollowersManager -Action AddFollower -Username "your_GitHub_user" -Token "ghp_xyz" -FollowerUsername "user_to_follow"
    Use-GitHubFollowersManager -Action RemoveFollower -Username "your_GitHub_user" -Token "ghp_xyz" -FollowerUsername "user_to_unfollow"

    .NOTES
    v0.0.4
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("CheckFollowers", "AddFollower", "RemoveFollower")]
        [string]$Action,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Token,

        [Parameter(Mandatory = $false)]
        [string]$FollowerUsername,

        [Parameter(Mandatory = $false)]
        [string]$OutputFile
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
        $Headers = @{"Authorization" = "Token $Token" }
        switch ($Action) {
            "CheckFollowers" {
                $PageNumber = 1
                $FollowerList = @()
                do {
                    $Followers = (Invoke-RestMethod -Headers $Headers -Uri "https://api.github.com/users/$Username/followers?page=$PageNumber&per_page=100")
                    $FollowerList += $Followers ; $PageNumber++
                } while ($Followers.Count -gt 0)
                $FollowerList | Select-Object login, html_url | Sort-Object login | Format-Table -AutoSize
                if ($OutputFile) {
                    $FollowerList | Select-Object login, html_url | Sort-Object login | Export-Csv -Path $OutputFile -NoTypeInformation
                }
            }
            "AddFollower" {
                $Result = Invoke-RestMethod -Headers $Headers -Method Put -Uri "https://api.github.com/user/following/$FollowerUsername"
                if ($Result) {
                    Write-Host "$FollowerUsername has been successfully added to $Username's followers list." -ForegroundColor Green
                }
            }
            "RemoveFollower" {
                $Result = Invoke-RestMethod -Headers $Headers -Method Delete -Uri "https://api.github.com/user/following/$FollowerUsername"
                if ($Result) {
                    Write-Host "$FollowerUsername has been successfully removed from $Username's followers list." -ForegroundColor Green
                }
            }
            default {
                Write-Error "Invalid action specified. Please specify either 'CheckFollowers', 'AddFollower', or 'RemoveFollower'."
            }
        }
    }
    END {
        Write-Verbose -Message "Cleaning up, closing connection and exiting..."
        gh auth logout --hostname "github.com" ; Clear-History -Verbose -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:USERPROFILE\Desktop\ght.txt" -Force -Verbose -ErrorAction SilentlyContinue
        Clear-Variable -Name Username, Token, FollowerUsername -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
        Remove-Variable -Name Username, Token, FollowerUsername -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
        Write-Host "Operation $($Action) completed for user: $($Username)" -ForegroundColor Green
    }
}
