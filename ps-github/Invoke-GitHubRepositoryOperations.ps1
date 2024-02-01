Function Invoke-GitHubRepositoryOperations {
    <#
    .SYNOPSIS
    Function for managing GitHub repositories by utilizing GitHub API to interact with the repositories via Personal Access Token.

    .DESCRIPTION
    This function that allows you to perform various actions on GitHub repositories, such as creating, deleting, archiving, and unarchiving repositories.

    .PARAMETER Action
    Action to perform on the GitHub repository, valid values are "Create", "Delete", "Archive", "Unarchive", and "List".
    .PARAMETER Visibility
    Visibility of the GitHub repository, valid values are "public", "private", or "internal". Default is "public".
    .PARAMETER AccountType
    Type of GitHub account, valid values are "user", "organization", or "enterprise".
    .PARAMETER AccountName
    Name of the GitHub account associated with the repository.
    .PARAMETER RepositoryName
    Specifies the name of the GitHub repository to be created or operated on.
    .PARAMETER AccessToken
    The GitHub access token to authenticate API requests, if not provided, the function will prompt for it.
    .PARAMETER DefaultBranch
    Default branch for the GitHub repository, valid values are "main", "master", "dev", "test", "stage", or "prod".
    .PARAMETER RepositoryId
    Specifies the ID of the GitHub repository to be operated on.
    .PARAMETER Private
    If specified, the GitHub repository will be private, this parameter is applicable only for the "Create" action.
    .PARAMETER Description
    Specifies the description of the GitHub repository.
    .PARAMETER Homepage
    Specifies the URL of the homepage for the GitHub repository.
    .PARAMETER GitIgnoreTemplate
    Specifies the template for .gitignore file to be used in the GitHub repository.
    .PARAMETER LicenseTemplate
    Specifies the license template to be used for the GitHub repository.
    .PARAMETER TeamId
    ID of the team that will be granted access to the GitHub repository, this parameter is applicable only for the "Create" action.
    .PARAMETER AutoInit
    GitHub repository will be auto-initialized with a README file, this parameter is applicable only for the "Create" action.
    .PARAMETER Issues
    GitHub repository will have issue tracking enabled, this parameter is applicable only for the "Create" action.
    .PARAMETER Pages
    GitHub repository will have GitHub Pages enabled, this parameter is applicable only for the "Create" action.
    .PARAMETER Projects
    GitHub repository will have GitHub Projects enabled, this parameter is applicable only for the "Create" action.
    .PARAMETER Discussions
    GitHub repository will have GitHub Discussions enabled, this parameter is applicable only for the "Create" action.
    .PARAMETER Codespaces
    GitHub repository will have Codespaces enabled, this parameter is applicable only for the "Create" action.
    .PARAMETER MirrorURL
    URL of a mirror repository to be used for the GitHub repository, this parameter is applicable only for the "Create" action.
    .PARAMETER Sponsorship
    If specified, the GitHub repository will be open for sponsorship, this parameter is applicable only for the "Create" action.
    .PARAMETER TopicTags
    If specified, the GitHub repository will support topic tags, this parameter is applicable only for the "Create" action.
    .PARAMETER UpdateBranch
    Default branch of the GitHub repository will be updated to the specified branch, this parameter is applicable only for the "Create" action.
    .PARAMETER SquashMerge
    Squash merging will be allowed in the GitHub repository, this parameter is applicable only for the "Create" action.
    .PARAMETER MergeCommit
    Merge commits will be allowed in the GitHub repository, this parameter is applicable only for the "Create" action.
    .PARAMETER Language
    The primary programming language used in the GitHub repository.
    .PARAMETER RebaseMerge
    If specified, rebase merging will be allowed in the GitHub repository, this parameter is applicable only for the "Create" action.
    .PARAMETER DeleteBranchOnMerge
    The source branch will be deleted after merging a pull request, this parameter is applicable only for the "Create" action.
    .PARAMETER IsTemplate
    GitHub repository will be marked as a template repository, this parameter is applicable only for the "Create" action.

    .EXAMPLE
    Invoke-GitHubRepositoryOperations -Action Create -AccountType user -AccountName "your_Github_user" -RepositoryName "your_repo" -AccessToken "ghp_xyz" -Visibility public -DefaultBranch master `
        -Description "some_description" -Sponsorship -Homepage "https://github.com/theFest/your_homepage" -Language Java -AutoInit -Discussions -Projects -Codespaces -Issues `
        -RebaseMerge -DeleteBranchOnMerge -GitIgnoreTemplate Java -LicenseTemplate mit -TopicTags -Pages -MirrorURL "https://github.com/your_mirror_url" -UpdateBranch -IsTemplate
    Invoke-GitHubRepositoryOperations -Action Archive -AccountType user -AccountName "your_Github_user" -RepositoryName "your_repo" -AccessToken "ghp_xyz" -Verbose
    Invoke-GitHubRepositoryOperations -Action Unarchive -AccountType user -AccountName "your_Github_user" -RepositoryName "your_repo" -AccessToken "ghp_xyz" -Verbose
    Invoke-GitHubRepositoryOperations -Action List -AccountType user -AccountName "your_Github_user" -AccessToken "ghp_xyz" -Verbose  
    Invoke-GitHubRepositoryOperations -Action Delete -AccountType user -AccountName "your_Github_user" -RepositoryName "your_repo" -AccessToken "ghp_xyz"

    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateSet("Create", "Delete", "Archive", "Unarchive", "List")]
        [string]$Action,
    
        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateSet("public", "private", "internal")]
        [string]$Visibility,
    
        [Parameter(Mandatory = $true)]
        [ValidateSet("user", "organization", "enterprise")]
        [ValidatePattern("^.{0,39}$")]
        [string]$AccountType,
    
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(3, 39)]
        [string]$AccountName,
    
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateLength(3, 255)]
        [string]$RepositoryName,
    
        [Parameter(Mandatory = $false)]
        [string]$AccessToken,

        [Parameter(Mandatory = $false)]
        [ValidateSet("main", "master", "dev", "test", "stage", "prod")]
        [string]$DefaultBranch,

        [Parameter(Mandatory = $false)]
        [string]$RepositoryId,
    
        [Parameter(Mandatory = $false)]
        [switch]$Private,
    
        [Parameter(Mandatory = $false)]
        [ValidateLength(3, 255)]
        [string]$Description,
    
        [Parameter(Mandatory = $false)]
        [uri]$Homepage,
    
        [Parameter(Mandatory = $false)]
        [ValidateSet("Actionscript", "Ada", "Agda", "Rust", "Python", "Java", "C++", "TypeScript", "JavaScript")]
        [string]$GitIgnoreTemplate,
    
        [Parameter(Mandatory = $false)]
        [ValidateSet("mit", "gpl-3.0", "bsd-2-clause", "bsd-3-clause", "apache-2.0", "mpl-2.0")]
        [string]$LicenseTemplate,
    
        [Parameter(Mandatory = $false)]
        [string]$TeamId,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoInit,
        
        [Parameter(Mandatory = $false)]
        [switch]$Issues,

        [Parameter(Mandatory = $false)]
        [switch]$Pages,
        
        [Parameter(Mandatory = $false)]
        [switch]$Projects,
        
        [Parameter(Mandatory = $false)]
        [switch]$Discussions,
        
        [Parameter(Mandatory = $false)]
        [switch]$Codespaces,
                
        [Parameter(Mandatory = $false)]
        [uri]$MirrorURL,

        [Parameter(Mandatory = $false)]
        [switch]$Sponsorship,
        
        [Parameter(Mandatory = $false)]
        [switch]$TopicTags,

        [Parameter(Mandatory = $false)]
        [switch]$UpdateBranch,
        
        [Parameter(Mandatory = $false)]
        [switch]$SquashMerge,
        
        [Parameter(Mandatory = $false)]
        [switch]$MergeCommit,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Actionscript", "Ada", "Agda", "Rust", "Python", "Java", "C++", "TypeScript", "JavaScript")]
        [string]$Language,

        [Parameter(Mandatory = $false)]
        [switch]$RebaseMerge,
        
        [Parameter(Mandatory = $false)]
        [switch]$DeleteBranchOnMerge,
        
        [Parameter(Mandatory = $false)]
        [switch]$IsTemplate
    )
    DynamicParam {
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        if ($Visibility -eq "private") {
            return $RuntimeParameterDictionary
        }
        else {
            $EnvironmentsAttribute = New-Object System.Management.Automation.ParameterAttribute
            $Environmentsattribute.Mandatory = $false
            $Environmentsattribute.ParameterSetName = "public"
            $Environmentsparameter = New-Object System.Management.Automation.RuntimeDefinedParameter("Environments", [switch], $Environmentsattribute)
            $RuntimeParameterDictionary.Add("Environments", $Environmentsparameter)
            $Wikiattribute = New-Object System.Management.Automation.ParameterAttribute
            $Wikiattribute.Mandatory = $false
            $Wikiattribute.ParameterSetName = "public"
            $Wikiparameter = New-Object System.Management.Automation.RuntimeDefinedParameter("Wiki", [switch], $Wikiattribute)
            $RuntimeParameterDictionary.Add("Wiki", $Wikiparameter)
            return $RuntimeParameterDictionary
        }
    }
    BEGIN {       
        if (-not $AccessToken) {
            $AccessToken = Read-Host -Prompt "Please enter your GitHub access token!"
        }
        if ([string]::IsNullOrEmpty($AccessToken)) {
            throw "Access token is null or empty!"
        }
        try {
            Invoke-RestMethod -Uri "https://api.github.com" -Method GET -Headers @{Authorization = "Token $AccessToken" } -ErrorAction Stop
        }
        catch {
            throw "Invalid access token"
        } 
        switch ($AccountType) {
            "user" {
                $Uri = "https://api.github.com/user/repos"
            }
            "organization" {
                try {
                    Invoke-RestMethod -Uri "https://api.github.com/orgs/$AccountName" -Method GET -Headers @{Authorization = "Token $AccessToken" } -ErrorAction Stop
                    $Uri = "https://api.github.com/orgs/$AccountName/repos"
                }
                catch {
                    throw "Invalid organization name '$AccountName'"
                }
            }
            "enterprise" {
                try {
                    Invoke-RestMethod -Uri "https://api.github.com/enterprise/$AccountName/repos" -Method GET -Headers @{Authorization = "Token $AccessToken" } -ErrorAction Stop
                    $Uri = "https://api.github.com/enterprise/$AccountName/repos"
                }
                catch {
                    throw "Invalid enterprise name '$AccountName'"
                }
            }
        }
    }
    PROCESS {
        switch ($Action) {
            "Create" {
                try {
                    $RepoExistsUri = "https://api.github.com/repos/$AccountName/$RepositoryName"
                    Invoke-RestMethod -Uri $RepoExistsUri -Method GET -Headers @{Authorization = "Token $AccessToken" } -ErrorAction Stop
                    throw "Repository with the name '$RepositoryName' already exists in the $AccountType '$AccountName'"
                }
                catch {
                    if ($_.Exception.Response.StatusCode -eq 404) {
                        Write-Verbose -Message "Repository does not exist. Proceeding with creation..."
                    }
                    else {
                        $ErrorMessage = $_.Exception.Message
                        $ErrorDetails = $_.Exception.Response.Content
                        Write-Error -Message "Error checking repository existence:`n$ErrorMessage`nDetails:`n$ErrorDetails"
                        throw "An unexpected error occurred while checking repository existence."
                    }
                }
                if ($GitIgnoreTemplate) {
                    try {
                        Invoke-RestMethod -Uri "https://api.github.com/gitignore/templates/$GitIgnoreTemplate" -Method GET -Headers @{Authorization = "Token $AccessToken" } -ErrorAction Stop
                    }
                    catch {
                        Throw "Invalid gitignore template '$GitIgnoreTemplate'"
                    }
                }
                if ($LicenseTemplate) {
                    try {
                        Invoke-RestMethod -Uri "https://api.github.com/licenses/$LicenseTemplate" -Method GET -Headers @{Authorization = "Token $AccessToken" } -ErrorAction Stop
                    }
                    catch {
                        throw "Invalid license template '$LicenseTemplate'"
                    }
                }
                $Repos | Select-Object name, language             
                $Body = @{
                    "name"                   = $RepositoryName
                    "description"            = $Description
                    "homepage"               = $Homepage
                    "visibility"             = if ($Private) { 'private' } else { $Visibility }
                    "has_issues"             = $Issues
                    "has_projects"           = $Projects
                    "has_discussions"        = $Discussions
                    "has_codespaces"         = $Codespaces
                    "has_topic_tags"         = $TopicTags
                    "has_environments"       = $Environments
                    "mirror_url"             = if ($MirrorURL) { $_ } else { $MirrorURL = "" }
                    "allow_squash_merge"     = if ($MergeCommit) { $true } else { $false }
                    "allow_merge_commit"     = if ($MergeCommit) { $true } else { $false }
                    "allow_rebase_merge"     = if ($RebaseMerge) { $true } else { $false }
                    "allow_update_branch"    = if ($UpdateBranch) { $true } else { $false }
                    "delete_branch_on_merge" = $DeleteBranchOnMerge
                    "is_template"            = if ($IsTemplate) { $true } else { $false }
                }
                if ($Description) {
                    $Body["description"] = $Description
                }
                if ($AutoInit) {
                    $Body["auto_init"] = $AutoInit
                }
                if ($Pages) {
                    $Body["has_pages"] = $Pages
                }
                if ($GitIgnoreTemplate) {
                    $Body["gitignore_template"] = $GitIgnoreTemplate
                }
                if ($LicenseTemplate) {
                    $Body["license_template"] = $LicenseTemplate
                }
                if ($Language) {
                    $Body["language"] = $Language
                }
                if ($TeamId) {
                    $Body["team_id"] = $TeamId
                }
                if ($Sponsorship) {
                    $Body["sponsorship"] = $Sponsorship
                }
                if ($Visibility -eq "private") {
                    $Private = $true
                }
                else { 
                    $Private = $false
                }
                if ($Private) {
                    $Body.Add("private", $Private)
                }   
                $Create = Invoke-RestMethod -Uri $Uri -Method POST -Verbose -Headers @{Authorization = "Token $AccessToken" } -ContentType "application/json" -Body (ConvertTo-Json $Body) -ErrorAction Stop
                Write-Output -InputObject $Create
                Write-Host "Repository '$RepositoryName' created successfully!" -ForegroundColor Green
                if ($DefaultBranch -ne "main") {
                    $DefaultBranchUri = "https://api.github.com/repos/$AccountName/$RepositoryName/git/refs/heads/main"
                    $DefaultBranchRef = Invoke-RestMethod -Uri $defaultBranchUri -Method Get -Headers @{Authorization = "Token $AccessToken" } -ErrorAction Stop
                    $DefaultBranchSha = $DefaultBranchRef.object.sha
                    $Branch = @{
                        "ref" = "refs/heads/$DefaultBranch"
                        "sha" = $DefaultBranchSha
                    }
                    Invoke-RestMethod -Uri "https://api.github.com/repos/$AccountName/$RepositoryName/git/refs" -Method Post -Headers @{Authorization = "Token $AccessToken" } -ContentType "application/json" -Body (ConvertTo-Json $Branch) -ErrorAction Stop
                    Write-Host "Default branch '$DefaultBranch' created successfully!" -ForegroundColor Green
                    $UpdateRepoUri = "https://api.github.com/repos/$AccountName/$RepositoryName"
                    $UpdateBody = @{
                        "default_branch" = $DefaultBranch
                    }
                    Invoke-RestMethod -Uri $UpdateRepoUri -Method Patch -Headers @{Authorization = "Token $AccessToken" } -ContentType "application/json" -Body (ConvertTo-Json $UpdateBody) -ErrorAction Stop
                    Write-Host "Default branch '$DefaultBranch' set successfully!" -ForegroundColor Green
                }
            }
            "Delete" {
                if ($RepositoryName) {
                    $Delete = Invoke-RestMethod -Uri "https://api.github.com/repos/$AccountName/$RepositoryName" -Method DELETE -Headers @{Authorization = "Token $AccessToken" } -ErrorAction Stop
                    Write-Host "Repository '$RepositoryName' deleted successfully!" -ForegroundColor Green
                }
                elseif ($RepositoryId) {
                    $Delete = Invoke-RestMethod -Uri "https://api.github.com/repositories/$RepositoryId" -Method DELETE -Headers @{Authorization = "Token $AccessToken" } -ErrorAction Stop
                    Write-Host "Repository with id '$RepositoryId' deleted successfully!" -ForegroundColor Green
                }
                else {
                    throw "Repository name or id not specified"
                }
            }
            "Archive" {
                try {
                    if ($RepositoryName) {
                        $ArchiveUri = "https://api.github.com/repos/$AccountName/$RepositoryName"
                        $Body = @{
                            "name"     = $RepositoryName
                            "archived" = $true
                        }
                        $Archive = Invoke-RestMethod -Uri $ArchiveUri -Method PATCH -Headers @{Authorization = "Token $AccessToken" } -ContentType "application/json" -Body (ConvertTo-Json $Body) -ErrorAction Stop
                        Write-Host "Repository '$RepositoryName' archived successfully!" -ForegroundColor Green
                    }
                    elseif ($RepositoryId) {
                        $ArchiveUri = "https://api.github.com/repositories/$RepositoryId"
                        $Body = @{
                            "archived" = $true
                        }
                        $Archive = Invoke-RestMethod -Uri $ArchiveUri -Method PATCH -Headers @{Authorization = "Token $AccessToken" } -ContentType "application/json" -Body (ConvertTo-Json $Body) -ErrorAction Stop
                        Write-Host "Repository with id '$RepositoryId' archived successfully!" -ForegroundColor Green
                    }
                    else {
                        throw "Repository name or id not specified"
                    }
                }
                catch {
                    Write-Error -Message "Error archiving repository: $($_.Exception.Message)"
                    Write-Error -Message "Status Code: $($_.Exception.Response.StatusCode)"
                    Write-Error -Message "Response Content: $($_.Exception.Response.Content)"
                }
            }
            "Unarchive" {
                try {
                    if ($RepositoryName) {
                        $UnarchiveUri = "https://api.github.com/repos/$AccountName/$RepositoryName"
                        $Body = @{
                            "name"     = $RepositoryName
                            "archived" = $false
                        }
                        $Unarchive = Invoke-RestMethod -Uri $UnarchiveUri -Method PATCH -Headers @{Authorization = "Token $AccessToken" } -ContentType "application/json" -Body (ConvertTo-Json $Body) -ErrorAction Stop
                        Write-Host "Repository '$RepositoryName' unarchived successfully!" -ForegroundColor Green
                    }
                    elseif ($RepositoryId) {
                        $UnarchiveUri = "https://api.github.com/repositories/$RepositoryId"
                        $Body = @{
                            "archived" = $false
                        }
                        $Unarchive = Invoke-RestMethod -Uri $UnarchiveUri -Method PATCH -Headers @{Authorization = "Token $AccessToken" } -ContentType "application/json" -Body (ConvertTo-Json $Body) -ErrorAction Stop
                        Write-Host "Repository with id '$RepositoryId' unarchived successfully!" -ForegroundColor Green
                    }
                    else {
                        throw "Repository name or id not specified"
                    }
                }
                catch {
                    $ErrorResponse = $_.Exception.Response
                    Write-Error -Message "Error unarchiving repository: $($_.Exception.Message)"
                    if ($null -ne $ErrorResponse) {
                        Write-Error -Message "Status Code: $($ErrorResponse.StatusCode)"
                        Write-Error -Message "Response Content: $($ErrorResponse.Content)"
                    }
                    else {
                        Write-Error -Message "Error details: Unable to retrieve response content."
                    }
                }
            }
            "List" {
                if ($AccountType -eq "user") {
                    $List = Invoke-RestMethod -Uri "https://api.github.com/user/repos?affiliation=owner" -Method GET -Headers @{Authorization = "Token $AccessToken" } -ErrorAction Stop
                }
                else {
                    $List = Invoke-RestMethod -Uri "https://api.github.com/$AccountType/$AccountName/repos?affiliation=owner" -Method GET -Headers @{Authorization = "Token $AccessToken" } -ErrorAction Stop
                }
                $List | Select-Object name, full_name, html_url | Format-Table
            }
            default {
                throw "Invalid action: $Action"
            }
        }
    }
    END {   
        switch ($ActionResult) {
            ($Action -eq "Create") { return $Create }
            ($Action -eq "Delete") { Write-Output -InputObject $Delete }
            ($Action -eq "Archive") { Write-Output -InputObject $Archive }
            ($Action -eq "Unarchive") { Write-Output -InputObject $Unarchive }
            ($Action -eq "List") { Write-Output -InputObject $List }
        }
        Write-Verbose -Message "Cleaning up and exiting..."
        Clear-History -Verbose -ErrorAction SilentlyContinue
        Clear-Variable -Name AccountName, RepositoryName, AccessToken, Homepage, MirrorURL -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
        Remove-Variable -Name AccountName, RepositoryName, AccessToken, Homepage, MirrorURL -Scope Global -Force -Verbose -ErrorAction SilentlyContinue
    }
}
