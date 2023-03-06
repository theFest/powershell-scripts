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

    .EXAMPLE
    GetGitInfo -LocalPath "$env:SystemDrive\your_local_repo"
    GetGitInfo -RemoteUrl "https://github.com/your/remote_repo"

    .NOTES
    v0.1.0
    #>
    [CmdletBinding()]
    [OutputType("GitInfo")]
    Param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [string]$Path = ".",

        [Parameter()]
        [string]$RemoteUrl,

        [Parameter()]
        [string]$LocalPath
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
        if ($RemoteUrl) {
            Write-Verbose "Retrieving information about remote Git repository $RemoteUrl"
            $Output = git ls-remote $RemoteUrl
            $RepoName = $RemoteUrl.Split('/')[-1].Split('.')[0]
            $Object = [PSCustomObject]@{
                PSTypeName   = "GitInfo"
                Name         = $RepoName
                Url          = $RemoteUrl
                Branches     = ($Output -replace '^.*refs/heads/', '' -replace '\s.*$' , '' | Select-Object -Unique) -join ', '
                Commits      = ($Output | Measure-Object).Count
                ComputerName = $env:COMPUTERNAME
                Date         = Get-Date
            }
        }
        elseif ($LocalPath) {
            $FullPath = Resolve-Path -Path $LocalPath
            Write-Verbose -Message "Processing path $FullPath"
            $GitPath = Join-Path $FullPath ".git"
            Write-Verbose -Message  "Checking if $GitPath exists"
            if (Test-Path -Path $GitPath) {
                Write-Verbose "Retrieving information about local Git repository $FullPath"
                $CommitCount = git -C $FullPath rev-list --count HEAD
                $Stat = Get-ChildItem -Path $GitPath -Recurse -File `
                | Measure-Object -Property Length -Sum
                $Object = [PSCustomObject]@{
                    PSTypeName   = "GitInfo"
                    Path         = $FullPath
                    Name         = Split-Path -Path $FullPath -Leaf
                    Files        = $Stat.Count
                    Size         = $Stat.Sum
                    SizeKB       = $Stat.Sum / 1KB
                    SizeMB       = $Stat.Sum / 1MB
                    SizeGB       = $Stat.Sum / 1GB
                    Commits      = $CommitCount
                    ComputerName = $env:COMPUTERNAME
                    Date         = Get-Date
                }
            }
            else {
                Write-Verbose -Message "Git repository not found in $FullPath"
            }
        }
        else {
            Write-Verbose -Message "No Git repository specified"
        }
        return $Object
    }
    END {
        Write-Verbose -Message "Ending $($MyInvocation.MyCommand)"
    }
}
