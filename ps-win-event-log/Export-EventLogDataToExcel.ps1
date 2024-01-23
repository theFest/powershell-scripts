Function Export-EventLogDataToExcel {
    <#
    .SYNOPSIS
    Exports event log data and PSReadLine history from remote computers to an Excel file.

    .DESCRIPTION
    This function exports event log data and PSReadLine history from one or more remote computers to an Excel file, requires the ImportExcel module to be installed on the system.

    .PARAMETER ComputerName
    Specifies one or more remote computers from which to export event log data, defaults to the local computer.
    .PARAMETER Filename
    Specifies the path and filename of the Excel file to which the data will be exported.
    .PARAMETER PowerShellEventlogOnly
    Switch to export only PowerShell-related event logs, if specified, only PowerShell-related logs are exported.
    .PARAMETER PSReadLineHistoryOnly
    Switch to export only PSReadLine history, if specified, only PSReadLine history is exported.
    .PARAMETER User
    Specifies the username for authentication when accessing remote computers.
    .PARAMETER Pass
    Specifies the password for authentication when accessing remote computers.

    .EXAMPLE
    Export-EventLogDataToExcel -Filename "$env:USERPROFILE\Desktop\results.xlsx"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(DefaultparameterSetname = "All")]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [string]$Filename,
        
        [Parameter(Mandatory = $false, ParameterSetname = "EventLog")]
        [switch]$PowerShellEventlogOnly,

        [Parameter(Mandatory = $false, ParameterSetname = "History")]
        [switch]$PSReadLineHistoryOnly,

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Pass
    )
    BEGIN {
        if (-not ($Filename.EndsWith('.xlsx'))) {
            Write-Warning -Message ("Specified {0} filename does not end with .xlsx, exiting..." -f $Filename)
            return
        }
        if (-not (Test-Path -Path $Filename)) {
            try {
                New-Item -Path $Filename -ItemType File -Force:$true -Confirm:$false -ErrorAction Stop | Out-Null
                Remove-Item -Path $Filename -Force:$true -Confirm:$false | Out-Null
                Write-Host ("Specified {0} filename is correct, and the path is accessible, continuing..." -f $Filename) -ForegroundColor Green
            }
            catch {
                Write-Warning -Message ("Path to specified {0} filename is not accessible, correct or file is in use, exiting..." -f $Filename)
                return
            }
        }
        else {
            Write-Warning -Message ("Specified file {0} already exists, appending data to it..." -f $Filename)
        }
        if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
            Write-Warning -Message "The ImportExcel module was not found on the system, installing now..."
            try {
                Install-Module -Name ImportExcel -SkipPublisherCheck -Force:$true -Confirm:$false -Scope CurrentUser -ErrorAction Stop
                Import-Module -Name ImportExcel -Scope Local -ErrorAction Stop
                Write-Host "Successfully installed the ImportExcel module, continuing.." -ForegroundColor Green
            }
            catch {
                Write-Warning -Message "Could not install the ImportExcel module, exiting..."
                return
            }
        }
        else {
            try {
                Import-Module -Name ImportExcel -Scope Local -ErrorAction Stop
                Write-Host "The ImportExcel module was found on the system, continuing..." -ForegroundColor Green
            }
            catch {
                Write-Warning -Message "Error importing the ImportExcel module, exiting..."
                return  
            }
        }
    }
    PROCESS {
        foreach ($Computer in $ComputerName | Sort-Object) {
            $Cred = $null
            if ($User -and $Pass) {
                $SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
                $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecPass
            }
            $PSDriveParams = @{
                Name        = "RemoteC$"
                PSProvider  = "FileSystem"
                Root        = "\\$($Computer)\c$"
                Credential  = $Cred
                ErrorAction = 'SilentlyContinue'
            }
            New-PSDrive @PSDriveParams | Out-Null
            $PsDriveExists = Get-PSDrive -Name "RemoteC$" -ErrorAction SilentlyContinue
            if ($PsDriveExists) {
                Write-Host ("`nComputer {0} is accessible, continuing..." -f $Computer) -ForegroundColor Green
                if (-not $PSReadLineHistoryOnly) {
                    $TotalEventLogs = foreach ($Eventlog in $Eventlogs) {
                        $Events = Get-WinEvent -LogName $Eventlog -ComputerName $Computer -Credential $Cred -ErrorAction SilentlyContinue
                        if ($Events.count -gt 0) {
                            Write-Host ("- Exporting {0} events from the {1} EventLog" -f $Events.count, $Eventlog) -ForegroundColor Green
                            foreach ($Event in $Events) {
                                [PSCustomObject]@{
                                    ComputerName = $Computer
                                    EventlogName = $Eventlog
                                    TimeCreated  = $Event.TimeCreated
                                    EventID      = $Event.Id
                                    Message      = $Event.Message
                                }
                            }
                        }
                        else {
                            Write-Host ("- No events found in the {0} Eventlog" -f $Eventlog) -ForegroundColor Gray
                        }
                    }
                    if ($TotalEventLogs.count -gt 0) {
                        try {
                            $TotalEventLogs | Export-Excel -Path $Filename -WorksheetName "PowerShell_EventLog_$($Date)" -AutoFilter -AutoSize -Append
                            Write-Host ("Exported Eventlog data to {0}" -f $Filename) -ForegroundColor Green
                        }
                        catch {
                            Write-Warning -Message ("Error exporting Eventlog data to {0} (File in use?), exiting..." -f $Filename)
                            return
                        }
                    }
                }
                if (-not $EventlogOnly) {
                    if (-not $PowerShellEventlogOnly) {
                        Write-Host ("Checking for Users/Documents and Settings folder on {0}" -f $Computer) -ForegroundColor Green
                        try {
                            if (Test-Path "\\$($Computer)\c$\Users") {
                                $UsersFolder = "\\$($Computer)\c$\Users"
                            }
                            else {
                                $UsersFolder = "\\$($Computer)\c$\Documents and Settings"
                            }
                        }
                        catch {
                            Write-Warning -Message ("Error finding Users/Documents and Settings folder on {0}. Exiting..." -f $Computer)
                            return
                        }
                        Write-Host ("Scanning for PSReadLine History files in {0}" -f $UsersFolder) -ForegroundColor Green
                        $HistoryFiles = foreach ($UserProfileFolder in Get-ChildItem -Path $UsersFolder -Directory) {
                            $List = Get-ChildItem -Path "$($UserProfileFolder.FullName)\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\*.txt" -ErrorAction SilentlyContinue
                            if ($list.Count -gt 0) {
                                Write-Host ("- {0} PSReadLine history file(s) found in {1}" -f $List.Count, $UserProfileFolder.FullName) -ForegroundColor Green
                                foreach ($File in $List) {
                                    [PSCustomObject]@{
                                        HistoryFileName = $File.FullName
                                    }
                                }   
                            }
                            else {
                                Write-Host ("- No PSReadLine history file(s) found in {0}" -f $UserProfileFolder.FullName) -ForegroundColor Gray
                            }
                        }
                        $TotalHistoryLogs = foreach ($File in $HistoryFiles) {
                            $HistoryData = Get-Content -Path $File.HistoryFileName -ErrorAction SilentlyContinue
                            if ($HistoryData.Count -gt 0) {
                                Write-Host ("- Exporting {0} PSReadLine History events from the {1} file" -f $HistoryData.Count, $File.HistoryFileName) -ForegroundColor Green
                                foreach ($Line in $HistoryData) {
                                    if ($Line.Length -gt 0) {
                                        [PSCustomObject]@{
                                            ComputerName = $Computer
                                            FileName     = $File.HistoryFileName
                                            Command      = $Line
                                        }
                                    }
                                }
                            }
                            else {
                                Write-Warning -Message ("No PSReadLine history found in the {0} file" -f $Log)
                            }
                        }
                        if ($TotalHistoryLogs.count -gt 0) {
                            try {
                                $TotalHistoryLogs | Export-Excel -Path $Filename -WorksheetName "PSReadLine_History_$($Date)" -AutoFilter -AutoSize -Append
                                Write-Host ("Exported PSReadLine history to {0}" -f $Filename) -ForegroundColor Green
                            }
                            catch {
                                Write-Warning -Message ("Error exporting PSReadLine history data to {0} (File in use?), exiting..." -f $Filename)
                                return
                            }
                        }
                    }
                }
            }
            else {
                Write-Warning -Message ("Specified computer {0} is not accessible, check permissions and network settings. Skipping..." -f $Computer)
                continue
            }
        }
    }
    END {
        Remove-PSDrive -Name "RemoteC$" -ErrorAction SilentlyContinue
    }
}
