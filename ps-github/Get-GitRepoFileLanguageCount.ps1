Function Get-GitRepoFileLanguageCount {
    <#
    .SYNOPSIS
    Gets the count of programming language files in a Git repository.

    .DESCRIPTION
    This function retrieves the count of files for specific programming languages in a Git repository, either by specifying a local repository path or a remote repository URL.

    .PARAMETER LocalRepoPath
    Local path of the Git repository, mandatory when using the local repository.
    .PARAMETER RemoteRepoPath
    URL of the remote Git repository, mandatory when using the remote repository.
    .PARAMETER CloneRemoteRepoPath
    Local path where the remote repository will be cloned, default is "$env:TEMP".
    .PARAMETER Language
    Programming language to filter, default is "all". Valid values include "all", "c", "cpp", "csharp", and others.
    .PARAMETER MaxDepth
    Maximum depth for recursive file search, default is [int]::MaxValue.
    .PARAMETER Exclude
    Specifies an array of file patterns to exclude from the analysis.
    .PARAMETER Include
    Specifies an array of file patterns to include in the analysis.
    .PARAMETER RepoClonePath
    Local path where the repository is cloned, default is "$env:TEMP".
    .PARAMETER RedirectStandardOutput
    Path for redirecting standard output, default is "$env:TEMP\GetGitRepoProgLang_strout.txt".
    .PARAMETER RedirectStandardError
    Path for redirecting standard error, default is "$env:TEMP\GetGitRepoProgLang_strerror.txt".
    .PARAMETER Recurse
    Indicates whether to include files from subdirectories recursively.

    .EXAMPLE
    Get-GitRepoFileLanguageCount -RemoteRepoPath "https://github.com/powershell/powershell"
    Get-GitRepoFileLanguageCount -LocalRepoPath "C:\Users\Administrator\Documents\GitHub\powershell-scripts"

    .NOTES
    v0.1.7
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "LocalRepoPath", Position = 0)]
        [ValidateScript({ 
                Test-Path $_ -PathType "Container"
            })]
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
        Write-Error -Message $_.Exception.Message
        return $null
    }
}
