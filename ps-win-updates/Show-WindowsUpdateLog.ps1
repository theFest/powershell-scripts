function Show-WindowsUpdateLog {
    <#
    .SYNOPSIS
    Retrieves Windows Update logs from specified paths, with support for remote execution.

    .DESCRIPTION
    This function retrieves Windows Update logs from default and custom log paths. Users can specify additional custom log paths, filter log entries by date, control the output format, limit the number of lines shown, and run the command on a remote computer.

    .EXAMPLE
    Show-WindowsUpdateLog -Verbose
    Show-WindowsUpdateLog -CustomLogPaths "C:\CustomPath\CustomLog.log"
    Show-WindowsUpdateLog -StartDate (Get-Date).AddDays(-7)
    Show-WindowsUpdateLog -LineCount 10
    Show-WindowsUpdateLog -ComputerName "RemotePC" -User "Admin" -Pass "Password" -CustomLogPaths "C:\CustomPath\CustomLog.log"

    .NOTES
    v0.2.8
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Name of the computer to run the command on")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Additional custom log paths to be included in the search")]
        [string[]]$CustomLogPaths = @(),

        [Parameter(Mandatory = $false, HelpMessage = "Filters log entries to include only those created on or after this date")]
        [datetime]$StartDate,

        [Parameter(Mandatory = $false, HelpMessage = "Filters log entries to include only those created on or before this date")]
        [datetime]$EndDate,

        [Parameter(Mandatory = $false, HelpMessage = "Specifies the format of the output, accepts 'Text' or 'Object'")]
        [ValidateSet("Text", "Object")]
        [string]$OutputFormat = "Text",

        [Parameter(Mandatory = $false, HelpMessage = "If specified, detailed log entries will be displayed")]
        [switch]$ShowDetails,

        [Parameter(Mandatory = $false, HelpMessage = "Specifies the maximum number of lines to show from the retrieved logs")]
        [int]$LineCount,

        [Parameter(Mandatory = $false, HelpMessage = "Username for remote authentication")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for remote authentication")]
        [string]$Pass
    )
    $DefaultLogPaths = @(
        "$env:SystemRoot\WindowsUpdate.log",
        "$env:SystemRoot\SoftwareDistribution\ReportingEvents.log",
        "$env:SystemRoot\Logs\CBS\CBS.log"
        # Add more default log paths as needed
    )
    $UpdateLogPaths = $DefaultLogPaths + $CustomLogPaths
    $FoundLogs = @()
    $Credential = if ($User -and $Pass) {
        $SecurePass = ConvertTo-SecureString $Pass -AsPlainText -Force
        New-Object System.Management.Automation.PSCredential($User, $SecurePass)
    }
    if ($ComputerName -ne $env:COMPUTERNAME) {
        $scriptBlock = {
            param ($UpdateLogPaths, $StartDate, $EndDate)
            $FoundLogs = @()
            foreach ($LogPath in $UpdateLogPaths) {
                if (Test-Path -Path $LogPath) {
                    try {
                        $LogContent = Get-Content -Path $LogPath -ErrorAction Stop
                        if ($StartDate) {
                            $LogContent = $LogContent | Where-Object { [datetime]::Parse($_.Substring(0, 19)) -ge $StartDate }
                        }
                        if ($EndDate) {
                            $LogContent = $LogContent | Where-Object { [datetime]::Parse($_.Substring(0, 19)) -le $EndDate }
                        }
                        $FoundLogs += $LogContent
                    }
                    catch {
                        Write-Host "Error reading log at ${LogPath}: $_" -ForegroundColor DarkRed
                    }
                }
                else {
                    Write-Host "Log not found at: $LogPath" -ForegroundColor DarkGreen
                }
            }
            return $FoundLogs
        }
        if ($Credential) {
            $FoundLogs = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -ArgumentList $UpdateLogPaths, $StartDate, $EndDate -Credential $Credential
        }
        else {
            $FoundLogs = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock -ArgumentList $UpdateLogPaths, $StartDate, $EndDate
        }
    }
    else {
        foreach ($LogPath in $UpdateLogPaths) {
            if (Test-Path -Path $LogPath) {
                try {
                    $LogContent = Get-Content -Path $LogPath -ErrorAction Stop
                    if ($StartDate) {
                        $LogContent = $LogContent | Where-Object { [datetime]::Parse($_.Substring(0, 19)) -ge $StartDate }
                    }
                    if ($EndDate) {
                        $LogContent = $LogContent | Where-Object { [datetime]::Parse($_.Substring(0, 19)) -le $EndDate }
                    }
                    $FoundLogs += $LogContent
                }
                catch {
                    Write-Host "Error reading log at ${LogPath}: $_" -ForegroundColor DarkRed
                }
            }
            else {
                Write-Host "Log not found at: $LogPath" -ForegroundColor DarkGreen
            }
        }
    }
    if ($FoundLogs.Count -gt 0) {
        if ($ShowDetails) {
            $FoundLogs | ForEach-Object { Write-Host "Detail: $_" }
        }
        else {
            if ($LineCount -and $LineCount -gt 0) {
                $FoundLogs = $FoundLogs | Select-Object -Last $LineCount
            }
            if ($OutputFormat -eq "Text") {
                return $FoundLogs
            }
            elseif ($OutputFormat -eq "Object") {
                return $FoundLogs | ConvertTo-Json
            }
        }
    }
    else {
        Write-Warning -Message "No Windows Update logs found!"
    }
}
