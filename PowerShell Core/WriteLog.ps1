Function WriteLog {
    <#
    .SYNOPSIS
    Simple function for writing logs.

    .DESCRIPTION
    This function writes, appends and exports logs.

    .PARAMETER LogMessage
    Mandatory - your log message.
    .PARAMETER LogSeverity
    Mandatory - severity of your message.
    .PARAMETER LogPath
    Not mandatory - path to location where you want the file to be saved.
    .PARAMETER LogFileName
    Not mandatory - name of the log file, it will have .csv extension.

    .EXAMPLE
    WriteLog -LogSeverity Alert -LogMessage "your_log_message"
    "your_log_message" | WriteLog -LogSeverity Alert -LogPath "$env:USERPROFILE\Desktop\your_log_path" -LogFileName "you_log_name"

    .NOTES
    v1
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
        [string]$LogFileName = "$env:COMPUTERNAME"
    )
    BEGIN {
        if ($LogPath) {
            if (!(Test-Path -Path $LogPath)) {
                New-Item -Path "$LogPath" -ItemType Directory -Verbose -Force | Out-Null
            }
        } 
        else {
            Write-Error -Message "Unable to create logpath '$LogPath'. Error was: $_" -ErrorAction Stop
        }
    }
    PROCESS {
        if ($LogFileName) {
            $ReportLogTable = [PSCustomObject]@{
                'TimeAppended' = (Get-Date -Format "yyyy-MM-dd-HH:mm")
                'LogMessage'   = $LogMessage
                'LogSeverity'  = $LogSeverity
            }
        }
        $LogFileName = [System.IO.Path]::Combine("$LogFileName.csv")
    }
    END {
        $ReportLogTable | Export-Csv -Path "$LogPath\$LogFileName" -Append -NoTypeInformation
    }
}