#Requires -Version 5.1
Function Dismount-RemoteDiskImage {
    <#
    .SYNOPSIS
    Dismounts a remote disk image using PowerShell.

    .DESCRIPTION
    This function dismounts a disk image on a remote computer using the Dismount-DiskImage cmdlet.

    .PARAMETER DevicePath
    Mandatory - specifies the device path of the disk image to be dismounted.
    .PARAMETER ComputerName
    Mandatory - name of the remote computer where the disk image will be dismounted.
    .PARAMETER Username
    Mandatory - username used to authenticate on the remote computer.
    .PARAMETER Pass
    Mandatory - password used to authenticate on the remote computer.

    .EXAMPLE
    Dismount-RemoteDiskImage -DevicePath "\\.\CDROM1" -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DevicePath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Pass
    )
    PROCESS {
        try {
            $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePassword
            $RemoteSession = New-PSSession -ComputerName $ComputerName -Credential $Credential
            Invoke-Command -Session $RemoteSession -ScriptBlock {
                param($DevicePath)
                Dismount-DiskImage -DevicePath $DevicePath -ErrorAction Stop -Verbose
            } -ArgumentList $DevicePath
        }
        catch {
            Write-Error -Message "Error: $_"
        }
        finally {
            if ($RemoteSession) {
                Remove-PSSession $RemoteSession -Verbose
            }
        }
    }
}
