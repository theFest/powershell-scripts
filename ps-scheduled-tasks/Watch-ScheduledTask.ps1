Function Watch-ScheduledTask {
    <#
    .SYNOPSIS
    Watches a scheduled task for modifications and logs changes.

    .DESCRIPTION
    This function monitors a specified scheduled task for modifications and records the changes in a log file.

    .PARAMETER TaskName
    Specifies the name of the scheduled task to monitor.
    .PARAMETER SourceIdentifier
    Identifier for the event source, default value is "TaskChange$TaskName".
    .PARAMETER LogFilePath
    File path for the log file to store the task modification details.

    .EXAMPLE
    Watch-ScheduledTask -TaskName "your_task" -LogFilePath "$env:USERPROFILE\Desktop\TaskLog.csv"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    [Alias("Task-Watcher")]
    param (
        [Parameter(Mandatory = $true)]
        [Alias("t")]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [Alias("s")]
        [string]$SourceIdentifier = "TaskChange$TaskName",

        [Parameter(Mandatory = $true)]
        [Alias("l")]
        [string]$LogFilePath
    )
    BEGIN {
        try {
            Get-ScheduledTask -TaskName $TaskName -ErrorAction Stop
        }
        catch {
            Write-Error -Message "The task $TaskName was not found!"
            return
        }
        if (-not (Test-Path -Path $LogFilePath)) {
            $LogHeader = "TimeStamp,PreviousState,CurrentState,EventType`n"
            $LogHeader | Out-File -FilePath $LogFilePath -Encoding utf8 -Append
        }
    }
    PROCESS {
        $Query = "Select * from __InstanceModificationEvent WITHIN 10 WHERE TargetInstance ISA 'MSFT_ScheduledTask' AND TargetInstance.TaskName='$TaskName'"
        $NS = 'Root\Microsoft\Windows\TaskScheduler'
        $Action = {
            $Previous = $Event.SourceEventArgs.NewEvent.PreviousInstance
            $Current = $Event.SourceEventArgs.NewEvent.TargetInstance
            $EventType = if ($Event.SourceEventArgs.NewEvent.EventType) {
                $Event.SourceEventArgs.NewEvent.EventType
            }
            else {
                "Unknown"
            }
            $EventData = "$(Get-Date), $($Previous.State), $($Current.State), $eventType"
            $EventData | Out-File -FilePath $LogFilePath -Encoding utf8 -Append
        }
        Register-CimIndicationEvent -SourceIdentifier $SourceIdentifier -Namespace $NS -query $Query -MessageData "The task $TaskName has changed" -MaxTriggerCount 7 -Action $Action
    }
    END {
        Unregister-Event -SourceIdentifier $SourceIdentifier -ErrorAction SilentlyContinue -Verbose
        Write-Host "Listing Event Subscriptions:"
        Get-EventSubscriber
    }
}
