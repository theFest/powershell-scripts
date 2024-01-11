Function Get-EvaluationLinks {
    <#
    .SYNOPSIS
    This function retrieves evaluation download links from various Microsoft pages.

    .DESCRIPTION
    This function scrapes specified Microsoft URLs to find and collect download links for evaluation software, handling inaccessible URLs and sorting the collected data before exporting it to a CSV file.

    .PARAMETER Urls
    Array of URLs from which download links will be collected, defaults to a predefined set of Microsoft evaluation URLs.
    .PARAMETER OutputFile
    Output file path to store the collected download links in CSV format, defaults to the user's desktop folder with a file named "EvalCenterDownloads.csv".
    .PARAMETER ProgressPreference
    Determines the preference for displaying progress, defaults to "SilentlyContinue".

    .EXAMPLE
    Get-EvaluationLinks

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$Urls,

        [Parameter(Mandatory = $false)]
        [string]$OutputFile = "$env:USERPROFILE\Desktop\EvalCenterDownloads.csv",

        [Parameter(Mandatory = $false)]
        [string]$ProgressPreference = "SilentlyContinue"
    )
    BEGIN {
        $TotalCount = 0
        $TotalFound = @()
        $DownloadLinks = @(
            'https://www.microsoft.com/en-us/evalcenter/download-biztalk-server-2016',
            'https://www.microsoft.com/en-us/evalcenter/download-host-integration-server-2020',
            'https://www.microsoft.com/en-us/evalcenter/download-hyper-v-server-2016',
            'https://www.microsoft.com/en-us/evalcenter/download-hyper-v-server-2019',
            'https://www.microsoft.com/en-us/evalcenter/download-lab-kit',
            'https://www.microsoft.com/en-us/evalcenter/download-mem-evaluation-lab-kit',
            'https://www.microsoft.com/en-us/evalcenter/download-microsoft-endpoint-configuration-manager',
            'https://www.microsoft.com/en-us/evalcenter/download-microsoft-endpoint-configuration-manager-technical-preview',
            'https://www.microsoft.com/en-us/evalcenter/download-microsoft-identity-manager-2016',
            'https://www.microsoft.com/en-us/evalcenter/download-sharepoint-server-2013',
            'https://www.microsoft.com/en-us/evalcenter/download-sharepoint-server-2016',
            'https://www.microsoft.com/en-us/evalcenter/download-sharepoint-server-2019',
            'https://www.microsoft.com/en-us/evalcenter/download-skype-business-server-2019',
            'https://www.microsoft.com/en-us/evalcenter/download-sql-server-2016',
            'https://www.microsoft.com/en-us/evalcenter/download-sql-server-2017-rtm',
            'https://www.microsoft.com/en-us/evalcenter/download-sql-server-2019',
            'https://www.microsoft.com/en-us/evalcenter/download-system-center-2019',
            'https://www.microsoft.com/en-us/evalcenter/download-system-center-2022',
            'https://www.microsoft.com/en-us/evalcenter/download-windows-10-enterprise',
            'https://www.microsoft.com/en-us/evalcenter/download-windows-11-enterprise',
            'https://www.microsoft.com/en-us/evalcenter/download-windows-11-office-365-lab-kit',
            'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2012-r2',
            'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2012-r2-essentials',
            'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2012-r2-essentials',
            'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2016',
            'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2016-essentials',
            'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2019',
            'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2019-essentials',
            'https://www.microsoft.com/en-us/evalcenter/download-windows-server-2022'
        )
    }
    PROCESS {
        foreach ($Url in $DownloadLinks) {
            try {
                $Content = Invoke-WebRequest -Uri $Url -ErrorAction Stop -Verbose
                $DownloadLinks = $content.links | Where-Object { `
                        $_.'aria-label' -match 'Download' `
                        -and $_.outerHTML -match 'fwlink' `
                        -or $_.'aria-label' -match '64-bit edition'
                }    
                $Count = $DownloadLinks.href.Count
                $TotalCount += $Count
                Write-Host ("Processing {0}, Found {1} Download(s)..." -f $Url, $Count) -ForegroundColor Green
                foreach ($DownloadLink in $DownloadLinks) {
                    $DownloadInfo = [PSCustomObject]@{
                        Title  = $Url.split('/')[5].replace('-', ' ').replace('download ', '')
                        Name   = $DownloadLink.'aria-label'.Replace('Download ', '')
                        Tag    = $DownloadLink.'data-bi-tags'.Split('&')[3].split(';')[1]
                        Format = $DownloadLink.'data-bi-tags'.Split('-')[1].ToUpper()
                        Link   = $DownloadLink.href
                    }
                    $TotalFound += $DownloadInfo
                }
            }
            catch {
                Write-Warning -Message ("{0} is not accessible" -f $Url)
            }
        }
    }
    END {
        Write-Host ("Found a total of {0} Downloads" -f $TotalCount) -ForegroundColor Green
        $TotalFound | Sort-Object Title, Name, Tag, Format | Export-Csv -NoTypeInformation -Encoding UTF8 -Delimiter ';' -Path $OutputFile
    }
}
