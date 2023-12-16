Function New-ScheduledTask {
    <#
    .SYNOPSIS
    Creates a new scheduled task locally.

    .DESCRIPTION
    This function creates a scheduled task on the local machine using PowerShell. It allows users to schedule tasks with specific triggers, actions, and user context.

    .PARAMETER TaskName
    Mandatory - name of the scheduled task to be created.
    .PARAMETER ActionPath
    Mandatory - the path to the script or executable file to be executed by the task.
    .PARAMETER TriggerType
    Mandatory - the type of trigger for the task (e.g., "Once", "Daily", "Weekly", etc.).
    .PARAMETER StartTime
    Mandatory - specifies the start time for the scheduled task.
    .PARAMETER EndTime
    NotMandatory - end time for the scheduled task. Default is 30 days from the current date.
    .PARAMETER User
    Mandatory - the user context under which the task will run.
    .PARAMETER Arguments
    NotMandatory - optional arguments to be passed to the script or executable file.

    .EXAMPLE
    New-ScheduledTask -TaskName "Test_Task" -ActionPath "$env:USERPROFILE\Desktops\your_script.ps1" -TriggerType "Daily" -StartTime (Get-Date) -User "your_user" -Arguments "-Force"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $true)]
        [string]$ActionPath,

        [Parameter(Mandatory = $true)]
        [string]$TriggerType,

        [Parameter(Mandatory = $true)]
        [datetime]$StartTime,

        [Parameter(Mandatory = $false)]
        [datetime]$EndTime = (Get-Date).AddDays(30),

        [Parameter(Mandatory = $true)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Arguments = ""
    )
    BEGIN {
        Write-Verbose -Message "Checking if scheduled task '$TaskName' already exists..."
        $ExistingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($ExistingTask) {
            Write-Warning -Message "Scheduled task '$TaskName' already exists. Please choose a different task name"
            break
        }
        Write-Host "Creating scheduled task '$TaskName'..." -ForegroundColor DarkCyan
    }
    PROCESS {
        $Trigger = New-ScheduledTaskTrigger -At $StartTime -Once
        $Action = New-ScheduledTaskAction -Execute $ActionPath -Argument $Arguments
        Register-ScheduledTask -TaskName $TaskName -Trigger $Trigger -User $User -Action $Action -Description "Test task created by PowerShell"
        if ($EndTime) {
            $Task = Get-ScheduledTask -TaskName $TaskName
            $Task.Triggers[0].EndBoundary = $EndTime.ToString("yyyy-MM-ddTHH:mm:ss")
            Set-ScheduledTask $Task -Verbose
        }
    }
    END {
        Write-Host "Scheduled task '$TaskName' created successfully" -ForegroundColor Green
    }
}
