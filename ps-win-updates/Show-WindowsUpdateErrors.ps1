Function Show-WindowsUpdateErrors {
    <#
    .SYNOPSIS
    Retrieves and displays Windows Update errors from specified event log.

    .DESCRIPTION
    This function retrieves and displays Windows Update errors from the specified event log.

    .PARAMETER LogName
    Name of the event log to search for Windows Update errors, valid values are "System," "Application," or "Security.", default is "System."

    .EXAMPLE
    Show-WindowsUpdateErrors

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("System", "Application", "Security")]
        [string]$LogName = "System"
    )
    $FilterXPath = "*[System[Provider[@Name='Microsoft-Windows-WindowsUpdateClient']]]"
    $ErrorLog = Get-WinEvent -LogName $LogName -FilterXPath $FilterXPath -ErrorAction SilentlyContinue
    if ($ErrorLog.Count -eq 0) {
        Write-Warning -Message "No Windows Update errors found in the $LogName event log!"
    }
    else {
        Write-Host "Windows Update Errors:" -ForegroundColor DarkCyan
        $ErrorLog | ForEach-Object {
            $Properties = $_.Properties
            $UpdateDetails = @{
                "Message"     = $Properties[1].Value
                "EventID"     = $_.Id
                "TimeCreated" = $_.TimeCreated
                "Provider"    = $Properties[0].Value
                "Level"       = $Properties[2].Value
            }
            $UpdateDetails
        }
    }
}
