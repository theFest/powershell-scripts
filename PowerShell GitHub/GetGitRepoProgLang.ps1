Function GetGitRepoProgLang {
    <#
    .SYNOPSIS
    This function is used to download a Git repository and get all the source code files in the repository that are written in a specified programming language.

    .DESCRIPTION
    Function can take either a local repository path or a remote repository path. If a remote repository path is provided, the function will download the repository to a temporary folder and change the current working directory to the cloned repository.
    We can filter files by extension based on the specified programming language. The function also supports filtering files based on the maximum depth of subdirectories to search, as well as including and excluding files based on patterns.

    .PARAMETER LocalRepoPath
    Mandatory - the local path to a Git repository.
    .PARAMETER RemoteRepoPath
    Mandatory - the remote path to a Git repository.
    .PARAMETER CloneRemoteRepoPath
    NotMandatory - the local path where the remote repository will be cloned, default value is "$env:TEMP".
    .PARAMETER Language
    NotMandatory - the programming language to filter files by extension, default value is "all".
    .PARAMETER MaxDepth
    NotMandatory - maximum depth of subdirectories to search, default value is [int]::MaxValue.
    .PARAMETER Exclude
    NotMandatory - an array of patterns to exclude files.
    .PARAMETER Include
    NotMandatory - an array of patterns to include files.
    .PARAMETER RepoClonePath
    NotMandatory - local path where the remote repository is cloned, default value is "$env:TEMP".
    .PARAMETER RedirectStandardOutput
    NotMandatory - file path to redirect standard output, default value is "$env:TEMP\GetGitRepoProgLang_strout.txt".
    .PARAMETER RedirectStandardError
    NotMandatory - file path to redirect standard erroe, default value is "$env:TEMP\GetGitRepoProgLang_strerror.txt".
    .PARAMETER Recurse
    NotMandatory - switch to enable recursive searching of subdirectories.

    .EXAMPLE
    GetGitRepoProgLang -RemoteRepoPath "https://github.com/powershell/powershell"
    GetGitRepoProgLang -LocalRepoPath "C:\your_git_repo" -Language "powershell" -MaxDepth 2 -Recurse

    .NOTES
    v0.1.4
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "LocalRepoPath", Position = 0)]
        [ValidateScript({ Test-Path $_ -PathType "Container" })]
        [string]$LocalRepoPath,

        [Parameter(Mandatory = $true, ParameterSetName = "RemoteRepoPath", Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$RemoteRepoPath,

        [Parameter(Mandatory = $false, ParameterSetName = "RemoteRepoPath", Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$CloneRemoteRepoPath = "$env:TEMP",

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateSet("all", "c", "cpp", "csharp", "go", "java", "javascript", "php", `
                "python", "ruby", "rust", "powershell", "html", "css", "xml", "swift", "kotlin", `
                "typescript", "dart", "groovy", "lua", "scala", "shell", "sql", "yaml", "perl", "r", `
                "vb.net", "matlab", "f#", "objective-c", "vbscript", "batch", "haskell", "visualbasic")]
        [string]$Language = "all",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$MaxDepth = [int]::MaxValue,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Exclude,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Include,

        [Parameter(Mandatory = $false)]
        [string]$RepoClonePath = "$env:TEMP",

        [Parameter(Mandatory = $false)]
        [string]$RedirectStandardOutput = "$env:TEMP\GetGitRepoProgLang_strout.txt",

        [Parameter(Mandatory = $false)]
        [string]$RedirectStandardError = "$env:TEMP\GetGitRepoProgLang_strerror.txt",

        [Parameter()]
        [switch]$Recurse
    )
    if ($LocalRepoPath) {
        Set-Location -Path $LocalRepoPath -Verbose
    }
    else {
        $RepoName = $RemoteRepoPath.Split('/')[-1].TrimEnd('.git')
        $RepoClonePath = Join-Path -Path $RepoClonePath -ChildPath $RepoName
        Write-Verbose -Message "Cloning $RemoteRepoPath to $RepoClonePath ..."
        if (!(Test-Path -Path $RepoClonePath)) {
            $GitProcess = Start-Process -FilePath "git" -ArgumentList "clone", $RemoteRepoPath, $RepoClonePath `
                -PassThru -RedirectStandardOutput $RedirectStandardOutput -RedirectStandardError $RedirectStandardError -WindowStyle Hidden
            Write-Warning -Message "Downloading Repository: $RemoteRepoPath to $RepoClonePath ..."
            $GitProcess.WaitForExit()
        }
        Set-Location $RepoClonePath -Verbose
    }
    try {
        $Files = Get-ChildItem -File -Depth $MaxDepth -Exclude $Exclude -Include $Include
        if ($Recurse) {
            $Files += Get-ChildItem -File -Recurse -Depth ($MaxDepth - 1) -Exclude $Exclude -Include $Include
        }
        $Languages = @{
            "c"           = ".c"
            "cpp"         = ".cpp"
            "csharp"      = ".cs"
            "go"          = ".go"
            "java"        = ".java"
            "javascript"  = ".js"
            "php"         = ".php"
            "python"      = ".py"
            "ruby"        = ".rb"
            "rust"        = ".rs"
            "powershell"  = ".ps1"
            "html"        = ".html"
            "css"         = ".css"
            "xml"         = ".xml"
            "swift"       = ".swift"
            "kotlin"      = ".kt"
            "typescript"  = ".ts"
            "dart"        = ".dart"
            "groovy"      = ".groovy"
            "lua"         = ".lua"
            "scala"       = ".scala"
            "shell"       = ".sh"
            "sql"         = ".sql"
            "yaml"        = ".yaml", ".yml"
            "perl"        = ".pl"
            "r"           = ".r"
            "vb.net"      = ".vb"
            "matlab"      = ".m"
            "f#"          = ".fs"
            "objective-c" = ".m"
            "vbscript"    = ".vbs"
            "batch"       = ".bat"
            "haskell"     = ".hs"
            "visualbasic" = ".vb"
        }
        $Counts = @{}
        foreach ($Lang in $Languages.Keys) {
            if ($Language -ne "all" -and $Lang -ne $Language) {
                continue
            }
            $Counts[$Lang] = ($Files | Where-Object { $_.Extension -in $Languages[$Lang] }).Count
        }
        return $Counts
    }
    catch {
        Write-Error $_.Exception.Message
        return $null
    }
}
