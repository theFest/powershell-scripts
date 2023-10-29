Function Write-EnhancedLog {
    <#
    .SYNOPSIS
    Enhanced function for writing logs.

    .DESCRIPTION
    This function writes, appends, and exports logs in various formats (CSV, JSON, or plain text). It supports custom fields and allows you to specify the log timestamp format.

    .PARAMETER LogMessage
    Mandatory - your log message.
    .PARAMETER LogSeverity
    Mandatory - severity of your message.
    .PARAMETER LogPath
    Not mandatory - path to the location where you want the file to be saved.
    .PARAMETER LogFileName
    Not mandatory - name of the log file.
    .PARAMETER CustomFields
    Not mandatory - custom fields to include in the log entry.
    .PARAMETER LogFormat
    Not mandatory - log format (CSV, JSON, or PlainText). Default is CSV.
    .PARAMETER TimestampFormat
    Not mandatory - timestamp format for log entries. Default is "yyyy-MM-dd-HH:mm".

    .EXAMPLE
    Write-EnhancedLog -LogSeverity Alert -LogMessage "Your log message"
    "Your log message" | Write-EnhancedLog -LogSeverity Alert -LogPath "$env:USERPROFILE\Desktop\YourLogPath" -LogFileName "YourLogName"

    .NOTES
    v0.2.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LogMessage,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("Information", "Trace", "Alert", "Debug", "Warning", "Error", "Critical", "Fatal")]
        [string]$LogSeverity,

        [Parameter(Mandatory = $false)]
        [string]$LogPath = "$env:TEMP",

        [Parameter(Mandatory = $false)]
        [string]$LogFileName = "$env:COMPUTERNAME",

        [Parameter(Mandatory = $false)]
        [hashtable]$CustomFields,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CSV", "JSON", "PlainText")]
        [string]$LogFormat = "CSV",

        [Parameter(Mandatory = $false)]
        [string]$TimestampFormat = "yyyy-MM-dd-HH:mm"
    )
    BEGIN {
        if (!(Test-Path -Path $LogPath)) {
            try {
                New-Item -Path $LogPath -ItemType Directory -ErrorAction Stop
            }
            catch {
                Write-Error "Unable to create log path '$LogPath'. Error was: $_"
                return
            }
        }
        if ($LogFormat -eq "CSV" -or $LogFormat -eq "JSON") {
            $LogFileExtension = ".$LogFormat"
        }
        else {
            $LogFileExtension = ".log"
        }
        $LogFileName = [System.IO.Path]::Combine($LogPath, "$LogFileName$LogFileExtension")
    }
    PROCESS {
        $LogEntry = @{
            "TimeAppended" = (Get-Date -Format $TimestampFormat)
            "LogMessage"   = $LogMessage
            "LogSeverity"  = $LogSeverity
        }
        if ($CustomFields) {
            foreach ($Key in $CustomFields.Keys) {
                $LogEntry[$Key] = $CustomFields[$Key]
            }
        }
        if ($LogFormat -eq "CSV") {
            $LogEntryObject = [PSCustomObject]$LogEntry
            $LogEntryObject | Export-Csv -Path $LogFileName -Append -NoTypeInformation -Force
        }
        elseif ($LogFormat -eq "JSON") {
            $LogEntryJson = $LogEntry | ConvertTo-Json
            Add-Content -Path $LogFileName -Value $LogEntryJson -Encoding UTF8
        }
        else {
            $LogEntryText = "[$($LogEntry["TimeAppended"])][$($LogEntry["LogSeverity"])] $($LogEntry["LogMessage"])"
            Add-Content -Path $LogFileName -Value $LogEntryText -Encoding UTF8
        }
    }
}
