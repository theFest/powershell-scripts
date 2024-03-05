Function Read-UpdateHistory {
    <#
    .SYNOPSIS
    Retrieves and displays the update history for a computer.

    .DESCRIPTION
    This function retrieves and displays the update history for a specified computer, can be used locally or remotely via WinRM.

    .PARAMETER Computername
    Name of the remote computer, if not provided, the local computer name is used.
    .PARAMETER User
    Username for authenticating the remote session, if not provided, the current username is used.
    .PARAMETER Pass
    Password for authenticating the remote session, if not provided, a credential prompt will be displayed.

    .EXAMPLE
    Read-UpdateHistory
    Read-UpdateHistory -Computername "remote_host" -Username "remote_user" -Password "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Computername = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$User = $env:USERNAME,

        [Parameter(Mandatory = $false)]
        [string]$Pass = $null
    )
    if ($Computername -and $User -and $Pass) {
        $SessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
        try {
            $RemoteSession = New-PSSession -ComputerName $Computername -Credential (New-Object -TypeName PSCredential -ArgumentList $User, (ConvertTo-SecureString $Pass -AsPlainText -Force)) -SessionOption $SessionOption
            $ScriptBlock = {
                $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
                $HistoryCount = $UpdateSearcher.GetTotalHistoryCount()
                if ($HistoryCount -gt 0) {
                    $UpdateHistory = $UpdateSearcher.QueryHistory(0, $HistoryCount)
                    foreach ($Update in $UpdateHistory) {
                        Write-Output "$($Update.Date) - $($Update.Title) - $($Update.ResultCode)"
                    }
                }
                else {
                    Write-Output "No update history found."
                }
            }
            Invoke-Command -Session $RemoteSession -ScriptBlock $ScriptBlock
        }
        catch {
            Write-Error -Message "Failed to create remote session. Error: $_"
        }
        finally {
            if ($RemoteSession) {
                Remove-PSSession -Session $RemoteSession -Verbose
            }
        }
    }
    else {
        $UpdateSession = New-Object -ComObject Microsoft.Update.Session
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
        $HistoryCount = $UpdateSearcher.GetTotalHistoryCount()
        if ($HistoryCount -gt 0) {
            $UpdateHistory = $UpdateSearcher.QueryHistory(0, $HistoryCount)
            foreach ($Update in $UpdateHistory) {
                Write-Output "$($Update.Date) - $($Update.Title) - $($Update.ResultCode)"
            }
        }
        else {
            Write-Host "No update history found." -ForegroundColor DarkCyan
        }
    }
}
