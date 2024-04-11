Function Invoke-RemoteVMsOperations {
    <#
    .SYNOPSIS
    Performs operations on Hyper-V virtual machines, including listing VMs, starting, stopping, and restarting VMs either locally or on a remote computer.

    .DESCRIPTION
    This function allows you to perform various operations on Hyper-V virtual machines. You can list VMs, start VMs, stop VMs, or restart VMs, operations can be executed either on the local machine or on a remote computer.

    .PARAMETER Action
    Action to be performed on the virtual machines, valid values are "List VMs", "Start VMs", "Stop VMs", and "Restart VMs".
    .PARAMETER VMName
    Name of the virtual machine(s) on which the action should be performed, it's optional for listing VMs and required for starting, stopping, or restarting VMs.
    .PARAMETER ComputerName
    Name of the remote computer where the VM operations should be executed, if not specified, the operations are performed on the local computer.
    .PARAMETER User
    Username for connecting to the remote computer, if ComputerName is specified, this parameter is required.
    .PARAMETER Pass
    Password for connecting to the remote computer, if ComputerName is specified, this parameter is required.

    .EXAMPLE
    Invoke-RemoteVMsOperations -Action 'List VMs' -Verbose
    Invoke-RemoteVMsOperations -Action 'List VMs' -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("List VMs", "Start VMs", "Stop VMs", "Restart VMs")]
        [string]$Action,

        [Parameter(Mandatory = $false)]
        [string[]]$VMName,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Pass
    )
    BEGIN {
        if (-not (Get-Module -ListAvailable -Name Hyper-V)) {
            Write-Warning -Message "Hyper-V module is not available. Please install the Hyper-V feature or module!"
            return
        }
    }
    PROCESS {
        $Credential = $null
        $Session = $null
        if ($ComputerName -ne $env:COMPUTERNAME) {
            if (-not $User -or -not $Pass) {
                $Credential = Get-Credential
            }
            else {
                $Credential = New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString $Pass -AsPlainText -Force))
            }
            Write-Verbose -Message "Connecting to remote computer '$ComputerName' with credentials"
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -SessionOption (New-PSSessionOption -OperationTimeout 600000)
        }
        $InvokeCommandScriptBlock = {
            param ($VMName, $Action)
            switch ($Action) {
                "List VMs" {
                    $VMs = Get-VM | Select-Object Name, State
                    Write-Host "Found $($VMs.Count) VM(s):"
                    $VMs | Format-Table -AutoSize
                }
                "Start VMs" {
                    $VMs = Get-VM -Name $VMName
                    Start-VM -VM $VMs -ErrorAction Stop
                    Write-Host "Virtual machine(s) '$($VMs.Name -join "', '")' started on $($env:COMPUTERNAME)"
                }
                "Stop VMs" {
                    $VMs = Get-VM -Name $VMName
                    Stop-VM -VM $VMs -Force -ErrorAction Stop
                    Write-Host "Virtual machine(s) '$($VMs.Name -join "', '")' stopped on $($env:COMPUTERNAME)"
                }
                "Restart VMs" {
                    $VMs = Get-VM -Name $VMName
                    Restart-VM -VM $VMs -Force -ErrorAction Stop
                    Write-Host "Virtual machine(s) '$($VMs.Name -join "', '")' restarted on $($env:COMPUTERNAME)"
                }
                default {
                    Write-Warning -Message "Invalid action. Use 'Start', 'Stop', 'Restart', or 'List'!"
                }
            }
        }
    }
    END {
        if ($Session) {
            Write-Verbose -Message "Executing remote command on '$ComputerName'"
            Invoke-Command -ScriptBlock $InvokeCommandScriptBlock -ArgumentList $VMName, $Action -Session $Session -ErrorAction Stop
            Write-Verbose -Message "Closing remote session..."
            Remove-PSSession $Session -Verbose
        }
        else {
            Write-Verbose -Message "Executing local command..."
            Invoke-Command -ScriptBlock $InvokeCommandScriptBlock -ArgumentList $VMName, $Action
        }
    }
}
