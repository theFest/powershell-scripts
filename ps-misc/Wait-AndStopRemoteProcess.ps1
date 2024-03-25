Function Wait-AndStopRemoteProcess {
    <#
    .SYNOPSIS
    Connects to a remote computer and allows the user to select processes to stop.

    .DESCRIPTION
    This function connects to a remote computer using PowerShell remoting, retrieves a list of processes, and presents them to the user in an Out-GridView for selection. Selected processes are then stopped after a specified timeout.

    .PARAMETER ComputerName
    Specifies the name or IP address of the remote computer.
    .PARAMETER User
    Specifies the username for connecting to the remote computer.
    .PARAMETER Pass
    Specifies the password associated with the provided username.
    .PARAMETER TimeoutInSeconds
    Timeout duration (in seconds) for waiting before stopping the selected processes, default is 60 seconds.

    .EXAMPLE
    Wait-AndStopRemoteProcess -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -TimeoutInSeconds 60

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [string]$User,

        [Parameter(Mandatory = $true)]
        [string]$Pass,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutInSeconds = 60
    )
    try {
        $SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
        $Credential = New-Object -TypeName PSCredential -ArgumentList $User, $SecPass
        $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
        $RemoteProcesses = Invoke-Command -Session $Session -ScriptBlock {
            Get-Process | Select-Object -Property ProcessName, Id
        }
        if ($RemoteProcesses) {
            Write-Host "Processes found on remote computer '$ComputerName':"
            $SelectedProcesses = $RemoteProcesses | Out-GridView -Title "Select processes to stop" -OutputMode Multiple
            if ($null -eq $SelectedProcesses) {
                Write-Host "Process selection canceled. Exiting!" -ForegroundColor DarkYellow
                return
            }
            Start-Sleep -Seconds $TimeoutInSeconds
            foreach ($SelectedProcess in $SelectedProcesses) {
                Invoke-Command -Session $Session -ScriptBlock {
                    param($SelectedProcess)
                    Stop-Process -Id $using:SelectedProcess.Id -Force
                } -ArgumentList $SelectedProcess
            }
            Write-Host "Selected processes stopped after $TimeoutInSeconds seconds."
        }
        else {
            Write-Host "No processes found on remote computer '$ComputerName'."
        }
    }
    catch {
        Write-Error -Message "Error: $_"
    }
    finally {
        Remove-PSSession -Session $Session -Verbose
    }
}
