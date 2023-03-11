Function GetGitInfo {
    <#
    .SYNOPSIS
    Gets information about a Git repository.

    .DESCRIPTION
    This function gets information about a Git repository, including the remote URL of the repository, the local path of the repository, and the status of the repository (whether there are uncommitted changes or not).

    .PARAMETER Path
    NotMandatory - local path of the Git repository to get information for. If not specified, the function will use the current directory.
    .PARAMETER RemoteUrl
    NotMandatory - either this or LocalPath, the function will set the remote URL of the repository to the specified value.
    .PARAMETER LocalPath
    NotMandatory - either this or RemoteUrl, the function will move the repository to the specified local path.
    .PARAMETER Branch
    NotMandatory - main is predefined, choose what's your default.
    .PARAMETER ListBranches
    NotMandatory - switch parameter for listing branches.

    .EXAMPLE
    GetGitInfo -LocalPath "$env:SystemDrive\Repos\your_local_repo"
    GetGitInfo -Remote "https://github.com/powershell/powershell" -Verbose
    GetGitInfo -Remote "https://github.com/powershell/powershell" -ListBranches -Verbose

    .NOTES
    v0.1.1
    #>
    [CmdletBinding(DefaultParameterSetName = "Remote")]
    [OutputType("GitInfo")]
    Param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Path = (Get-Location).Path,

        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline, ValueFromPipelineByPropertyName, ParameterSetName = "Local")]
        [ValidateScript({ Test-Path $_ -PathType Container })]
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
        Write-Verbose -Message "Starting $($MyInvocation.MyCommand)"
        ## Check if Git is installed on the system
        if (-not (Get-Command git.exe -ErrorAction SilentlyContinue)) {
            ## If Git is not installed, download the Git for Windows installer
            $GitInstallURL = 'https://github.com/git-for-windows/git/releases/download/v2.31.1.windows.1/Git-2.31.1-64-bit.exe'
            $GitInstallPath = 'C:\Temp\Git-Installer.exe'
            Invoke-WebRequest -Uri $GitInstallURL -OutFile $GitInstallPath
            ## Install Git silently using the downloaded installer
            $Arguments = '/VERYSILENT /NORESTART /SUPPRESSMSGBOXES /SP-'
            Start-Process -FilePath $GitInstallPath -ArgumentList $Arguments -Wait
        }
    }
    PROCESS {
        try {
            if ($PSCmdlet.ParameterSetName -eq "Remote") {
                Write-Verbose "Retrieving information about remote Git repository $Remote"
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
                Write-Verbose -Message  "Checking if $GitPath exists, running on $env:COMPUTERNAME"
                if (Test-Path -Path $GitPath) {
                    Write-Verbose "Retrieving information about local Git repository $FullPath"
                    $CommitCount = git -C $FullPath rev-list --count HEAD
                    $Stat = Get-ChildItem -Path $GitPath -Recurse -File `
                    | Measure-Object -Property Length -Sum
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
                    Write-Verbose -Message "Git repository not found in $FullPath"
                }
            }
            if ($ListBranches) {
                Write-Output -InputObject $Object.Branches
            }
            return $Object
        }
        catch {
            Write-Verbose -Message "Error: $($_.Exception.Message)"
            Write-Error "Failed to retrieve repository size information for $_"
        }
    }
}
