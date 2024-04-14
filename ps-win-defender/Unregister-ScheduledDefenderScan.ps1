Function Unregister-ScheduledDefenderScan {
    <#
    .SYNOPSIS
    Removes the scheduled Windows Defender scan task.

    .DESCRIPTION
    This function removes the scheduled Windows Defender scan task created by the Register-ScheduledDefenderScan function. Additionally, it lists all non-Microsoft scheduled tasks and prompts the user to select the task to unregister.

    .PARAMETER TaskName
    Name of the scheduled task to unregister. If not provided, a list of non-Microsoft scheduled tasks will be displayed for selection.

    .EXAMPLE
    Unregister-ScheduledDefenderScan -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Name of the scheduled task to unregister")]
        [string]$TaskName
    )
    try {
        if (-not $TaskName) {
            Write-Verbose -Message "Listing non-Microsoft scheduled tasks..."
            $Tasks = Get-ScheduledTask | Where-Object { $_.TaskPath -notlike "*\Microsoft*" } | Select-Object -ExpandProperty TaskName
            if ($Tasks.Count -eq 0) {
                Write-Host "No non-Microsoft scheduled tasks found" -ForegroundColor DarkCyan
                return
            }
            Write-Verbose -Message "Prompting user to select task..."
            $TaskChoice = $Tasks | Out-GridView -Title "Select Task to Unregister" -PassThru
            if (-not $TaskChoice) {
                Write-Host "Task selection canceled." -ForegroundColor Yellow
                return
            }
            $TaskName = $TaskChoice
        }
        Write-Verbose -Message "Unregistering scheduled task '$TaskName'..."
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -Verbose
        Write-Host "Scheduled task '$TaskName' has been successfully removed." -ForegroundColor Green
    }
    catch {
        Write-Error -Message "Error occurred while unregistering the scheduled task: $_!"
    }
    finally {
        Write-Verbose -Message "Scheduled task unregistration process completed"
    }
}
