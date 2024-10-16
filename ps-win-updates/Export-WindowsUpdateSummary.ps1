function Export-WindowsUpdateSummary {
    <#
    .SYNOPSIS
    Exports a summary of Windows Update installations to the console and optionally to a file.

    .DESCRIPTION
    This function retrieves and displays a summary of Windows Update installations by parsing a Windows Update log file, summary includes information about the installation results and supports both local and remote machines. If the log file does not contain any installation details, the function will query Windows Event Logs for updates.
    
    .EXAMPLE
    Export-WindowsUpdateSummary
    Export-WindowsUpdateSummary -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.3.6
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Name of the remote computer, efaults to the local computer if not specified")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Username for accessing the remote machine (required for remote operations)")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for accessing the remote machine (not needed for local operations)")]
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the Windows Update log file to parse.")]
        [string]$LogPath,

        [Parameter(Mandatory = $false, HelpMessage = "Path for the output file where the summary will be saved, defaults to the desktop")]
        [string]$OutputPath = "$env:USERPROFILE\Desktop\windows_update_summary.log"
    )
    BEGIN {
        $CommonLogPaths = @(
            "C:\Windows\Logs\WindowsUpdate\WindowsUpdate.log",
            "C:\Windows\WindowsUpdate.log",
            "C:\Windows\SoftwareDistribution\ReportingEvents.log",
            "C:\ProgramData\USOShared\Logs\UsoCoreWorker.etl"
        )
        if (-not $LogPath) {
            $LogPath = $CommonLogPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
            if (-not $LogPath) {
                Write-Error -Message "No valid Windows Update log found in common paths!"
                return
            }
            Write-Host "Using log file: $LogPath" -ForegroundColor Green
        }
        if ($ComputerName -and $User -and $Pass) {
            $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential($User, $SecurePassword)
        }
    }
    PROCESS {
        if ($ComputerName) {
            Write-Host "Running on remote machine: $ComputerName" -ForegroundColor Green
            $ScriptBlock = {
                param ($LogPath)
                if (-not (Test-Path -Path $LogPath)) {
                    Write-Error -Message "The specified log file '$LogPath' does not exist!"
                    return
                }
                $InstallSummary = Get-Content -Path $LogPath | Select-String -Pattern "Installation Result|Update successful|Completed install"
                return $InstallSummary
            }
            $InstallSummary = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock $ScriptBlock -ArgumentList $LogPath
        }
        else {
            if (-not (Test-Path $LogPath)) {
                Write-Error -Message "The specified log file '$LogPath' does not exist."
                return
            }
            $InstallSummary = Get-Content -Path $LogPath | Select-String -Pattern "Installation Result|Update successful|Completed install"
        }
        if ($InstallSummary -and $InstallSummary.Count -gt 0) {
            $OutputData = "Windows Update Installation Summary:`r`n"
            $OutputData += $InstallSummary | ForEach-Object {
                "  $_"
            }
            Write-Output -InputObject $OutputData
            $OutputData | Out-File -FilePath $OutputPath -Force
        }
        else {
            Write-Warning -Message "No installation summary found in the log file! Searching the event logs for updates."
            $EventLogQuery = Get-WinEvent -FilterHashtable @{LogName = 'System'; ID = 19, 20, 21, 42 } |
            Where-Object { $_.ProviderName -eq 'Microsoft-Windows-WindowsUpdateClient' }
            if ($EventLogQuery.Count -gt 0) {
                $OutputData = "Windows Update Event Log Summary:`r`n"
                $OutputData += $EventLogQuery | ForEach-Object {
                    "Date: $($_.TimeCreated) | $($_.Message)"
                }
                Write-Output -InputObject $OutputData
                $OutputData | Out-File -FilePath $OutputPath -Force
            }
            else {
                Write-Warning -Message "No update information found in the event logs!"
            }
        }
    }
    END {
        if ($InstallSummary -or $EventLogQuery) {
            Write-Host "Summary saved to: $OutputPath" -ForegroundColor Cyan
        }
    }
}
