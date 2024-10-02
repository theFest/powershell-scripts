function Add-VirtualMachineNote {
    <#
    .SYNOPSIS
    Adds or replaces notes for a virtual machine.

    .DESCRIPTION
    This function adds or replaces notes for a specified virtual machine, it can also target a local or remote computer, using provided credentials if necessary.

    .EXAMPLE
    Add-VirtualMachineNote -VmName "your_local_vm" -Notes "your_new_note" -Verbose
    Add-VirtualMachineNote -VmName "your_remote_vm" -ComputerName "remote_hostname" -User "remote_username" -Pass "remote_password" -Notes "your_new_remote_note"

    .NOTES
    v0.0.8
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, HelpMessage = "Specifies the name of the virtual machine")]
        [ValidateNotNullOrEmpty()]
        [Alias("v")]
        [string]$VmName,

        [Parameter(Mandatory = $false, HelpMessage = "Target computer where the virtual machine resides, defaults to the local computer")]
        [ValidateNotNullOrEmpty()]
        [Alias("c")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Username for accessing the remote computer. If not specified, the function prompts for credentials if the remote computer is targeted")]
        [ValidateNotNullOrEmpty()]
        [Alias("u")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for accessing the remote computer. If not specified, the function prompts for credentials")]
        [ValidateNotNullOrEmpty()]
        [Alias("p")]
        [string]$Pass,

        [Parameter(Mandatory = $true, HelpMessage = "Content of the notes to be added or replaced for the virtual machine")]
        [ValidateNotNullOrEmpty()]
        [Alias("n")]
        [string]$Notes,

        [Parameter(Mandatory = $false, HelpMessage = "Replace the existing notes. If not specified, the content is appended to the current notes")]
        [Alias("rp")]
        [switch]$Replace
    )
    BEGIN {
        Write-Verbose -Message "Initializing: $($MyInvocation.MyCommand)"
        try {
            $Credential = $null
            if ($ComputerName -ne $env:COMPUTERNAME) {
                if (-not ($User -and $Pass)) {
                    $Credential = Get-Credential -Message "Enter credentials for $ComputerName"
                }
                else {
                    $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
                    $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecurePassword
                }
            }
            $CIMSession = New-CimSession -ComputerName $ComputerName -Credential $Credential
        }
        catch {
            Write-Error -Message "Failed to establish connection to $ComputerName : $_"
            return
        }
    }
    PROCESS {
        try {
            $VM = Get-CimInstance -CimSession $CIMSession -Namespace "root/virtualization/v2" -ClassName "Msvm_ComputerSystem" -Filter "ElementName='$VmName'"
            if ($VM) {
                Write-Host "Updating notes for virtual machine: $($VM.ElementName)" -ForegroundColor Green
                $CurrentNotes = (Get-VM -Name $VM.ElementName).Notes
                $DateTime = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]"
                $NewNote = if ($Replace) {
                    Write-Verbose -Message "Replacing the existing notes..."
                    "$DateTime $Notes"
                }
                else {
                    Write-Verbose -Message "Appending new notes..."
                    if ($CurrentNotes) {
                        "$CurrentNotes `n$DateTime $Notes"
                    }
                    else {
                        "$DateTime $Notes"
                    }
                }
                if ($PSCmdlet.ShouldProcess($VM.ElementName, "Update VM Notes")) {
                    Set-VM -Name $VM.ElementName -Notes $NewNote -Verbose
                    Write-Host "Notes updated successfully." -ForegroundColor Green
                }
            }
            else {
                Write-Warning -Message "No virtual machine found with the name '$VmName'."
            }
        }
        catch {
            Write-Warning -Message "Failed to update notes for VM '$VmName': $_"
        }
    }
    END {
        Write-Verbose -Message "Cleaning up: $($MyInvocation.MyCommand)"
        if ($CIMSession) {
            Remove-CimSession -CimSession $CIMSession -Verbose
        }
    }
}
