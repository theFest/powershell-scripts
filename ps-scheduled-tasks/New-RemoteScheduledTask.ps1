Function New-RemoteScheduledTask {
    <#
    .SYNOPSIS
    Creates a scheduled task on a remote computer via WinRM.

    .DESCRIPTION
    This function establishes a remote session to a specified computer using PowerShell remoting and creates a scheduled task on that remote machine.

    .PARAMETER ComputerName
    Mandatory - name of the remote computer where the task will be created.
    .PARAMETER Username
    Mandatory - the username used to establish a remote session.
    .PARAMETER Pass
    Mandatory - the password associated with the provided username.
    .PARAMETER TaskName
    Mandatory - the name of the task to be created.
    .PARAMETER ActionPath
    Mandatory - path to the script or executable file to be executed by the task.
    .PARAMETER TriggerType
    Mandatory - type of trigger for the task (e.g., "Daily", "Weekly", etc.).
    .PARAMETER TriggerValue
    Mandatory - the value for the trigger (e.g., "3:00AM" for Daily trigger).
    .PARAMETER Description
    NotMandatory - specifies an optional description for the task.

    .EXAMPLE
    New-RemoteScheduledTask -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass" -TaskName "Test_Task" -ActionPath "C:\Temp\Test_Task.ps1" -TriggerType "Daily" -TriggerValue "3:00AM" -Description "TT Script"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $true)]
        [string]$Username,
        
        [Parameter(Mandatory = $true)]
        [string]$Pass,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $true)]
        [string]$ActionPath,
        
        [Parameter(Mandatory = $true)]
        [string]$TriggerType,
        
        [Parameter(Mandatory = $true)]
        [string]$TriggerValue,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )
    BEGIN {
        $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
        $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
    }
    PROCESS {
        try {
            Invoke-Command -Session $Session -ScriptBlock {
                param($TaskName, $ActionPath, $TriggerType, $TriggerValue, $Description)
                Import-Module ScheduledTasks -Force -Verbose
                $Trigger = New-ScheduledTaskTrigger -Once -At $TriggerValue
                $Action = New-ScheduledTaskAction -Execute $ActionPath
                Register-ScheduledTask -TaskName $TaskName -Trigger $Trigger -Action $Action -Description $Description -RunLevel Highest -Force
            } -ArgumentList $TaskName, $ActionPath, $TriggerType, $TriggerValue, $Description
        }
        catch {
            Write-Error -Message "Failed to create scheduled task on $ComputerName : $_"
        }
    }
    END {
        if ($Session) {
            Remove-PSSession -Session $Session -Verbose -ErrorAction SilentlyContinue
        }
    }
}
