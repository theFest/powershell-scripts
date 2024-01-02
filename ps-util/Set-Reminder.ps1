Function Set-Reminder {
    <#
    .SYNOPSIS
    Sets a reminder to display a message after a specified time or minutes.
    
    .DESCRIPTION
    This function allows users to set a reminder message that will be displayed after a specified time or minutes. It creates a job that sleeps for the specified duration and then displays the message.
    
    .PARAMETER Message
    Mandatory - specifies the text of the reminder message.
    .PARAMETER Time
    Mandatory - specifies the exact time when the reminder should be displayed.
    .PARAMETER Minutes
    NotMandatory - the duration in minutes before the reminder is displayed.
    .PARAMETER Wait
    NotMandatory - adds the /W flag to the message, making the reminder wait for user acknowledgment.
    .PARAMETER Passthru
    NotMandatory - returns the created job object.
    
    .EXAMPLE
    Set-Reminder -Message "Meeting at 3 PM" -Time "12/31/2023 2:30PM"
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding(DefaultParameterSetName = "Minutes", SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Enter the alert message text")]
        [string]$Message,

        [Parameter(Mandatory = $true, ParameterSetName = "Time", HelpMessage = "Exact date and time when the reminder should be displayed")]
        [ValidateNotNullorEmpty()]
        [Alias("Date", "Dt")]
        [datetime]$Time,
    
        [Parameter(Mandatory = $false, ParameterSetName = "Minutes", HelpMessage = "Duration, in minutes, before the reminder is displayed")]
        [ValidateNotNullorEmpty()]
        [int]$Minutes = 1,

        [Parameter(Mandatory = $false, HelpMessage = "Specifies to wait for user acknowledgment")]
        [switch]$Wait,
    
        [Parameter(Mandatory = $false, HelpMessage = "Returns the created job object")]
        [switch]$Passthru
    )
    BEGIN {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"  
        Write-Verbose -Message "Using parameter set $($PSCmdlet.ParameterSetName)"
        $Sleep = switch ($PSCmdlet.ParameterSetName) {
            "Time" { ($Time - (Get-Date)).TotalSeconds }
            "Minutes" { $Minutes * 60 }
        }
        $LastJob = Get-Job -Name "Reminder*" | Sort-Object ID | Select-Object -last 1
        if ($LastJob) {
            [Regex]$Rx = "\d+$"
            $Counter = [int]$Rx.Match($LastJob.Name).Value + 1
        }
        else {
            $Counter = 1
        }
    }
    PROCESS {
        Write-Verbose -message "Sleeping for $Sleep seconds"
        $Sb = {
            Param($Sleep, $Cmd)
            Start-Sleep -Seconds $Sleep
            Invoke-Expression $Cmd
        }
        $Cmd = "msg.exe $env:UserName"
        if ($Wait) {
            Write-Verbose -Message "Reminder will wait for user"
            $Cmd += " /W"
        }
        $Cmd += " $Message"
        $JobName = "Reminder$Counter"
        Write-Verbose -Message "Creating job $JobName"
        $WhatIf = "'$Message' in $Sleep seconds"
        if ($PSCmdlet.ShouldProcess($WhatIf)) {
            $Job = Start-Job -ScriptBlock $Sb -ArgumentList $Sleep, $Cmd -Name $JobName 
            $Job | Add-Member -MemberType NoteProperty -Name Message -Value $Message
            $Job | Add-Member -MemberType NoteProperty -Name Time -Value (Get-Date).AddSeconds($Sleep)
            $Job | Add-Member -MemberType NoteProperty -Name Wait -Value $Wait
            if ($Passthru) {
                $Job
            }
        }
    }
    END {
        Write-Verbose -Message "Do not close this PowerShell session or you will lose the reminder job"
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
    }
}
