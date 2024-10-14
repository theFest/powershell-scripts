function Get-LastUpdateInfo {
    <#
    .SYNOPSIS
    Retrieves information about the last Windows Update check time and scan date.

    .DESCRIPTION
    This function fetches information about the last Windows Update check time and scan date. It can be used both locally and remotely, with optional credentials for remote access.

    .EXAMPLE
    Get-LastUpdateInfo -Verbose
    Get-LastUpdateInfo -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.1.6
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Name of the remote computer to check, if not provided, the function checks the local system")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, HelpMessage = "Username for authenticating to the remote computer, required for remote checks")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for authenticating to the remote computer, required for remote checks")]
        [string]$Pass
    )
    if ($ComputerName -ne $env:COMPUTERNAME -and (-not $User -or -not $Pass)) {
        Write-Warning "Please provide both Username and Password for remote computer access."
        return
    }
    $ScriptBlock = {
        $UpdateSearcher = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher()
        $AutomaticUpdates = New-Object -ComObject Microsoft.Update.AutoUpdate
        $LastCheckTime = $AutomaticUpdates.Results.LastSearchSuccessDate
        Write-Host "Last Windows Update check time on $($env:COMPUTERNAME): $LastCheckTime" -ForegroundColor Green
        $History = $UpdateSearcher.GetTotalHistoryCount()
        if ($History -gt 0) {
            $LastScanDate = $UpdateSearcher.QueryHistory(0, $History) | 
            Sort-Object -Property Date -Descending | 
            Select-Object -First 1 -ExpandProperty Date
            Write-Host "Last Windows Update scan date on $($env:COMPUTERNAME): $LastScanDate" -ForegroundColor Green
        }
        else {
            Write-Warning "No Windows Update scan history found on $($env:COMPUTERNAME)!"
        }
    }
    if ($ComputerName -eq $env:COMPUTERNAME) {
        & $ScriptBlock
    }
    else {
        $SessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
        $SessionCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (ConvertTo-SecureString -String $Pass -AsPlainText -Force)
        try {
            $RemoteSession = New-PSSession -ComputerName $ComputerName -Credential $SessionCredential -SessionOption $SessionOption
            Invoke-Command -Session $RemoteSession -ScriptBlock $ScriptBlock
        }
        catch {
            Write-Error "Failed to connect to $ComputerName. Error: $_"
        }
        finally {
            if ($RemoteSession) {
                Remove-PSSession -Session $RemoteSession -Verbose
            }
        }
    }
}
