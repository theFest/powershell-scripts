Function Get-MissingUpdates {
    <#
    .SYNOPSIS
    Retrieves information about Windows updates.

    .DESCRIPTION
    This function retrieves information about Windows updates, including the count of updates and their details. By default, it displays all available updates, use optional parameters to filter and customize the output.

    .PARAMETER ShowPendingOnly
    If specified, only pending updates will be displayed.
    .PARAMETER ShowCount
    If specified, the count of available updates will be displayed.

    .EXAMPLE
    Get-MissingUpdates

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$ShowPendingOnly,

        [Parameter(Mandatory = $false)]
        [switch]$ShowCount
    )
    $UpdateSession = New-Object -ComObject Microsoft.Update.Session
    $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
    $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
    if ($SearchResult.Updates.Count -eq 0) {
        Write-Host "No updates found!" -ForegroundColor DarkGreen
    }
    else {
        if ($ShowCount) {
            Write-Host "$($SearchResult.Updates.Count) updates available..." -ForegroundColor DarkCyan
        }
        $SearchResult.Updates | ForEach-Object {
            if ($ShowPendingOnly) {
                Write-Host "$($_.Title)" -ForegroundColor DarkGray
            }
            else {
                Write-Host "$($_.Title) - $($($_.Date) -as [datetime])" -ForegroundColor Gray
            }
        }
    }
}
