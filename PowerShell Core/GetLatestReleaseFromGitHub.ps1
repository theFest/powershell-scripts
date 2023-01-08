Function GetLatestReleaseFromGitHub {
    <#
    .SYNOPSIS
    Download latest SW release from GitHub.

    .DESCRIPTION
    Simple function that downloads latest software/code release from GitHub API's.

    .PARAMETER SearchType
    Mandatory - choose type of download, combine FileNamePattern with SearchString.
    .PARAMETER Owner
    Mandatory - enter owner of GitHub's repository name.
    .PARAMETER Repository
    Mandatory - enter GitHub repository name from owners.
    .PARAMETER SearchString
    Mandatory - software or code release that you want to download from GitHub.
    .PARAMETER FileNamePattern
    NotMandatory - mandatory when using pattern based search type to download. 
    .PARAMETER OutPath
    NotMandatory - leave empty and or choose a path where content will be downloaded.

    .EXAMPLE
    GetLatestReleaseFromGitHub -SearchType Exact -Owner "microsoft" -Repository "nubesgen" -SearchString "nubesgen-cli-windows.exe"
    GetLatestReleaseFromGitHub -SearchType Pattern -Owner "microsoft" -Repository "terminal" -SearchString "terminal" -FileNamePattern *.zip -OutPath "$env:USERPROFILE\Desktop"

    .NOTES
    v1
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
        [string]$OutPath = "$env:TEMP"
    )
    BEGIN {
        $ErrorActionPreference = "Stop"
        try {
            if ($Response = (Invoke-WebRequest -Uri "https://api.github.com/repos/$Owner/$Repository/releases/latest" -Verbose).Content) {
                Write-Information -MessageData $Response
                Write-Host "INFO: Connection to GitHub established...." -ForegroundColor Green
            }
        }
        catch [System.Net.WebException] {
            $ErrorMessage = $_.Exception.Message
            Write-Error -Message "A web exception occurred: $ErrorMessage"
        }
        catch [System.UriFormatException] {
            $ErrorMessage = $_.Exception.Message
            Write-Error -Message "A URI format exception occurred: $ErrorMessage"
        }
        catch {
            $ErrorMessage = $_.Exception.Message
            Write-Error -Message "An unknown exception occurred: $ErrorMessage"
        }
    }
    PROCESS {
        if ($OutPath) {
            $Release = ((Invoke-WebRequest -Uri "https://api.github.com/repos/$Owner/$Repository/releases/latest" -Verbose | ConvertFrom-Json).Assets)
            $ReleaseSel = ($Release | Select-Object *)
            $ReleaseSelBD = ($Release | Select-Object *).Browser_Download_Url
            $ReleaseSelPat = ($ReleaseSelBD | Select-String -SimpleMatch $SearchString).Line
            switch ($SearchType) {
                "Exact" {  
                    $PatN = Split-Path -Path $ReleaseSelPat -Leaf
                    $LatestPatUrl = (([uri]$ReleaseSelPat).OriginalString) | Sort-Object -Property published_at -Descending | Select-Object -First 1
                    Invoke-WebRequest -Uri $LatestPatUrl -OutFile "$OutPath\$PatN" -Verbose
                }
                "Pattern" {           
                    $PtPat = $ReleaseSel | Sort-Object -Property published_at -Descending | Where-Object { $_.Name -like $FileNamePattern } | Select-Object -First 1
                    $PatN = $PtPat.Name
                    $LatestPatUrl = $PtPat.Browser_Download_Url
                    Invoke-WebRequest -Uri $LatestPatUrl -OutFile "$OutPath\$PatN" -Verbose
                }
                default { Write-Host "Default" }
            }
        }
    }
    END {
        if (Test-Path -Path "$OutPath\$PatN") {
            Write-Host "INFO: Downloaded successfully, verifying downloaded content..." -ForegroundColor DarkGreen
        }
        else {
            Write-Host "ERROR: Downloaded failed!" -ForegroundColor DarkMagenta
        }
        $LocalPath = (Get-Item "$OutPath\$PatN").Length
        $RemotePath = (Invoke-WebRequest -Uri $LatestPatUrl -UseBasicParsing -Method Head -WarningAction SilentlyContinue).Headers.'Content-Length'
        $LRCheck = [System.IO.File]::Exists("$OutPath\$PatN") -and $LocalPath -eq $RemotePath
        if ($LRCheck) {
            Write-Host "INFO: Download ended with success, local matches remote content." -ForegroundColor Green
        }
        else {
            Write-Host "ERROR: Verification of downloaded content has failed!" -ForegroundColor Magenta
        }
    }
}