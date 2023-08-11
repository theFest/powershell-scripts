Function GetGitHubContent {
    <#
    .SYNOPSIS
    GitHub content downloader with extended capabilities.

    .DESCRIPTION
    This function enables you to download single or multiple files/directories directly from GitHub using various authentication methods. It also supports downloading from specific commits and tagging.

    .PARAMETER AuthToken
    Mandatory - GitHub Personal Access Token (PAT) for authentication.
    .PARAMETER AuthMethod
    NotMandatory - authentication method to use, possible values: "PAT" (Personal Access Token), "Basic" (Basic Authentication).
    .PARAMETER Paths
    Mandatory - paths to download from the repository, can include files or directories.
    .PARAMETER Owner
    Mandatory - owner of the GitHub repository.
    .PARAMETER Repository
    Mandatory - name of the GitHub repository.
    .PARAMETER Branch
    NotMandatory - branch name of the GitHub repository, default is "main".
    .PARAMETER Commit
    NotMandatory - commit hash to download content from a specific commit.
    .PARAMETER Tag
    NotMandatory - tag name to download content from a specific tag.
    .PARAMETER DestinationPath
    NotMandatory - local destination path to save the downloaded files, default is "$env:USERPROFILE\Desktop".
    .PARAMETER GitHubBaseUrl
    NotMandatory - base URL for the GitHub content, default is "https://raw.githubusercontent.com".

    .EXAMPLE
    GetGitHubContent -Owner "your_GitHub_name" -Repository "your_repo_name" -Branch "your_branch" -AuthToken "ghp_xyz" -Paths "your_repo_folder/your_file_on_GitHub.ps1" -Verbose
    GetGitHubContent -Owner "your_GitHub_name" -Repository "your_repo_name" -Branch "your_branch" -AuthToken "ghp_xyz" -Paths "your_repo_folder/your_file_on_GitHub.ps1", "your_repo_folder/your_file_on_GitHub.ps1"
    "ghp_xyz" | GetGitHubContent -Owner "theFest" -Repository "PowerShell-Scripts" -Branch "main" -Paths "your_repo_folder/your_file_on_GitHub.ps1" -Commit "commit_hash" -DestinationPath "$env:SystemDrive\Temp"
    
    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AuthToken,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Paths,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Owner,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Repository,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Branch = "main",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Commit,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Tag,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$DestinationPath = "$env:USERPROFILE\Desktop",

        [Parameter(Mandatory = $false)]
        [string]$GitHubBaseUrl = "https://raw.githubusercontent.com",

        [Parameter(Mandatory = $false)]
        [ValidateSet("PAT", "Basic")]
        [string]$AuthMethod = "PAT"
    )
    BEGIN {
        if (-not (Test-Path -Path $DestinationPath)) {
            Write-Verbose -Message "Creating new folder..."
            New-Item -ItemType Directory -Path $DestinationPath -InformationAction SilentlyContinue -Verbose
        }
    }
    PROCESS {
        try {
            foreach ($Path in $Paths) {
                Write-Verbose -Message "Preparing to download files..."
                $DecodedPath = [Uri]::UnescapeDataString($Path)
                if ($Commit) {
                    $ContentUrl = "$GitHubBaseUrl/$Owner/$Repository/$Commit/$DecodedPath"
                }
                elseif ($Tag) {
                    $ContentUrl = "$GitHubBaseUrl/$Owner/$Repository/$Tag/$DecodedPath"
                }
                else {
                    $ContentUrl = "$GitHubBaseUrl/$Owner/$Repository/$Branch/$DecodedPath"
                }
                $DestinationFile = Join-Path -Path $DestinationPath -ChildPath $DecodedPath
                $DestinationDirectory = Split-Path -Path $DestinationFile -Parent
                if (-not (Test-Path -Path $DestinationDirectory)) {
                    New-Item -ItemType Directory -Path $DestinationDirectory -Force -Verbose
                }
                try {
                    $Headers = @{
                        "User-Agent" = "powershell-script"
                    }
                    if ($AuthMethod -eq "PAT") {
                        $Headers["Authorization"] = "Bearer $AuthToken"
                    }
                    elseif ($AuthMethod -eq "Basic") {
                        $Base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$AuthToken"))
                        $Headers["Authorization"] = "Basic $Base64Auth"
                    }
                    $Response = Invoke-WebRequest -Uri $ContentUrl -Headers $Headers -UseBasicParsing -ErrorAction Stop
                    if ($Response.StatusCode -eq 200) {
                        $ContentBytes = [System.Text.Encoding]::UTF8.GetBytes($Response.Content)
                        [System.IO.File]::WriteAllBytes($DestinationFile, $ContentBytes)
                        Write-Output -InputObject "Downloaded: $($Response.BaseResponse.ResponseUri.AbsoluteUri)"
                    }
                    else {
                        Write-Error -Message "Failed to download: $ContentUrl. Status code: $($Response.StatusCode)"
                    }
                }
                catch {
                    Write-Error -Message "Failed to download: $ContentUrl. Error: $($_.Exception.Message)"
                }
            }
        }
        catch {
            Write-Error -Message "An error occurred while downloading content. Error: $($_.Exception.Message)"
        }
    }
    END {
        Write-Host "Finished, cleaning and exiting..."
        Clear-History -Verbose -ErrorAction SilentlyContinue
        Clear-Variable -Name AuthToken, Owner, Repository, Paths -Scope Global -Force -ErrorAction SilentlyContinue
        Remove-Variable -Name AuthToken, Owner, Repository, Paths -Scope Global -Force -ErrorAction SilentlyContinue
    }
}
