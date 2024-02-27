Function Get-LastUpdateInfo {
    <#
    .SYNOPSIS
    Retrieves information about the last Windows Update check time and scan date.

    .DESCRIPTION
    This function fetches information about the last Windows Update check time and scan date. It can be used both locally and remotely, with optional credentials for remote access.

    .PARAMETER ComputerName
    Name of the target computer, defaults to the local computer.
    .PARAMETER User
    Specifies the username for remote computer access.
    .PARAMETER Pass
    Specifies the password for remote computer access.

    .EXAMPLE
    Get-LastUpdateInfo
    Get-LastUpdateInfo -ComputerName "remote_host" -Username "remote_user" -Password "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Pass
    )
    if ($ComputerName -ne $env:COMPUTERNAME -and (-not $User -or -not $Pass)) {
        Write-Warning -Message "Please provide both Username and Password for remote computer access."
        return
    }
    $AutomaticUpdates = New-Object -ComObject Microsoft.Update.AutoUpdate
    $LastCheckTime = $AutomaticUpdates.Results.LastSearchSuccessDate
    Write-Host "Last Windows Update check time on ${ComputerName}: $LastCheckTime" -ForegroundColor Green
    $SessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
    $SessionCredential = $null
    if ($Pass) {
        $SessionCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (ConvertTo-SecureString -String $Pass -AsPlainText -Force)
    }
    $RemoteScriptBlock = {
        $UpdateSearcher = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher()
        $History = $UpdateSearcher.GetTotalHistoryCount()
        if ($History -gt 0) {
            $LastScanDate = $UpdateSearcher.QueryHistory(0, $History) | 
            Sort-Object -Property Date -Descending | 
            Select-Object -First 1 -ExpandProperty Date

            Write-Host "Last Windows Update scan date on $($env:COMPUTERNAME): $LastScanDate" -ForegroundColor Green
        }
        else {
            Write-Warning -Message "No Windows Update scan history found on $($env:COMPUTERNAME)!"
        }
    }
    if ($ComputerName -ne $env:COMPUTERNAME) {
        $RemoteSession = New-PSSession -ComputerName $ComputerName -Credential $SessionCredential -SessionOption $SessionOption
        Invoke-Command -ScriptBlock $RemoteScriptBlock -Session $RemoteSession
        Remove-PSSession -Session $RemoteSession -Verbose
    }
    else {
        Invoke-Command -ScriptBlock $RemoteScriptBlock
    }
}
