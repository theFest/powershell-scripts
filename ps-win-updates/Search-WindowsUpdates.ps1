Function Search-WindowsUpdates {
    <#
    .SYNOPSIS
    Searches for Windows updates based on a specified keyword in the update descriptions.

    .DESCRIPTION
    This function retrieves a list of installed hotfixes (Windows updates) using the Get-HotFix cmdlet, it then filters the updates based on the provided keyword in their descriptions.

    .PARAMETER Keyword
    Specifies the keyword to search for in the update descriptions.

    .EXAMPLE
    Search-WindowsUpdates -Keyword "Security"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Keyword
    )
    if (-not (Get-Command Get-HotFix -ErrorAction SilentlyContinue)) {
        Write-Host "Get-HotFix cmdlet is not available on this system. Please ensure you are running this on a Windows system!"
        return
    }
    $Updates = Get-HotFix | Where-Object { $_.Description -like "*$Keyword*" }
    if ($Updates.Count -eq 0) {
        Write-Host "No updates found matching the keyword '$Keyword'!" -ForegroundColor Yellow
    }
    else {
        Write-Host "Updates matching the keyword '$Keyword':" -ForegroundColor DarkCyan
        $Updates | Format-Table -Property HotFixID, Description, InstalledOn -AutoSize
    }
}
