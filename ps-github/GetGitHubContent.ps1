Function GetGitHubContent {
    <#
    .SYNOPSIS
    GitHub content downloader.
    
    .DESCRIPTION
    This function enables you to download single or multiple file direcly from GitHub using Personal Access Token.
    
    .PARAMETER PAT
    Mandatory - Personal Access Token (PAT) for GitHub authentication.
    .PARAMETER Paths
    Mandatory - paths to download from the repository.
    .PARAMETER Owner
    Mandatory - owner of the GitHub repository
    .PARAMETER Repository
    Mandatory - name of the GitHub repository.
    .PARAMETER Branch
    Mandatory - branch name of the GitHub repository.
    .PARAMETER DestinationPath
    NotMandatory - local destination path to save the downloaded files.
    .PARAMETER GitHubBaseUrl
    NotMandatory - base URL for the GitHub content.
    
    .EXAMPLE
    #GetGitHubContent -Owner "your_GitHub_name" -Repository "your_repo_name" -Branch "you_branch" -PAToken "ghp_xyz" -Paths "your_repo_folder/your_file_on_GitHub.ps1"
    "ghp_xyz" | GetGitHubContent -Owner "your_GitHub_name" -Repository "your_repo_name" -Branch "you_branch" -Paths "your_repo_folder/your_file_2.ps1", "your_repo_folder/your_file_2.ps1"
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$PAToken,

        [Parameter(Mandatory = $true)]
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
        [string]$DestinationPath = "$env:USERPROFILE\Desktop",

        [Parameter(Mandatory = $false)]
        [string]$GitHubBaseUrl = "https://raw.githubusercontent.com"
    )
    try {
        if (-not (Test-Path -Path $DestinationPath)) {
            New-Item -ItemType Directory -Path $DestinationPath -Force -Verbose
        }
        foreach ($Path in $Paths) {
            Write-Verbose -Message "Preparing to download file's..."
            $DecodedPath = [Uri]::UnescapeDataString($Path)
            $ContentUrl = "$GitHubBaseUrl/$Owner/$Repository/$Branch/$DecodedPath"
            $DestinationFile = Join-Path -Path $DestinationPath -ChildPath $DecodedPath
            $DestinationDirectory = Split-Path -Path $DestinationFile -Parent
            if (-not (Test-Path -Path $DestinationDirectory)) {
                New-Item -ItemType Directory -Path $DestinationDirectory -Force -Verbose
            }
            try {
                $Response = Invoke-WebRequest -Uri $ContentUrl -Headers @{
                    "Authorization" = "Bearer $PAToken"
                    "User-Agent"    = "powershell-script"
                } -UseBasicParsing -ErrorAction Stop
                $Content = $Response.Content
                $Content | Out-File -FilePath $DestinationFile -Force -ErrorAction Stop
                Write-Output -InputObject "Downloaded: $($Response.BaseResponse.ResponseUri.AbsoluteUri)"
            }
            catch {
                Write-Error -Message "Failed to download: $ContentUrl. Error: $($_.Exception.Message)"
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred while downloading content. Error: $($_.Exception.Message)"
    }
    Write-Verbose -Message "Finished, cleaning and exiting..."
    Clear-History -Verbose -ErrorAction SilentlyContinue
    Clear-Variable -Name PAToken, Owner, Repository, Paths -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
    Remove-Variable -Name PAToken, Owner, Repository, Paths -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
}
