Function Get-WindowsUpdateDriverInfo {
    <#
    .SYNOPSIS
    Retrieves information about available Windows driver updates.

    .DESCRIPTION
    This function connects to Windows Update to search for driver updates that are not currently installed, provides a summary or detailed information about the available updates.
    
    .PARAMETER ShowDetails
    Switch parameter to display detailed information about each driver update.
    
    .EXAMPLE
    Get-WindowsUpdateDriverInfo -ShowDetails
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$ShowDetails
    )
    try {
        $DriverUpdateSession = New-Object -ComObject Microsoft.Update.Session
        $DriverUpdateSearcher = $DriverUpdateSession.CreateUpdateSearcher()
        $DriverUpdates = $DriverUpdateSearcher.Search("IsInstalled=0 AND Type='Driver'")
        if ($DriverUpdates.Updates.Count -eq 0) {
            Write-Host "No driver updates found!" -ForegroundColor DarkCyan
        }
        else {
            Write-Host "Driver updates available:"
            $DriverUpdates.Updates | ForEach-Object {
                if ($ShowDetails) {
                    Write-Host "  Title: $($_.Title)"
                    Write-Host "  Description: $($_.Description)"
                    Write-Host "  Support URL: $($_.SupportUrl)"
                    Write-Host "  Update ID: $($_.Identity.UpdateID)"
                    Write-Host "  --------------------"
                }
                else {
                    Write-Host "  $($_.Title)"
                }
            }
        }
    }
    catch {
        Write-Error -Message "Error: $_"
    }
}
