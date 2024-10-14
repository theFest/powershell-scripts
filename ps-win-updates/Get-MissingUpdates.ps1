function Get-MissingUpdates {
    <#
    .SYNOPSIS
    Retrieves information about Windows updates on a local or remote machine.

    .DESCRIPTION
    This function retrieves information about Windows updates, including the count of updates and their details.
    By default, it displays all available updates. Use optional parameters to filter and customize the output. The function also supports checking for missing updates on a remote computer.

    .EXAMPLE
    Get-MissingUpdates -Verbose
    Get-MissingUpdates -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.1.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Name of the remote computer to check, if not provided, the function checks the local system")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, HelpMessage = "Username for authenticating to the remote computer, required for remote checks")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for authenticating to the remote computer, required for remote checks")]
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "Only pending updates will be displayed")]
        [switch]$ShowPendingOnly,

        [Parameter(Mandatory = $false, HelpMessage = "Count of available updates will be displayed")]
        [switch]$ShowCount
    )
    $ScriptBlockGetUpdates = {
        $UpdateSession = New-Object -ComObject Microsoft.Update.Session
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
        $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
        $UpdatesInfo = @{
            Count   = $SearchResult.Updates.Count
            Updates = $SearchResult.Updates
        }
        return $UpdatesInfo
    }
    $ScriptBlockDisplayCount = {
        param($UpdateCount)
        Write-Host "$UpdateCount updates available..." -ForegroundColor DarkCyan
    }
    $ScriptBlockDisplayUpdateInfo = {
        param($Update, $ShowPendingOnly)
        if ($ShowPendingOnly) {
            Write-Host "$($Update.Title)" -ForegroundColor DarkGray
        }
        else {
            Write-Host "$($Update.Title) - $($Update.Date -as [datetime])" -ForegroundColor Gray
        }
    }
    if ($ComputerName) {
        if (-not $User -or -not $Pass) {
            Write-Error "Username and password are required for remote checks."
            return
        }
        $SecPass = ConvertTo-SecureString $Pass -AsPlainText -Force
        $Cred = New-Object System.Management.Automation.PSCredential ($User, $SecPass)
        $Result = Invoke-Command -ComputerName $ComputerName -Credential $Cred -ScriptBlock $ScriptBlockGetUpdates
    }
    else {
        $Result = & $ScriptBlockGetUpdates
    }
    if ($Result.Count -eq 0) {
        Write-Host "No updates found!" -ForegroundColor DarkGreen
    }
    else {
        if ($ShowCount) {
            & $ScriptBlockDisplayCount $Result.Count
        }
        $Result.Updates | ForEach-Object {
            & $ScriptBlockDisplayUpdateInfo $_ $ShowPendingOnly
        }
    }
}
