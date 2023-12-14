Function Get-RemoteScheduledTasks {
    <#
    .SYNOPSIS
    Retrieves scheduled tasks from a remote computer.

    .DESCRIPTION
    This function establishes a remote session to a specified computer using PowerShell remoting and retrieves scheduled tasks using the ScheduledTasks module. It allows retrieving scheduled tasks from a remote machine by providing credentials.

    .PARAMETER ComputerName
    Mandatory - name of the remote computer from which to retrieve scheduled tasks.
    .PARAMETER Username
    Mandatory - the username to establish a remote session.
    .PARAMETER Pass
    Mandatory - the password associated with the provided username.
    .PARAMETER OutputCSV
    NotMandatory - path to save the output as a CSV file.

    .EXAMPLE
    Get-RemoteScheduledTasks -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass" -OutputCSV "$env:USERPROFILE\Desktop\ScheduledTasks.csv"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, HelpMessage = "Enter the computer name")]
        [Alias('Computer')]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $true, HelpMessage = "Enter the username")]
        [Alias('User')]
        [ValidateNotNullOrEmpty()]
        [string]$Username,
        
        [Parameter(Mandatory = $true, HelpMessage = "Enter the password")]
        [Alias('Password')]
        [ValidateNotNullOrEmpty()]
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "Enter the path to save the output as CSV")]
        [Alias('CSV')]
        [string]$OutputCSV
    )
    BEGIN {
        try {
            $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
        }
        catch {
            Write-Error -Message "Failed to establish a remote session to $ComputerName : $_"
            return
        }
    }
    PROCESS {
        try {
            $Tasks = Invoke-Command -Session $Session -ScriptBlock {
                param($Computer)
                Import-Module ScheduledTasks
                Get-ScheduledTask -TaskPath "\*" | Select-Object TaskName, State, LastRunTime
            } -ArgumentList $ComputerName
            if ($OutputCSV) {
                $Tasks | Export-Csv -Path $OutputCSV -NoTypeInformation -Force
            }
            else {
                $Tasks
            }
        }
        catch {
            Write-Error -Message "Failed to retrieve scheduled tasks on $ComputerName : $_"
        }
    }
    END {
        if ($Session) {
            Remove-PSSession -Session $Session -ErrorAction SilentlyContinue -Verbose
        }
    }
}
