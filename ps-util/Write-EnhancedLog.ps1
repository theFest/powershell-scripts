Function Write-EnhancedLog {
    <#
    .SYNOPSIS
    Writes log messages with enhanced features such as custom severity levels, custom fields, and various output formats.

    .DESCRIPTION
    This function allows users to write log messages with customizable severity levels, additional custom fields, and choose from different output formats including CSV, JSON, and plain text.

    .PARAMETER LogMessage
    Specifies the message to log.

    .PARAMETER LogSeverity
    Severity level of the log, options include "Information", "Trace", "Alert", "Debug", "Warning", "Error", "Critical", "Fatal", "Verbose", "Emergency", "Notice", "Severe", "Info", "Important", and "Success".
    .PARAMETER LogPath
    Directory path where logs will be stored. Defaults to $env:TEMP if not provided.
    .PARAMETER LogFileName
    Name of the log file, defaults to $env:COMPUTERNAME if not provided.
    .PARAMETER CustomFields
    Additional custom fields to include in the log entry.
    .PARAMETER LogFormat
    Format in which logs will be stored, options are "CSV", "JSON", or "PlainText". Defaults to "CSV" if not provided.
    .PARAMETER TimestampFormat
    Timestamp format, defaults to "yyyy-MM-dd-HH:mm" if not provided.

    .EXAMPLE
    "Your log message" | Write-EnhancedLog -LogSeverity Alert -LogPath "$env:USERPROFILE\Desktop" -LogFileName "YourLogName"

    .NOTES
    v0.5.4
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Specify the message to log")]
        [ValidateNotNullOrEmpty()]
        [string]$LogMessage,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the severity level of the log")]
        [ValidateSet(
            "Information", 
            "Trace", 
            "Alert", 
            "Debug", 
            "Warning", 
            "Error", 
            "Critical", 
            "Fatal", 
            "Verbose",
            "Emergency",
            "Notice",
            "Severe",
            "Info",
            "Important",
            "Success"
        )]
        [ValidateNotNullOrEmpty()]
        [string]$LogSeverity,

        [Parameter(Mandatory = $false, HelpMessage = "Directory path where logs will be stored")]
        [string]$LogPath = "$env:TEMP",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the name of the log file")]
        [string]$LogFileName = "$env:COMPUTERNAME",

        [Parameter(Mandatory = $false, HelpMessage = "Additional custom fields to include in the log entry")]
        [hashtable]$CustomFields,

        [Parameter(Mandatory = $false, HelpMessage = "Format in which logs will be stored")]
        [ValidateSet("CSV", "JSON", "PlainText")]
        [string]$LogFormat = "CSV",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the timestamp format")]
        [ValidateSet("yyyy-MM-dd-HH:mm", "yyyy-MM-dd-HH:mm:ss", "yyyyMMddHHmmss", "yyyy/MM/dd HH:mm:ss", "MM/dd/yyyy HH:mm:ss", "dd-MM-yyyy HH:mm:ss")]
        [string]$TimestampFormat = "yyyy-MM-dd-HH:mm"
    )
    BEGIN {
        if (!(Test-Path -Path $LogPath)) {
            try {
                New-Item -Path $LogPath -ItemType Directory -ErrorAction Stop | Out-Null
            }
            catch {
                Write-Error -Message "Unable to create log path '$LogPath'. Error was: $_"
                return
            }
        }
        $LogFileExtension = if ($LogFormat -eq "CSV" -or $LogFormat -eq "JSON") {
            ".$LogFormat"
        }
        else {
            ".log"
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
        switch ($LogFormat) {
            "CSV" {
                $LogEntryObject = [PSCustomObject]$LogEntry
                $LogEntryObject | Export-Csv -Path $LogFileName -Append -NoTypeInformation -Force
            }
            "JSON" {
                $LogEntryJson = $LogEntry | ConvertTo-Json
                Add-Content -Path $LogFileName -Value $LogEntryJson -Encoding UTF8
            }
            "PlainText" {
                $LogEntryText = "[$($LogEntry["TimeAppended"])][$($LogEntry["LogSeverity"])] $($LogEntry["LogMessage"])"
                Add-Content -Path $LogFileName -Value $LogEntryText -Encoding UTF8
            }
            default {
                Write-Warning "Unsupported log format: $LogFormat"
            }
        }
    }
}
