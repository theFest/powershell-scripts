Function GetGitRepoProgLang {
    <#
    .SYNOPSIS
    Count of programming files by language in a given Git repository.

    .DESCRIPTION
    This function takes a Git repository path and an optional language parameter as input and returns a hashtable containing the count of programming files in the repository filtered by language.

    .PARAMETER RepoPath
    Mandatory - path of the Git repository to search for programming files.
    .PARAMETER Language
    NotMandatory - language for which to count the programming files. If not specified, counts all programming files in the repository.

    .EXAMPLE
    GetGitRepoProgLang -RepoPath "$env:SystemDrive\your_repo_path"

    .NOTES
    v0.1.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$RepoPath,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("all", "c", "cpp", "csharp", "go", "java", "javascript", `
                "php", "python", "ruby", "rust", "powershell", "html", "css", "xml")]
        [string]$Language = "all"
    )
    ## Change the working directory to the Git repository path
    Set-Location $RepoPath
    # Get a list of all the files in the repository
    $Files = Get-ChildItem -Recurse -File
    ## Filter the files by extension and count them
    $Counts = @{
        "c"          = ($Files | Where-Object { $_.Extension -in ".c" }).Count
        "cpp"        = ($Files | Where-Object { $_.Extension -in ".cpp" }).Count
        "csharp"     = ($Files | Where-Object { $_.Extension -in ".cs" }).Count
        "go"         = ($Files | Where-Object { $_.Extension -in ".go" }).Count
        "java"       = ($Files | Where-Object { $_.Extension -in ".java" }).Count
        "javascript" = ($Files | Where-Object { $_.Extension -in ".js" }).Count
        "php"        = ($Files | Where-Object { $_.Extension -in ".php" }).Count
        "python"     = ($Files | Where-Object { $_.Extension -in ".py" }).Count
        "ruby"       = ($Files | Where-Object { $_.Extension -in ".rb" }).Count
        "rust"       = ($Files | Where-Object { $_.Extension -in ".rs" }).Count
        "powershell" = ($Files | Where-Object { $_.Extension -in ".ps1" }).Count
        "html"       = ($Files | Where-Object { $_.Extension -in ".html" }).Count
        "css"        = ($Files | Where-Object { $_.Extension -in ".css" }).Count
        "xml"        = ($Files | Where-Object { $_.Extension -in ".xml" }).Count
    }
    ## Filtering counts by the specified language parameter
    if ($Language -ne "all") {
        $Counts = @{
            $Language = $Counts[$Language]
        }
    }
    ## Return the counts
    return $Counts
}
