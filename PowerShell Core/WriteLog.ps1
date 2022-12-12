Function WriteLog {
    <#
    .SYNOPSIS
    This function writes logs.
    
    .DESCRIPTION
    This function writes, appends and exports logs.
    
    .PARAMETER LogMessage
    Mandatory - your log message.
    .PARAMETER LogSeverity
    Mandatory - severity of your message.
    .PARAMETER LogPath
    Not mandatory - path to location where you want the file to be saved.
    If LogPath is not declared, folder will be created inside $env:APPDATA\BMX\Logs

    .NOTES
    If LogPath is not declared, logs will end in $env:TEMP\Logs.
    If LogFileName if not declared, hostname will be used as one.

    .EXAMPLE
    WriteLog -LogMessage "Your_Message" -LogSeverity Information -LogPath "C:\" -LogFileName "Your_File_Name"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LogMessage,
 
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Information', 'Warning', 'Alert', 'Error')]
        [string]$LogSeverity = 'Information',

        [Parameter(Mandatory = $false)]
        [string]$LogPath,
		
        [Parameter(Mandatory = $false)]
        [string]$LogFileName
    )
    BEGIN {
        if ($LogPath) {
            New-Item -Path "$LogPath" -ItemType Directory -Force | Out-Null
        } 
        elseif (!$LogPath) {
            New-Item -Path "$env:TEMP\Logs" -ItemType Directory -Force | Out-Null
            $LogPath = "$env:TEMP\Logs"
        }
        else {
            Write-Error -Message "Unable to create logpath '$LogPath'. Error was: $_" -ErrorAction Stop
        }
    }
    PROCESS {
        if ($LogFileName) {
            $LogFileName = "$LogFileName" + ".csv"
        }
        elseif (!$LogFileName) {
            $LogFileName = "$env:COMPUTERNAME" + ".csv"
        }
        $ReportLogTable = [PSCustomObject]@{
            'TimeAppended' = (Get-Date -Format "yyyy-MM-dd-HH:mm")
            'LogMessage'   = $LogMessage
            'LogSeverity'  = $LogSeverity
        }
    }
    END {
        $ReportLogTable | Export-Csv -Path "$LogPath\$LogFileName" -Append -NoTypeInformation
    }
}