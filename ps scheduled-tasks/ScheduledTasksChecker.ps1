Function ScheduledTasksChecker {
    <#
    .SYNOPSIS
    ScheduledTasksChecker allows you to perform various actions on Windows scheduled tasks.
    
    .DESCRIPTION
    The function will perform the specified action on the scheduled task, and it uses Job Cmdlets for job processing, modify as you wish.
    
    .PARAMETER Action
    Mandatory - specifies the action to be performed on the scheduled task, it accepts one of the following strings: "Start", "Stop", "GetStatus", "Enable", "Disable", "GetInfo", "Export".
    .PARAMETER TaskName
    Mandatory - mandatory parameter that specifies the name of the scheduled task to be acted upon, it must be a non-null and non-empty string.
    .PARAMETER TaskPath
    NotMandatory - path of the scheduled task to be acted upon, if not provided, the task will be assumed to be in the root folder of the task scheduler.
    .PARAMETER ExportPath
    NotMandatory - optional parameter that is only used when the $Action is set to "Export", it specifies the path where the exported scheduled task should be saved.
    .PARAMETER AsJob
    NotMandatory - specifies whether the action should be executed as a background job or not, if specified, the action will be executed as a background job, allowing the script to continue executing while the job runs in the background.
    
    .EXAMPLE
    $TaskName = "SilentCleanup"
    $TaskPath = "\Microsoft\Windows\DiskCleanup\"
    ScheduledTasksChecker -Action Start -TaskName $TaskName -TaskPath $TaskPath -AsJob
    ScheduledTasksChecker -Action Stop -TaskName $TaskName -TaskPath $TaskPath -AsJob
    ScheduledTasksChecker -Action GetStatus -TaskName $TaskName -TaskPath $TaskPath -AsJob
    ScheduledTasksChecker -Action Disable -TaskName $TaskName -TaskPath $TaskPath -AsJob
    ScheduledTasksChecker -Action Enable -TaskName $TaskName -TaskPath $TaskPath -AsJob
    ScheduledTasksChecker -Action GetInfo -TaskName $TaskName -TaskPath $TaskPath -AsJob
    ScheduledTasksChecker -Action Export -TaskName $TaskName -TaskPath $TaskPath -ExportPath "$env:USERPROFILE\Desktop"
    
    .NOTES
    v1.0
    #>
    [CmdletBinding()]
    param (   
        [Parameter(Mandatory = $true)]
        [ValidateSet("Start", "Stop", "GetStatus", "Enable", "Disable", "GetInfo", "Export")]
        [string]$Action,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$TaskPath,

        [Parameter(Mandatory = $false, ParameterSetName = "ExportTask")]
        [ValidateNotNullOrEmpty()]
        [string]$ExportPath,

        [switch]$AsJob
    )
    BEGIN {
        $TaskAction = $null
        switch ($Action) {
            "Start" { $TaskAction = "Start-ScheduledTask" }
            "Stop" { $TaskAction = "Stop-ScheduledTask" }
            "GetStatus" { $TaskAction = "Get-ScheduledTask" }
            "Enable" { $TaskAction = "Enable-ScheduledTask" }
            "Disable" { $TaskAction = "Disable-ScheduledTask" }
            "GetInfo" { $TaskAction = "Get-ScheduledTaskInfo" }
            "Export" { $TaskAction = "Export-ScheduledTask" }
        }
    }
    PROCESS {
        if ($TaskPath) {
            $Task = "$TaskAction -TaskName $TaskName -TaskPath $TaskPath"
        }
        else {
            $Task = "$TaskAction -TaskName $TaskName"
        }
        if ($AsJob) {
            $SchTaskJob = Start-Job -ScriptBlock { Invoke-Expression $Using:Task } -Name "SchTaskJob"
            do { 
                Write-Host "Waiting to complete the jobs..."
                $CheckTask = (Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath)
                if (($CheckTask.State -ne "Ready") -and ($CheckTask.Result -ne "0x0")) {
                    Write-Warning -Message "Task is still not in Ready state, nor Last Run Result is success!"
                }
                Start-Sleep -Seconds 10
            }
            until($($SchTaskJob.State) -eq "Completed")
            Write-Host "Job completed, continuing..."
            foreach ($Job in $SchTaskJob.ChildJobs) {
                Write-Host "Result on: $($SchTaskJob.Location)" -ForegroundColor Cyan
                Get-Job -Name "SchTaskJob" | Wait-Job | Receive-Job -Keep -Verbose
            }      
        }
        else {
            Invoke-Expression $Task
            if ($Action -eq "Export") {
                $Task = Get-ScheduledTask -TaskName $TaskName  
                $Task | Export-ScheduledTask -Verbose | Out-File -FilePath "$($ExportPath)\$($TaskName).xml" -Verbose
            }
        }
    }
    END {
        Write-Host "Finishing, output of Scheduled Task($TaskName):..."
        if ($AsJob) {
            Get-Job -Name * -Verbose | Remove-Job -Force -ErrorAction SilentlyContinue
        }
        Write-Output -InputObject $CheckTask | Select-Object *
    }
}