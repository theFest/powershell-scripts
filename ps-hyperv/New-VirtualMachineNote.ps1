Function New-VirtualMachineNote {
    <#
    .SYNOPSIS
    Adds or replaces notes for a virtual machine.

    .DESCRIPTION
    This function adds or replaces notes for a specified virtual machine.

    .PARAMETER Name
    Mandatory - specifies the name of the virtual machine.
    .PARAMETER TargetComputer
    NotMandatory - target computer where the virtual machine resides.
    .PARAMETER Username
    NotMandatory - the username used for accessing the remote computer.
    .PARAMETER Pass
    NotMandatory - the password for accessing the remote computer.
    .PARAMETER Notes
    Mandatory - notes content to be added or replaced for specified VM.
    .PARAMETER Replace
    NotMandatory - to replace the existing notes, if not specified, the content is appended.

    .EXAMPLE
    New-VirtualMachineNote -Name "your_vm_name" -TargetComputer "remote_host" -Username "remote_user" -Pass "remote_pass" -Notes "new_notes" -Replace

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, HelpMessage = "Enter the name of the virtual machine")]
        [ValidateNotNullorEmpty()]
        [Alias("VMName")]
        [string]$Name,

        [Parameter(Mandatory = $false, HelpMessage = "Enter the target computer name")]
        [ValidateNotNullorEmpty()]
        [Alias("ComputerName")]
        [string]$TargetComputer = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Enter the username of remote computer")]
        [ValidateNotNullorEmpty()]
        [Alias("RunAs")]
        [string]$Username,

        [Parameter(Mandatory = $false, HelpMessage = "Enter the password of remote computer")]
        [ValidateNotNullorEmpty()]
        [Alias("SecurePassword")]
        [string]$Pass,

        [Parameter(Mandatory = $true, HelpMessage = "Enter notes content")]
        [ValidateNotNullorEmpty()]
        [string]$Notes,

        [Parameter(Mandatory = $false, HelpMessage = "Specify whether to replace the existing notes")]
        [switch]$Replace
    )
    BEGIN {
        Write-Verbose -Message "Starting: $($MyInvocation.MyCommand)"
        $Credential = $null
        if (-not ($Username -and $Pass)) {
            $Credential = Get-Credential -Message "Enter credentials for $Username"
        }
        else {
            $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePassword
        }
        $CIMSession = New-CimSession -ComputerName $TargetComputer -Credential $Credential
    }
    PROCESS {
        try {
            $VM = Get-CimInstance -Namespace "root/virtualization/v2" -ClassName "Msvm_ComputerSystem" -Filter "ElementName='$Name'"
            if ($VM) {
                Write-Host "Changing Note on: $($VM.ElementName)..." -ForegroundColor Green
                $CurrentNotes = Get-VM -Name $VM.ElementName | Select-Object -ExpandProperty Notes
                $NewNote = if ($Replace) {
                    Write-Verbose -Message "Replacing VM Note..."
                    $Notes
                }
                else {
                    Write-Verbose -Message "Appending VM Note..."
                    $CurrentNotes + "`n$Notes"
                }
                Set-VM -Name $VM.ElementName -Notes $NewNote -Verbose
            }
            else {
                Write-Warning -Message "No VM found with the name '$Name'!"
            }
        }
        catch {
            Write-Warning -Message "Failed to find or process running virtual machines on $TargetComputer. $_"
        }
    }
    END {
        Write-Verbose -Message "Ending: $($MyInvocation.MyCommand)"
        if ($CIMSession) {
            Remove-CimSession -CimSession $CIMSession -Verbose
        }
    }
}
