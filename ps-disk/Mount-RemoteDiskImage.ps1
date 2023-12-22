#Requires -Version 5.1
Function Mount-RemoteDiskImage {
    <#
    .SYNOPSIS
    Mounts a disk image on a remote computer without assigning a drive letter.

    .DESCRIPTION
    This function mounts a disk image file on a specified remote computer without assigning a drive letter to the mounted image.

    .PARAMETER ImagePath
    Mandatory - specifies the path to the disk image file.
    .PARAMETER StorageType
    NotMandatory - type of storage for the disk image file, valid values are "ISO", "VHD", or "VHDX".
    .PARAMETER ComputerName
    Mandatory - name of the remote computer where the image will be mounted.
    .PARAMETER Username
    Mandatory - the username to access the remote computer.
    .PARAMETER Pass
    Mandatory - the password associated with the provided username.

    .EXAMPLE
    Mount-RemoteDiskImage -ImagePath "C:\remote_path\remote_image.iso" -StorageType ISO -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ImagePath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("ISO", "VHD", "VHDX")]
        [string]$StorageType = "ISO",

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
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
            Invoke-Command -Session $Session -ScriptBlock {
                param($ImagePath, $StorageType)
                if (-not (Test-Path -Path $ImagePath -PathType Leaf)) {
                    throw "Image file not found at $ImagePath"
                }
                Mount-DiskImage -ImagePath $ImagePath -StorageType $StorageType -PassThru -Verbose
                Write-Host "Image mounted successfully" -ForegroundColor Green
            } -ArgumentList $ImagePath, $StorageType
        }
        catch {
            Write-Error -Message "Error: $_"
        }
        finally {
            if ($Session) {
                Remove-PSSession $Session -Verbose
            }
        }
    }
}
