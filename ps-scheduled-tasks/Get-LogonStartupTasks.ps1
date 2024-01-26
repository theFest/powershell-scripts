Function Get-LogonStartupTasks {
    <#
    .SYNOPSIS
    Retrieve logon and startup tasks.

    .DESCRIPTION
    This function retrieves logon and startup tasks based on specified parameters.

    .PARAMETER TaskPaths
    Specifies the paths to search for tasks, defaults to the root path '\'.
    .PARAMETER MicrosoftPath
    Include tasks from the '\Microsoft*' path in the search.
    .PARAMETER IncludeDisabled
    Include disabled tasks in the result.
    .PARAMETER IncludeTrigger
    Filter tasks based on trigger type ('Both', 'Boot', 'Logon'), defaults to 'Both'.

    .EXAMPLE
    Get-LogonStartupTasks
    Get-LogonStartupTasks -TaskPaths '\', '\CustomPath' -MicrosoftPath -IncludeDisabled -IncludeTrigger Logon

    .NOTES
    v0.0.1
    #>
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("t")]
        [ValidateNotNullOrEmpty()]
        [string[]]$TaskPaths = '\',

        [Parameter(Mandatory = $false, Position = 1)]
        [Alias("mp")]
        [switch]$MicrosoftPath,

        [Parameter(Mandatory = $false)]
        [Alias("id")]
        [switch]$IncludeDisabled,

        [Parameter(Mandatory = $false)]
        [Alias("it")]
        [ValidateSet("Both", "Boot", "Logon")]
        [string]$IncludeTrigger = "Both"
    )
    $LogonStartupTriggers = foreach ($TaskPath in $TaskPaths) {
        $Tasks = Get-ScheduledTask -TaskPath $TaskPath -ErrorAction SilentlyContinue |
        Where-Object { $_.Triggers -match 'LogonTrigger|BootTrigger' }
        if ($MicrosoftPath) {
            $MicrosoftTasks = Get-ScheduledTask -TaskPath "\Microsoft*" -ErrorAction SilentlyContinue |
            Where-Object { $_.Triggers -match 'LogonTrigger|BootTrigger' }
            $Tasks += $MicrosoftTasks
        }
        foreach ($Task in $Tasks) {
            foreach ($Trigger in $Task.Triggers) {
                $IsBootTrigger = $Trigger.CimClass.CimClassName -eq 'MSFT_TaskBootTrigger'
                $IsLogonTrigger = $Trigger.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger'
                $TaskPathValue = if ($Task.TaskPath -eq "") { '\' } else { $Task.TaskPath }
                $IsReadyOrRunning = $Task.State -in @('Ready', 'Running')
                if ($IncludeDisabled -or ($IsReadyOrRunning -and !$IncludeDisabled)) {
                    if (($IncludeTrigger -eq 'Both') -or
                        ($IncludeTrigger -eq 'Boot' -and $IsBootTrigger) -or 
                        ($IncludeTrigger -eq 'Logon' -and $IsLogonTrigger)
                    ) {
                        $Properties = @{
                            TaskName   = $Task.TaskName
                            TaskPath   = $TaskPathValue
                            TaskAction = ($Task.Actions | ForEach-Object { $_.Arguments }) -join ', '
                            TaskState  = $Task.State
                            Trigger    = $Trigger.CimClass.CimClassName
                        }
                        if ($Task.Settings) {
                            $Properties += @{
                                AllowDemandStart   = $Task.Settings.AllowDemandStart
                                AllowHardTerminate = $Task.Settings.AllowHardTerminate
                                Enabled            = $Task.Settings.Enabled
                                Priority           = $Task.Settings.Priority
                                RunOnlyIfIdle      = $Task.Settings.RunOnlyIfIdle
                            }
                        }
                        [PSCustomObject]$Properties
                    }
                }
            }
        }
    }
    Write-Output -InputObject $LogonStartupTriggers
}
