Function New-GitHubGist {
    <#
    .SYNOPSIS
    Creates a new GitHub Gist.

    .DESCRIPTION
    This function creates a new GitHub Gist either from content provided or by referencing a file.

    .PARAMETER Name
    specifies the name for your gist.
    .PARAMETER Path
    file path to include in the GitHub Gist.
    .PARAMETER Content
    the content to include in the GitHub Gist.
    .PARAMETER Description
    provides a description for your gist.
    .PARAMETER UserToken
    provides a GitHub personal access token.
    .PARAMETER Private
    sets the gist to private, if not specified, the Gist will be public.
    .PARAMETER Passthru
    passes the created gist object through.

    .EXAMPLE
    New-GitHubGist -Name "example_gist" -Content "Sample code 1", "Sample code 2", "Sample code 3" -Description "Sample Gist" -UserToken "ghp_xyz"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(SupportsShouldProcess = $true, DefaultParameterSetName = "Content")]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true, HelpMessage = "Specify the name for your gist")]
        [ValidateNotNullorEmpty()]
        [Alias("n")]
        [string]$Name,
    
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = "Path", HelpMessage = "File path to include in the GitHub Gist")]
        [ValidateNotNullorEmpty()]
        [Alias("p")]
        [string]$Path,
    
        [Parameter(Mandatory = $true, ParameterSetName = "Content", HelpMessage = "Content to include in the GitHub Gist")]
        [ValidateNotNullorEmpty()]
        [Alias("c")]
        [string[]]$Content,
    
        [Parameter(Mandatory = $false, HelpMessage = "Provide a description for your gist")]
        [string]$Description,
    
        [Parameter(Mandatory = $true, HelpMessage = "Provide a GitHub personal access token")]
        [Alias("t")]
        [ValidateNotNullorEmpty()]
        [string]$UserToken,
    
        [Parameter(Mandatory = $false, HelpMessage = "Set the gist to private")]
        [Alias("pr")]
        [switch]$Private,

        [Parameter(Mandatory = $false, HelpMessage = "Pass the created gist object through")]
        [Alias("pt")]
        [switch]$Passthru
    )
    BEGIN {
        $Headers = @{
            Authorization = "Bearer $UserToken"
        }
        $BaseURL = "https://api.github.com/gists"
    }
    PROCESS {
        $GistContent = switch ($PSCmdlet.ParameterSetName) {
            "Path" { 
                Get-Content -Path $Path -Raw -Verbose
            }
            "Content" { 
                $Content -join [Environment]::NewLine 
            }
        }
        $GistData = @{
            files       = @{
                $Name = @{
                    content = $GistContent
                }
            }
            description = $Description
            public      = (-not $Private)
        } | ConvertTo-Json
        Write-Verbose -Message "Posting to $BaseURL..."
        if ($PSCmdlet.ShouldProcess("$Name [$Description]")) {
            $Result = Invoke-RestMethod -Uri $BaseURL -Method Post -Headers $Headers -ContentType "application/vnd.github.v3+json" -Body $GistData
            if ($Passthru) {
                Write-Verbose -Message "Writing the result to the pipeline..."
                $Result | Select-Object @{
                    Name       = "Url"
                    Expression = { $_.html_url }
                }, Description, Public, @{
                    Name       = "Created"
                    Expression = { [datetime]::Parse($_.created_at) }
                }
            } 
        }
    }
    END {
        Clear-Variable -Name "Headers" -Force -Verbose
    }
}
