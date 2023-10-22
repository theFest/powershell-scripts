Function Get-RemoteEventLog {
    <#
    .SYNOPSIS
    Retrieves and filters remote event logs from one or more computers.

    .DESCRIPTION
    This function allows you to query and filter event logs from remote computers.
    Specify various filter criteria such as log name, event level, provider name, time range, event ID, event source, event message, and more.
    Supports exporting the filtered events to different formats like CSV, HTML, JSON, or XML.

    .PARAMETER LogName
    NotMandatory - specifies the name of the event log(s) to query. Valid values are "Application", "System", or "Security".
    .PARAMETER Level
    NotMandatory - filters events based on the event level. Valid values are "Information", "Warning", "Error", "Critical", "Verbose", "LogAlways", "AuditSuccess", or "AuditFailure".
    .PARAMETER ProviderName
    NotMandatory - filters events based on the provider name.
    .PARAMETER StartTime
    NotMandatory - start time of the time range for event filtering. Defaults to 180 days ago from the current date.
    .PARAMETER EndTime
    NotMandatory - end time of the time range for event filtering. Defaults to the current date.
    .PARAMETER ComputerName
    Mandatory - name of one or more remote computers to query for event logs.
    .PARAMETER UserName
    Mandatory - username to use for authentication when accessing remote computers.
    .PARAMETER Pass
    Mandatory - password to use for authentication when accessing remote computers.
    .PARAMETER MaxEvents
    NotMandatory - maximum number of events to retrieve per log. Defaults to 100.
    .PARAMETER OutputFormat
    NotMandatory - format to which the filtered events should be exported. Valid values are "CSV", "HTML", "JSON", or "XML".
    .PARAMETER MaxAge
    NotMandatory - maximum age of events to retrieve. Defaults to 30 days.
    .PARAMETER EventID
    NotMandatory - filters events based on the event ID(s).
    .PARAMETER EventSource
    NotMandatory - filters events based on the event source.
    .PARAMETER EventMessage
    NotMandatory - filters events based on the event message.
    .PARAMETER EventCategory
	NotMandatory - specify the event category to filter.
	.PARAMETER EventUser
	NotMandatory - specify the event user to filter.
	.PARAMETER EventKeyword
	NotMandatory - keyword to filter events based on event message text.
    .PARAMETER IncludeEventDescription
    NotMandatory - includes the event description in the output.
    .PARAMETER UseCredentialManager
    NotMandatory - whether to use the credential manager for authentication.
    .PARAMETER UseRemoteEventSubscriptions
    NotMandatory - whether to use remote event subscriptions for querying events.
    .PARAMETER PageSize
    NotMandatory - page size for event retrieval.
    .PARAMETER OutputDirectory
    NotMandatory - output directory for exporting the filtered events. Defaults to the user's desktop.

    .EXAMPLE
    Get-RemoteEventLog -ComputerName "remote_host" -UserName "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Application", "System", "Security")]
        [string[]]$LogName = 'Security',

        [Parameter(Mandatory = $false)]
        [ValidateSet("Information", "Warning", "Error", "Critical", "Verbose", "LogAlways", "AuditSuccess", "AuditFailure")]
        [string]$Level,

        [Parameter(Mandatory = $false)]
        [string[]]$ProviderName,

        [Parameter(Mandatory = $false)]
        [datetime]$StartTime = (Get-Date).AddDays(-180),

        [Parameter(Mandatory = $false)]
        [datetime]$EndTime = (Get-Date),

        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,

        [Parameter(Mandatory = $true)]
        [string[]]$UserName,

        [Parameter(Mandatory = $true)]
        [string[]]$Pass,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10000)]
        [int]$MaxEvents = 100,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CSV", "HTML", "JSON", "XML")]
        [string]$OutputFormat,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 3650)]
        [TimeSpan]$MaxAge = [System.TimeSpan]::FromDays(30),

        [Parameter(Mandatory = $false)]
        [int[]]$EventID,

        [Parameter(Mandatory = $false)]
        [string]$EventSource,

        [Parameter(Mandatory = $false)]
        [string]$EventMessage,

        [Parameter(Mandatory = $false)]
        [string]$EventCategory,

        [Parameter(Mandatory = $false)]
        [string]$EventUser,

        [Parameter(Mandatory = $false)]
        [string]$EventKeyword,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeEventDescription,

        [Parameter(Mandatory = $false)]
        [switch]$UseCredentialManager,

        [Parameter(Mandatory = $false)]
        [switch]$UseRemoteEventSubscriptions,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000)]
        [int]$PageSize = 100,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputDirectory = "$env:USERPROFILE\Desktop"
    )
    BEGIN {
        if ($UseCredentialManager) {
            $Credential = Get-Credential -UserName $UserName -Message "Enter password for user: $UserName"
        }
        elseif ($Pass) {
            $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential($UserName, $SecurePassword)
        }
        else {
            $Credential = $null
        }
        $EventFilter = "*[System[TimeCreated[@SystemTime >= '$($StartTime.ToUniversalTime().ToString("o"))' -and @SystemTime <= '$($EndTime.ToUniversalTime().ToString("o"))']]]"
        if ($Level) {
            $EventFilter += " and System/Level=$Level"
        }
        if ($ProviderName) {
            $ProviderFilter = $ProviderName | ForEach-Object { "System/Provider[@Name='$_']" }
            $EventFilter += " and ($ProviderFilter)"
        }
        if ($EventSource) {
            $EventFilter += " and System/Provider[@Name='$EventSource']"
        }
        if ($EventMessage) {
            $EventFilter += " and *[System/EventData/Data and *[System/EventData/Data[contains(.,'$EventMessage')]]]"
        }
        if ($EventID) {
            $EventIdString = $EventID -join ','
            $EventFilter += " and System/EventID=($EventIdString)"
        }
        if ($EventCategory) {
            $EventFilter += " and System/Channel=$EventCategory"
        }
        if ($EventUser) {
            $EventFilter += " and System/SecurityUserID='$EventUser'"
        }
        if ($EventKeyword) {
            $EventFilter += " and *[System/EventData/Data and *[System/EventData/Data[contains(.,'$EventKeyword')]]]"
        }
    }
    PROCESS {
        Write-Verbose -Message "Querying events from each remote computer..."
        $Results = foreach ($Computer in $ComputerName) {
            try {
                if ($UseRemoteEventSubscriptions) {
                    $EventLog = New-Object System.Diagnostics.Eventing.Reader.EventLogWatcher -ArgumentList $EventFilter, [System.Diagnostics.Eventing.Reader.PathType]::LogName, $Computer
                    $Events = $EventLog.ReadEvent()
                    $Events
                }
                else {
                    $EventParams = @{
                        LogName      = $LogName
                        ComputerName = $Computer
                        MaxEvents    = $MaxEvents
                        Credential   = $Credential
                        ErrorAction  = "Stop"
                    }
                    $FetchedEvents = Get-WinEvent @EventParams | Where-Object { $_.TimeCreated -ge $StartTime -and $_.TimeCreated -le $EndTime }
                    if ($EventUser) {
                        $FetchedEvents = $FetchedEvents | Where-Object { $_.Properties[1].Value -eq $EventUser }
                    }
                    if ($EventCategory) {
                        $FetchedEvents = $FetchedEvents | Where-Object { $_.ProviderName -eq $EventCategory }
                    }
                    if ($EventKeyword) {
                        $FetchedEvents = $FetchedEvents | Where-Object { $_.Message -like "*$EventKeyword*" }
                    }
                    $FetchedEvents
                }
            }
            catch {
                if ($PSCmdlet.ShouldContinue("Failed to get events from computer $Computer with filter: $EventFilter. Do you want to continue?", "Warning")) {
                    continue
                }
                else {
                    break
                }
            }
        }
        if ($OutputFormat) {
            if (!$OutputDirectory) {
                $OutputDirectory = "$env:USERPROFILE\Desktop"
                Write-Verbose -Message "No output directory specified. Exporting events to $OutputDirectory."
            }
            $OutputDirectory = Convert-Path $OutputDirectory
            if (-not (Test-Path -Path $OutputDirectory)) {
                Write-Verbose -Message "Output directory '$OutputDirectory' does not exist. Creating it..."
                New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
            }
            Write-Verbose -Message "Exporting results to $OutputFormat..."
            $OutputFilePath = Join-Path $OutputDirectory "events.$OutputFormat"
            switch ($OutputFormat.ToLower()) {
                "csv" {
                    $Results | ConvertTo-Csv -NoTypeInformation | Out-File -FilePath $OutputFilePath
                }
                "html" {
                    $Results | ConvertTo-Html | Out-File -FilePath $OutputFilePath
                }
                "json" {
                    $Results | ConvertTo-Json | Out-File -FilePath $OutputFilePath
                }
                "xml" {
                    $Results | ConvertTo-Xml | Out-File -FilePath $OutputFilePath
                }
            }
            Write-Verbose -Message "Exported events to $OutputFilePath."
        }
        $Results
    }
    END {
        Write-Verbose -Message "Processing results..."
        if ($OutputFormat -eq 'CSV') {
            if (!$OutputDirectory) {
                $OutputDirectory = "$env:USERPROFILE\Desktop"
                Write-Verbose -Message "No output directory specified. Exporting events to $OutputDirectory."
            }
            $OutputDirectory = Convert-Path $OutputDirectory
            if (-not (Test-Path $OutputDirectory)) {
                Write-Verbose -Message "Output directory '$OutputDirectory' does not exist. Creating it..."
                New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
            }
            $OutputFilePath = Join-Path $OutputDirectory "events.csv"
            Write-Verbose -Message "Exporting events to $OutputFilePath..."
            $Results | Export-Csv -Path $OutputFilePath -NoTypeInformation
        }
    }
}
