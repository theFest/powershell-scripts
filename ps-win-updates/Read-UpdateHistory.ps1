function Read-UpdateHistory {
    <#
    .SYNOPSIS
    Retrieves and displays the Windows Update history from a local or remote computer.

    .DESCRIPTION
    This function queries the Windows Update history on the specified computer. It can use WMI for remote queries and COM objects for local queries.
    It outputs the update date, title, and result code for each update in the history. If no updates are found, or if errors occur, appropriate messages are displayed.

    .EXAMPLE
    Read-UpdateHistory -Verbose
    Read-UpdateHistory -Computername "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.4.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "remote computer from which to retrieve the update history. If not specified, the function queries the local computer")]
        [string]$Computername = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Username for the remote connection, required if `ComputerName` is specified")]
        [string]$User = $env:USERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Password for the remote connection, required if `ComputerName` is specified")]
        [string]$Pass = $null
    )
    if ($Computername -ne $env:COMPUTERNAME) {
        if ($User -and $Pass) {
            Write-Verbose -Verbose "Creating CIM session to query remote update history on $Computername..."
            $Credential = New-Object System.Management.Automation.PSCredential ($User, (ConvertTo-SecureString $Pass -AsPlainText -Force))
            $SessionOptions = New-CimSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
            try {
                $Session = New-CimSession -ComputerName $Computername -Credential $Credential -SessionOption $SessionOptions
                $Query = "SELECT * FROM Win32_QuickFixEngineering"
                $Updates = Get-CimInstance -Query $Query -CimSession $Session
                Write-Verbose -Message "Successfully queried remote update history."
            }
            catch {
                Write-Error -Message "Failed to query remote update history. Error: $_"
                return
            }
            finally {
                Remove-CimSession -CimSession $Session -Verbose
            }
        }
        else {
            Write-Error -Message "User and Pass must be provided for remote queries!"
            return
        }
    }
    else {
        Write-Verbose -Verbose "Querying local update history using COM objects...."
        $ScriptBlock = {
            $UpdateSession = New-Object -ComObject Microsoft.Update.Session
            $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
            $HistoryCount = $UpdateSearcher.GetTotalHistoryCount()
            if ($HistoryCount -gt 0) {
                Write-Verbose -Verbose "Found $HistoryCount updates in the history"
                $UpdateHistory = $UpdateSearcher.QueryHistory(0, $HistoryCount)
                $UpdateHistory
            }
            else {
                return "No update history found."
            }
        }
        $Updates = & $ScriptBlock
    }
    if ($Updates) {
        $Updates | ForEach-Object {
            if ($Computername -ne $env:COMPUTERNAME) {
                "$($_.HotFixID) - $($_.Description) - $($_.InstalledOn)"
            }
            else {
                "$($_.Date) - $($_.Title) - $($_.ResultCode)"
            }
        }
    }
}
