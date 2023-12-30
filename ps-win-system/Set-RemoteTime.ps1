Function Set-RemoteTime {
    <#
    .SYNOPSIS
    Sets the system time on a remote computer.

    .DESCRIPTION
    This function allows setting the date and time on a remote machine using PowerShell remoting.

    .PARAMETER ComputerName
    Mandatory - specifies the name of the remote computer.
    .PARAMETER Username
    Mandatory - the username used to authenticate on the remote computer.
    .PARAMETER Pass
    Mandatory - the password corresponding to the provided username.
    .PARAMETER NewTime
    Mandatory -specifies the new date and time to be set on the remote computer.
    .PARAMETER ForceSync
    NotMandatory - indicates whether to force time synchronization immediately.
    .PARAMETER TimeoutSeconds
    NotMandatory - timeout duration for the remote operation in seconds, default is 30 seconds.

    .EXAMPLE
    Set-RemoteTime -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass" -NewTime "2025-12-31 11:59:00"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [string]$Pass,

        [Parameter(Mandatory = $true)]
        [ValidateScript({
                try {
                    [datetime]::ParseExact($_, 'yyyy-MM-dd HH:mm:ss', [System.Globalization.CultureInfo]::InvariantCulture)
                    $true
                }
                catch {
                    throw "Invalid date format. Please provide a valid date in the format 'yyyy-MM-dd HH:mm:ss'."
                }
            })]
        [string]$NewTime,

        [Parameter(Mandatory = $false)]
        [switch]$ForceSync,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 30
    )
    BEGIN {
        Write-Verbose -Message "Starting $($MyInvocation.MyCommand)"
        try {
            Test-WsMan -ComputerName $ComputerName -ErrorAction Stop
            Write-Host "Test-WsMan successful. WSMan connection is available" -ForegroundColor Green
        }
        catch {
            Write-Error -Message "Test-WsMan failed. Unable to establish WSMan connection to $ComputerName!"
            return
        }
        try {
            $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Cred = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Cred
        }
        catch {
            Write-Error -Message "Failed to establish a remote session, error: $_"
            return
        }
    }
    PROCESS {
        try {
            $ScriptBlock = {
                param($NewTime, $ForceSync, $TimeoutSeconds)     
                if ($ForceSync) {
                    w32tm /resync /force
                }
                else {
                    Set-Date $NewTime
                }
            }
            $Params = @{
                Session      = $Session
                ScriptBlock  = $ScriptBlock
                ArgumentList = $NewTime, $ForceSync, $TimeoutSeconds
            }
            Invoke-Command @Params
        }
        catch {
            Write-Error -Message "Failed to set time on the remote machine, error: $_"
            return
        }
    }
    END {
        if ($Session) {
            try {
                Remove-PSSession $Session -ErrorAction Stop
            }
            catch {
                Write-Error -Message "Failed to close the remote session, error: $_"
            }
        }
        if ($Cred) {
            $Cred = $null
            [System.GC]::Collect()
        }
        Write-Verbose -Message "Ending $($MyInvocation.MyCommand)"
    }
}
