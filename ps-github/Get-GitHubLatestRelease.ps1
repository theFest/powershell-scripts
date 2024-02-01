Function Get-GitHubLatestRelease {
    <#
    .SYNOPSIS
    Downloads the latest release file from a GitHub repository.

    .DESCRIPTION
    This function retrieves information about the latest release of a GitHub repository, allowing users to download specific files based on search criteria.

    .PARAMETER SearchType
    Type of search to perform, use "Exact" for an exact match search or "Pattern" for a pattern match search.
    .PARAMETER Owner
    Specifies the GitHub repository owner.
    .PARAMETER Repository
    Specifies the name of the GitHub repository.
    .PARAMETER SearchString
    String to search for in the GitHub release files.
    .PARAMETER FileNamePattern
    Pattern to filter files when using "Pattern" search type.
    .PARAMETER OutputPath
    Directory where the downloaded file will be saved. The default is the user's temporary directory.

    .EXAMPLE
    Get-GitHubLatestRelease -SearchType Exact -Owner "microsoft" -Repository "nubesgen" -SearchString "nubesgen-cli-windows.exe"
    Get-GitHubLatestRelease -SearchType Pattern -Owner "microsoft" -Repository "terminal" -SearchString "terminal" -FileNamePattern *.zip -OutputPath "$env:USERPROFILE\Desktop"

    .NOTES
    v0.1.3
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("Exact", "Pattern")]
        [string]$SearchType,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Owner,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Repository,

        [Parameter(Mandatory = $true, Position = 3)]
        [string]$SearchString,

        [Parameter(Mandatory = $false)]
        [ValidateSet("*.msi", "*.exe", "*.zip", "*.tar.gz", "*.xml", "*.msixbundle", "*.*")]
        [string]$FileNamePattern,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "$env:TEMP"
    )
    BEGIN {
        $ErrorActionPreference = "Stop"
        try {
            $ApiUrl = "https://api.github.com/repos/$Owner/$Repository/releases/latest"
            $ResponseContent = (Invoke-WebRequest -Uri $ApiUrl -Verbose).Content
            Write-Information -MessageData $ResponseContent
            Write-Host "INFO: Connection to GitHub established...." -ForegroundColor Green
        }
        catch [System.Net.WebException] {
            Write-Error -Message $_.Exception.Message
        }
        catch [System.UriFormatException] {
            Write-Error -Message $_.Exception.Message
        }
        catch {
            Write-Error -Message $_.Exception.Message
        }
    }
    PROCESS {
        if ($OutputPath) {
            $LatestRelease = (Invoke-WebRequest -Uri $ApiUrl -Verbose | ConvertFrom-Json).Assets
            $SelectedRelease = $LatestRelease | Select-Object *
            $DownloadUrls = $SelectedRelease.Browser_Download_Url
            $SelectedUrl = ($DownloadUrls | Select-String -SimpleMatch $SearchString).Line
            switch ($SearchType) {
                "Exact" {
                    $FileName = Split-Path -Path $SelectedUrl -Leaf
                    $LatestUrl = (([uri]$SelectedUrl).OriginalString) | Sort-Object -Property published_at -Descending | Select-Object -First 1
                    Invoke-WebRequest -Uri $LatestUrl -OutFile "$OutputPath\$FileName" -Verbose
                }
                "Pattern" {
                    $SelectedPattern = $SelectedRelease | Sort-Object -Property published_at -Descending | Where-Object { $_.Name -like $FileNamePattern } | Select-Object -First 1
                    $FileName = $selectedPattern.Name
                    $LatestUrl = $selectedPattern.Browser_Download_Url
                    Invoke-WebRequest -Uri $LatestUrl -OutFile "$OutputPath\$FileName" -Verbose
                }
                default { 
                    Write-Warning -Message "Incorrect choice, Exact or Pattern should be picked!" 
                }
            }
        }
    }
    END {
        $DownloadPath = "$OutputPath\$FileName"
        if (Test-Path -Path $DownloadPath) {
            Write-Host "Downloaded successfully, verifying downloaded content..." -ForegroundColor DarkGreen
        }
        else {
            Write-Error -Message "Download failed!"
        }
        $LocalSize = (Get-Item $DownloadPath).Length
        $RemoteSize = (Invoke-WebRequest -Uri $LatestUrl -UseBasicParsing -Method Head -WarningAction SilentlyContinue).Headers.'Content-Length'
        $SizeCheck = [System.IO.File]::Exists($DownloadPath) -and $LocalSize -eq $RemoteSize
        if ($SizeCheck) {
            Write-Host "Download ended with success, local matches remote content" -ForegroundColor Green
        }
        else {
            Write-Error -Message "Verification of downloaded content has failed!"
        }
    }
}
