Function Invoke-ScheduledTaskOperation {
    <#
    .SYNOPSIS
    Manage scheduled tasks using the SCHTASKS utility.

    .DESCRIPTION
    This function provides a simplified interface to manage scheduled tasks using the SCHTASKS utility.
    It allows you to create, modify, query, run, end, and delete scheduled tasks. You can specify various parameters and options to customize the behavior of the scheduled tasks.

    .PARAMETER Operation
    NotMandatory - operation to perform on the scheduled task. Valid values: 'Create', 'Change', 'Query', 'Run', 'End', 'Delete'.
    .PARAMETER FilePath
    NotMandatory - path to the script file for creating a scheduled task.
    .PARAMETER FileName
    NotMandatory - name of the script file for creating a scheduled task.
    .PARAMETER WebContentURL
    NotMandatory - URL to download the script file for creating a scheduled task.
    .PARAMETER WebContentLocalPath
    NotMandatory - local directory to save the downloaded script file.
    .PARAMETER XMLImportPath
    NotMandatory - path to the XML file to import a scheduled task.
    .PARAMETER XMLScriptPath
    NotMandatory - path to the script referenced in the XML file.
    .PARAMETER ComputerName
    NotMandatory - the name of the remote computer.
    .PARAMETER RunAsUser
    NotMandatory - the username to run the task as.
    .PARAMETER TriggerType
    NotMandatory - trigger type for the task. Valid values: 'MINUTE', 'HOURLY', 'DAILY', 'WEEKLY', 'MONTHLY', 'ONCE', 'ONSTART', 'ONLOGON', 'ONIDLE'.
    .PARAMETER Interval
    NotMandatory - specifies the interval for the task.
    .PARAMETER TaskName
    NotMandatory - specifies the name of the scheduled task.
    .PARAMETER ProgramPath
    NotMandatory - the path of the program or command that the task runs.
    .PARAMETER StartDate
    NotMandatory - specifies the date on which the task schedule starts.
    .PARAMETER EndDate
    NotMandatory - specifies the end date of the task schedule.
    .PARAMETER Description
    NotMandatory - specifies the description of the scheduled task.
    .PARAMETER Author
    NotMandatory - specifies the author of the scheduled task.
    .PARAMETER Enable
    NotMandatory - enables the scheduled task.
    .PARAMETER Disable
    NotMandatory - disables the scheduled task.
    .PARAMETER RunAsUserAccount
    NotMandatory - the user account to run the task as.
    .PARAMETER RunAsUserPass
    NotMandatory - the password for the user account.
    .PARAMETER WorkingDirectory
    NotMandatory - the working directory for the task.
    .PARAMETER Priority
    NotMandatory - the priority of the task (0-10).
    .PARAMETER MaxRunTime
    NotMandatory - maximum runtime for the task in seconds.
    .PARAMETER Arguments
    NotMandatory - the arguments to pass to the program/command.
    .PARAMETER AdditionalTriggers
    NotMandatory - specifies additional triggers for the task.
    .PARAMETER ExportTasksCSV
    NotMandatory - indicates whether to export the list of scheduled tasks to a CSV file.
    .PARAMETER ExportPath
    NotMandatory - the path for exporting the list of scheduled tasks to a CSV file.

    .EXAMPLE
    Invoke-ScheduledTaskOperation -Operation CreateTask -WebContentURL "https://example.com/your_script.ps1" -WebContentLocalPath "C:\your_scripts" -TaskName "your_sch_task" -TriggerType DAILY -Interval 1
    Invoke-ScheduledTaskOperation -Operation CreateTask -FilePath "C:\Scripts" -FileName "your_script.ps1" -TaskName "your_sch_task" -TriggerType DAILY -Interval 1 -ProgramPath "C:\Scripts\your_script.ps1" -Verbose
    Invoke-ScheduledTaskOperation -Operation CreateTask -XMLImportPath "C:\Scripts\TaskDefinition.xml" -XMLScriptPath "C:\Scripts\your_script.ps1" -TaskName "your_sch_task" -RunAsUser "your_user" -RunAsUserPass "your_pass"
    Invoke-ScheduledTaskOperation -Operation ChangeTask -TaskName "your_task" -TriggerType DAILY -Interval 30 -ProgramPath "$env:USERPROFILE\Desktop\your_script.ps1" -Verbose
    Invoke-ScheduledTaskOperation -Operation QueryTask -TaskName "your_task"
    Invoke-ScheduledTaskOperation -Operation RunTask -TaskName "your_task"
    Invoke-ScheduledTaskOperation -Operation EndTask -TaskName "your_task" -Verbose
    Invoke-ScheduledTaskOperation -Operation DeleteTask -TaskName "your_task" -Verbose

    .NOTES
    v0.0.2
    #>
    [CmdletBinding(DefaultParameterSetName = "FilePathContent")]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "FilePathContent", HelpMessage = "Choose schedule task operation method")]
        [ValidateSet("CreateTask", "ChangeTask", "QueryTask", "RunTask", "EndTask", "DeleteTask")]
        [string]$Operation,

        [Parameter(Mandatory = $false, ParameterSetName = "FilePathContent", HelpMessage = "The path to the script file")]
        [string]$FilePath,

        [Parameter(Mandatory = $false, ParameterSetName = "FilePathContent", HelpMessage = "The name of the script file")]
        [string]$FileName,

        [Parameter(Mandatory = $false, ParameterSetName = "WebContent", HelpMessage = "The URL to download the script file")]
        [string]$WebContentURL,

        [Parameter(Mandatory = $false, ParameterSetName = "WebContent", HelpMessage = "The local directory to save the downloaded script file")]
        [string]$WebContentLocalPath,

        [Parameter(Mandatory = $false, ParameterSetName = "XMLImportScheme", HelpMessage = "The path to the XML file to import")]
        [string]$XMLImportPath,

        [Parameter(Mandatory = $false, ParameterSetName = "XMLImportScheme", HelpMessage = "The path to the script referenced in the XML file")]
        [string]$XMLScriptPath,

        [Parameter(Mandatory = $false, ParameterSetName = "Computer", HelpMessage = "The name of the remote computer")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, ParameterSetName = "RunAsSpecifiedUser", HelpMessage = "The username to run the task as")]
        [string]$RunAsUser,

        [Parameter(Mandatory = $false, HelpMessage = "The trigger type for the task")]
        [ValidateSet("MINUTE", "HOURLY", "DAILY", "WEEKLY", "MONTHLY", "ONCE", "ONSTART", "ONLOGON", "ONIDLE")]
        [string]$TriggerType = "DAILY",

        [Parameter(Mandatory = $false, HelpMessage = "The interval for the task")]
        [ValidateRange(1, 9999)]
        [int]$Interval = 1,

        [Parameter(Mandatory = $false, HelpMessage = "The name of the scheduled task")]
        [ValidateNotNullOrEmpty()]
        [string]$TaskName,

        [Parameter(Mandatory = $false, HelpMessage = "The path of the program or command that the task runs")]
        [ValidateNotNullOrEmpty()]
        [string]$ProgramPath,

        [Parameter(Mandatory = $false, HelpMessage = "The date on which the task schedule starts")]
        [ValidateNotNullOrEmpty()]
        [datetime]$StartDate,

        [Parameter(Mandatory = $false, HelpMessage = "The end date of the task schedule")]
        [ValidateNotNullOrEmpty()]
        [datetime]$EndDate,

        [Parameter(Mandatory = $false, HelpMessage = "The description of the scheduled task")]
        [string]$Description,

        [Parameter(Mandatory = $false, HelpMessage = "The author of the scheduled task")]
        [string]$Author,

        [Parameter(Mandatory = $false, HelpMessage = "Enable the scheduled task")]
        [switch]$Enable,

        [Parameter(Mandatory = $false, HelpMessage = "Disable the scheduled task")]
        [switch]$Disable,

        [Parameter(Mandatory = $false, HelpMessage = "The user account to run the task as")]
        [string]$RunAsUserAccount,

        [Parameter(Mandatory = $false, HelpMessage = "The password for the user account")]
        [string]$RunAsUserPass,

        [Parameter(Mandatory = $false, HelpMessage = "The working directory for the task")]
        [string]$WorkingDirectory,

        [Parameter(Mandatory = $false, HelpMessage = "The priority of the task (0-10)")]
        [ValidateRange(0, 10)]
        [int]$Priority = 5,

        [Parameter(Mandatory = $false, HelpMessage = "The maximum runtime for the task in seconds")]
        [ValidateRange(1, [System.Int32]::MaxValue)]
        [int]$MaxRunTime = 0,

        [Parameter(Mandatory = $false, HelpMessage = "The arguments to pass to the program/command")]
        [string]$Arguments,

        [Parameter(Mandatory = $false, HelpMessage = "Additional triggers for the task")]
        [ValidateScript({
                if ($_ -is [string[]]) { return $true }
                throw "AdditionalTriggers must be an array of strings"
            })]
        [string[]]$AdditionalTriggers,

        [Parameter(Mandatory = $false, HelpMessage = "Export the list of scheduled tasks to a CSV file")]
        [switch]$ExportTasksCSV,

        [Parameter(Mandatory = $false)]
        [string]$ExportPath = "$env:TEMP\SchTasksExportedTasks.csv"
    )
    BEGIN {
        $PSPath = "$env:windir\System32\WindowsPowerShell\v1.0\powershell.exe"
        $TaskFilePath = "$env:windir\System32\Tasks\$TaskName"
        if ($Operation -eq "Create") {
            if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
                Write-Warning "The task '$TaskName' already exists. Please choose a different task name or use the 'Change' operation."
                return
            }
            if (Test-Path -Path $TaskFilePath) {
                $DeleteChoice = Read-Host "The task file path '$TaskFilePath' already exists. Do you want to overwrite the existing contents? (Y/N)"
                if ($DeleteChoice -eq 'Y') {
                    Remove-Item -Path $TaskFilePath -Force -ErrorAction SilentlyContinue
                }
                else {
                    return
                }
            }
        }
    }
    PROCESS {
        switch ($Operation) {
            "CreateTask" {
                if ($ParameterSetName -eq "WebContent") {
                    Write-Verbose -Message "Downloading and creating a scheduled task from web content"
                    New-Item -Path $WebContentLocalPath -Name $TaskName -ItemType Directory -Force | Out-Null
                    $LocalFilePath = Join-Path -Path $WebContentLocalPath -ChildPath $TaskName
                    Invoke-WebRequest -Uri $WebContentURL -OutFile $LocalFilePath -UseBasicParsing -Verbose
                    SCHTASKS /Create /SC $TriggerType /TN $TaskName /TR "$PSPath -NoLogo -ExecutionPolicy Bypass -File $LocalFilePath"
                }
                elseif ($ParameterSetName -eq "FilePathContent") {
                    Write-Verbose -Message "Creating a scheduled task from the specified script file"
                    $ScriptPath = Join-Path -Path $FilePath -ChildPath $FileName
                    SCHTASKS /Create /SC $TriggerType /MO $Interval /TN $TaskName /TR "$PSPath -NoLogo -ExecutionPolicy Bypass -File $ScriptPath"
                }
                elseif ($ParameterSetName -eq "XMLImportScheme") {
                    Write-Verbose -Message "Importing a scheduled task from the XML file"
                    if ((Test-Path -Path $XMLImportPath) -and (Test-Path -Path $XMLScriptPath)) {
                        SCHTASKS /Create /XML $XMLImportPath /TN $TaskName /RU $RunAsUser /RP $RunAsUserPass /F
                    }
                    else {
                        Write-Error "Incorrect paths: $XMLImportPath and $XMLScriptPath"
                        break
                    }
                }
            }
            "ChangeTask" {
                Write-Verbose -Message "Modifying an existing scheduled task"
                if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
                    SCHTASKS /Change /TN $TaskName /SC $TriggerType /MO $Interval /TR "$PSPath -NoLogo -ExecutionPolicy Bypass -File $ProgramPath"
                }
                else {
                    Write-Warning -Message "The task '$TaskName' does not exist in the scheduled tasks library. Use the 'Create' operation to create a new task."
                }
            }
            "QueryTask" {
                Write-Verbose -Message "Querying information about the scheduled task"
                SCHTASKS /Query /V /TN $TaskName
            }
            "RunTask" {
                Write-Verbose -Message "Running the scheduled task immediately"
                SCHTASKS /Run /TN $TaskName
            }
            "EndTask" {
                Write-Verbose -Message "Ending a running scheduled task"
                SCHTASKS /End /TN $TaskName
            }
            "DeleteTask" {
                Write-Warning -Message "Deleting the scheduled task"
                $DeleteChoice = Read-Host "Are you sure you want to delete the task '$TaskName'? (Y/N)"
                if ($DeleteChoice -eq "Y") {
                    SCHTASKS /Delete /TN $TaskName /F
                }
                else {
                    Write-Host "Task deletion cancelled." -ForegroundColor DarkGray
                }
            }
            default {
                Write-Warning -Message "Invalid operation specified. Please choose from 'Create', 'Change', 'Query', 'Run', 'End', 'Delete'."
            }
        }
    }
    END {
        if ($ExportTasksCSV) {
            SCHTASKS /Query /FO CSV /V | Out-File -FilePath $ExportPath -Force
            Write-Output -InputObject "Scheduled tasks list has been exported to: $ExportPath"
        }
    }
}
