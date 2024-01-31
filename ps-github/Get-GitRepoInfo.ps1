Function Get-GitRepoInfo {
    <#
    .SYNOPSIS
    Retrieves information about a Git repository, either from a local path or a remote URL.

    .DESCRIPTION
    This function provides details about a Git repository, including the repository name, URL, branch information, commit count, file count, and size.

    .PARAMETER Local
    Local path to the Git repository, used when retrieving information from a local repository.
    .PARAMETER Remote
    Remote URL of the Git repository, used when retrieving information from a remote repository.
    .PARAMETER Branch
    Specifies the branch name to retrieve information about, default is "main."
    .PARAMETER ListBranches
    Switch parameter to output a list of all branches in the repository.

    .EXAMPLE
    Get-GitRepoInfo -Local "C:\Path\To\Local\Repository"
    Get-GitRepoInfo -Remote "https://github.com/username/repo"

    .NOTES
    v0.1.8
    #>
    [CmdletBinding(DefaultParameterSetName = "Remote")]
    [OutputType("GitInfo")]
    param (
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Local")]
        [ValidateScript({ 
                Test-Path $_ -PathType Container
            })]
        [string]$Local,

        [Parameter(Mandatory = $true, Position = 2, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Remote")]
        [ValidateNotNullOrEmpty()]
        [string]$Remote,

        [Parameter(Mandatory = $false)]
        [ValidateSet("main", "master", "all")]
        [string]$Branch = "main",

        [Parameter()]
        [switch]$ListBranches
    )
    BEGIN {
        Write-Verbose -Message "Checking if Git is installed on the system..."
        if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
            Write-Verbose -Message "Git is not installed, downloading"
            $GitInstallURL = "https://github.com/git-for-windows/git/releases/download/v2.43.0.windows.1/Git-2.43.0-64-bit.exe"
            $GitInstallPath = "$env:TEMP\Git-2.43.0-64-bit.exe"
            Invoke-WebRequest -Uri $GitInstallURL -OutFile $GitInstallPath
            Write-Verbose -Message "Installing Git silently using the downloaded installer"
            $Arguments = '/VERYSILENT /NORESTART /SUPPRESSMSGBOXES /SP-'
            Start-Process -FilePath $GitInstallPath -ArgumentList $Arguments -Wait
        }
    }
    PROCESS {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        try { 
            $Object = $null
            if ($PSCmdlet.ParameterSetName -eq "Remote") {
                Write-Verbose "Retrieving information about the remote Git repository $Remote"
                $Output = git ls-remote $Remote
                $RepoName = $Remote.Split('/')[-1].Split('.')[0]
                $Branches = $output -replace '^.*refs/heads/', '' -replace '\s.*$' , '' | Select-Object -Unique
                $BranchesCount = $Branches.Count
                $CommitsCount = ($output | Measure-Object).Count
                $Object = [PSCustomObject]@{
                    PSTypeName    = "GitInfo"
                    Name          = $RepoName
                    Url           = $Remote
                    Branch        = $Branch
                    Branches      = $Branches
                    BranchesCount = $BranchesCount
                    Commits       = $CommitsCount
                    Date          = Get-Date
                }
            }
            elseif ($PSCmdlet.ParameterSetName -eq "Local") {
                $FullPath = Resolve-Path -Path $Local
                Write-Verbose -Message "Processing path $FullPath"
                $GitPath = Join-Path $FullPath ".git"
                if (Test-Path -Path $GitPath) {
                    Write-Verbose "Retrieving information about the local Git repository $FullPath"
                    $CommitCount = git -C $FullPath rev-list --count HEAD
                    $Stat = Get-ChildItem -Path $GitPath -Recurse -File | Measure-Object -Property Length -Sum
                    $Object = [PSCustomObject]@{
                        PSTypeName = "GitInfo"
                        Path       = $FullPath
                        Name       = Split-Path -Path $FullPath -Leaf
                        Files      = $Stat.Count
                        Size       = $Stat.Sum
                        SizeKB     = $Stat.Sum / 1KB
                        SizeMB     = $Stat.Sum / 1MB
                        SizeGB     = $Stat.Sum / 1GB
                        Branch     = $Branch
                        Commits    = $CommitCount
                        Date       = Get-Date
                    }
                }
                else {
                    Write-Host "Git repository not found in $FullPath" -ForegroundColor Red
                }
            }
            if ($Object -and $ListBranches) {
                Write-Output -InputObject $Object.Branches
            }
            return $Object
        }
        catch {
            Write-Verbose -Message "Error: $($_.Exception.Message)"
            Write-Error -Message "Failed to retrieve repository information: $_"
        }
    }
}
