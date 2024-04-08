Function Remove-RemotePSDrive {
    <#
    .SYNOPSIS
    Removes a PSDrive from a remote computer.

    .DESCRIPTION
    This function removes a PSDrive from a remote computer using PowerShell remoting.

    .PARAMETER Name
    Specifies the name of the PSDrive.
    .PARAMETER ComputerName
    Specifies the name of the remote computer.
    .PARAMETER Username
    Username for authentication to the remote computer.
    .PARAMETER Pass
    Password for authentication to the remote computer.

    .EXAMPLE
    Remove-RemotePSDrive -Name "rPSD" -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string]$Username,
        
        [Parameter(Mandatory = $false)]
        [string]$Pass
    )
    BEGIN {
        $StartTime = Get-Date
        Write-Host "Script started at $StartTime" -ForegroundColor DarkCyan
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"
    }
    PROCESS {
        try {
            Write-Verbose -Message "Removing PSDrive $Name from $ComputerName"
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
            Invoke-Command -Session $Session -ScriptBlock {
                param($Name)
                Remove-PSDrive -Name $Name
            } -ArgumentList $Name -ErrorAction Stop      
        }
        catch {
            Write-Error -Message "Failed to remove PSDrive $Name from $ComputerName. $_"
        }
    }
    END {
        if ($Session) {
            Remove-PSSession -Session $Session -Verbose
        }
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
        $EndTime = Get-Date
        $ExecutionTime = New-TimeSpan -Start $StartTime -End $EndTime
        Write-Host "Total execution time: $($ExecutionTime.TotalSeconds) seconds" -ForegroundColor DarkCyan
    }
}
