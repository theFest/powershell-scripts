Function Search-Eventlog {
    <#
    .SYNOPSIS
    Searches event logs on local or remote machines.

    .DESCRIPTION
    This function searches for specific events within Windows event logs on a local or remote computer. It can filter based on log name, time frame, event ID, and more.

    .PARAMETER ComputerName
    Name of the remote computer to search for event logs, defaults to the local computer.
    .PARAMETER Hours
    Specifies the number of hours to search back for events, defaults to 1 hour.
    .PARAMETER EventID
    Specifies the Event ID number to search for.
    .PARAMETER EventLogName
    Specifies the name of the event log to search in.
    .PARAMETER GridView
    Outputs results in a grid view format.
    .PARAMETER Filter
    Specifies a string to search for in event messages.
    .PARAMETER OutCSV
    Specifies the output path for saving results in CSV format.
    .PARAMETER ExcludeLog
    Excludes specific logs from the search, e.g., security or application logs.
    .PARAMETER User
    Specifies the username for accessing a remote computer.
    .PARAMETER Pass
    Specifies the password for accessing a remote computer.

    .EXAMPLE
    Search-Eventlog -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -GridView

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(DefaultParameterSetName = "All")]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Name of remote computer")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Number of hours to search back for")]
        [double]$Hours = 1,

        [Parameter(Mandatory = $false, HelpMessage = "EventID number")]
        [int[]]$EventID,

        [Parameter(Mandatory = $false, HelpMessage = "The name of the event log to search in")]
        [string[]]$EventLogName,

        [Parameter(Mandatory = $false, ParameterSetName = "GridView", HelpMessage = "Output results in a grid view")]
        [switch]$GridView,

        [Parameter(Mandatory = $false, HelpMessage = "String to search for")]
        [string]$Filter,

        [Parameter(Mandatory = $false, ParameterSetName = "CSV", HelpMessage = "Output path, e.g., c:\data\events.csv")]
        [string]$OutCSV,

        [Parameter(Mandatory = $false, HelpMessage = "Exclude specific logs, e.g., security or application, security")]
        [string[]]$ExcludeLog,

        [Parameter(Mandatory = $false, HelpMessage = "Username for remote computer")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for remote computer")]
        [string]$Pass
    )
    $Credentials = $null
    if ($ComputerName -ne $env:COMPUTERNAME -and $User -and $Pass) {
        $SecurePass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
        $Credentials = New-Object -TypeName PSCredential -ArgumentList $User, $SecurePass
    }
    elseif ($ComputerName -ne $env:COMPUTERNAME) {
        $Credentials = Get-Credential
    }
    [datetime]$StartTime = (Get-Date).AddHours(-$Hours)
    try {
        if ($ComputerName -ne $env:COMPUTERNAME -and $Credentials) {
            if ($EventLogName) {
                $EventLogNames = Get-WinEvent -ListLog $EventLogName -ComputerName $ComputerName -Credential $Credentials -ErrorAction Stop |
                Where-Object LogName -NotIn $ExcludeLog
            }
            else {
                $EventLogNames = Get-WinEvent -ListLog * -ComputerName $ComputerName -Credential $Credentials -ErrorAction Stop |
                Where-Object LogName -NotIn $ExcludeLog
            }
            Write-Host "EventLog names $($EventLogNames.LogName -join ', ') are valid on $ComputerName, continuing..." -ForegroundColor Green
        }
        else {
            if ($EventLogName) {
                $EventLogNames = Get-WinEvent -ListLog $EventLogName -ComputerName $ComputerName -ErrorAction Stop |
                Where-Object LogName -NotIn $ExcludeLog
            }
            else {
                $EventLogNames = Get-WinEvent -ListLog * -ComputerName $ComputerName -ErrorAction Stop |
                Where-Object LogName -NotIn $ExcludeLog
            }
            Write-Host "EventLog names $($EventLogNames.LogName -join ', ') are valid on $ComputerName, continuing..." -ForegroundColor Green
        }
    }
    catch {
        Write-Warning -Message "Error accessing EventLogs on $ComputerName : $_"
        return
    }
    $Total = foreach ($Log in $EventLogNames) {
        Write-Host "[Eventlog $($Log.LogName)] - Retrieving events from the $($Log.LogName) Event log on $ComputerName..." -ForegroundColor Green
        try {
            $FilterHashtable = @{
                LogName   = $Log.LogName
                StartTime = $StartTime
            }
            if ($EventID) {
                $FilterHashtable.Add('ID', $EventID)
            }
            if ($ComputerName -ne $env:COMPUTERNAME -and $Credentials) {
                $Events = Get-WinEvent -FilterHashtable $FilterHashtable -ComputerName $ComputerName -Credential $Credentials -ErrorAction Stop
            }
            else {
                $Events = Get-WinEvent -FilterHashtable $FilterHashtable -ComputerName $ComputerName -ErrorAction Stop
            }
            foreach ($Event in $Events) {
                if (-not $Filter -or $Event.Message -match $Filter) {
                    [PSCustomObject]@{
                        Time         = $Event.TimeCreated.ToString('dd-MM-yyyy HH:mm')
                        Computer     = $ComputerName
                        LogName      = $Event.LogName
                        ProviderName = $Event.ProviderName
                        Level        = $Event.LevelDisplayName
                        User         = if ($Event.UserId) { "$($Event.UserId)" } else { "N/A" }
                        EventID      = $Event.ID
                        Message      = $Event.Message
                    }
                }
            }
            Write-Host "$($Events.Count) events found in the $($Log.LogName) Event log on $ComputerName" -ForegroundColor Green
        }
        catch {
            Write-Warning "No events found in $($Log.LogName) within the specified time-frame (After $StartTime), EventID, or Filter on ${ComputerName}: $_"
        }
    }
    if ($GridView -and $Total) {
        $Total | Sort-Object Time, LogName | Out-GridView -Title 'Retrieved events...'
    }
    if ($OutCSV -and $Total) {
        try {
            $Total | Sort-Object Time, LogName | Export-Csv -NoTypeInformation -Delimiter ';' -Encoding UTF8 -Path $OutCSV -ErrorAction Stop
            Write-Host "Exported results to $OutCSV" -ForegroundColor Green
        }
        catch {
            Write-Warning -Message "Error saving results to $OutCSV, check path or permissions. Exiting..."
        }
    }
    if (-not $OutCSV -and -not $GridView -and $Total) {
        $Total | Sort-Object Time, LogName
    }
    if (-not $Total) {
        Write-Warning -Message "No results were found on $ComputerName"
    }
}
