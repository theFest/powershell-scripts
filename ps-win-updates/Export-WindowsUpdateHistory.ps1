Function Export-WindowsUpdateHistory {
    <#
    .SYNOPSIS
    Exports Windows Update history to a CSV file.

    .DESCRIPTION
    This function retrieves information about installed updates using the Get-HotFix cmdlet and exports the data to a CSV file, exported file includes details such as HotFixID, Description, and InstalledOn.

    .PARAMETER OutputPath
    Path where the CSV file will be saved. If not provided, the file will be saved on the user's desktop with the default name "win_update_history.csv".
    .PARAMETER NumberOfEntries
    Specifies the number of update entries to include in the exported history, defaults to 100 if not specified.

    .EXAMPLE
    Export-WindowsUpdateHistory

    .NOTES
    v0.0.1
    #>
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$OutputPath = "$env:USERPROFILE\Desktop\win_update_history.csv",

        [Parameter(Mandatory = $false, Position = 1)]
        [int]$NumberOfEntries = 100
    )
    try {
        $UpdateHistory = Get-HotFix | Select-Object -First $NumberOfEntries
        if ($null -eq $UpdateHistory) {
            throw "Failed to query update history, no data available!"
        }
        $UpdateHistory | Export-Csv -Path $OutputPath -NoTypeInformation
        Write-Host "WU history exported to $OutputPath" -ForegroundColor Cyan
    }
    catch {
        Write-Error -Message "Error: $_"
    }
}
