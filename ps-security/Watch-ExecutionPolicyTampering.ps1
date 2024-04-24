Function Watch-ExecutionPolicyTampering {
    <#
    .SYNOPSIS
    Watches and logs changes to the PowerShell execution policy.

    .DESCRIPTION
    This function creates a scheduled task to monitor changes to the PowerShell execution policy. It logs any changes to the execution policy to a specified file and alerts the user.

    .PARAMETER Frequency
    Frequency of checking for changes in the execution policy, values are "Second", "Minute", or "Hour".
    .PARAMETER LogFilePath
    Path to the log file where the changes to the execution policy will be recorded, default location is the desktop of the current user.

    .EXAMPLE
    Watch-ExecutionPolicyTampering

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("Second", "Minute", "Hour")]
        [string]$Frequency = "Minute",

        [Parameter(Mandatory = $false)]
        [string]$LogFilePath = "$env:USERPROFILE\Desktop\ExecutionPolicy.log"
    )
    Write-Verbose -Message "Define the trigger interval based on frequency"
    switch ($Frequency) {
        "Second" {
            $RepetitionInterval = New-TimeSpan -Seconds 1
        }
        "Minute" {
            $RepetitionInterval = New-TimeSpan -Minutes 1
        }
        "Hour" {
            $RepetitionInterval = New-TimeSpan -Hours 1
        }
    }
    Write-Host "Creating scheduled task trigger..." -ForegroundColor Cyan
    $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date)
    Write-Verbose -Message "Setting repetition for the trigger..."
    $Trigger.Repetition = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval $RepetitionInterval
    Write-Verbose -Message "Defining the scheduled task action..."
    $Action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "Watch-ExecutionPolicy -LogFilePath '$LogFilePath' -Frequency '$Frequency'"
    Write-Verbose -Message "Register the scheduled task..."
    Register-ScheduledTask -TaskName "ExecutionPolicyWatcher" -Trigger $Trigger -Action $Action -RunLevel Highest -Force | Out-Null
    Write-Host "Watching execution policy!" -ForegroundColor Yellow
    $CurrentPolicy = Get-ExecutionPolicy
    while ($true) {
        Write-Information -MessageData "Polling interval set to 500 miliseconds"
        Start-Sleep -Milliseconds 500
        $NewPolicy = Get-ExecutionPolicy
        if ($NewPolicy -ne $CurrentPolicy) {
            $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $ChangeMessage = "Execution Policy changed from '$CurrentPolicy' to '$NewPolicy' at $Timestamp"
            Write-Output $ChangeMessage
            Add-Content -Path $LogFilePath -Value $ChangeMessage
            $CurrentPolicy = $NewPolicy
            Write-Verbose -Message "Alert the user (customize as needed)"
            [System.Windows.Forms.MessageBox]::Show($ChangeMessage, "Execution Policy Change", "OK", [System.Windows.Forms.MessageBoxIcon]::Warning)
        }
    }
}
