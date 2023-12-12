Function Invoke-RemoteScript {
    <#
    .SYNOPSIS
    Executes a script block on multiple remote computers using PowerShell remoting.
    
    .DESCRIPTION
    This function establishes a remote session on specified computers and executes the provided script block remotely.
    
    .PARAMETER TargetComputers
    Mandatory - specifies an array of target computer names.
    .PARAMETER Username
    Mandatory - the username used for remote authentication.
    .PARAMETER Pass
    Mandatory - the password used for remote authentication.
    .PARAMETER ScriptBlock
    Mandatory - script block to execute remotely on the target computers.
    .PARAMETER Authentication
    NotMandatory - specifies the authentication mechanism for the remote session.
    .PARAMETER EnableNetworkAccess
    NotMandatory - enables network access in the remote session, default: $true.
    .PARAMETER UseSSL
    NotMandatory - specifies whether to use SSL for the remote session.
    .PARAMETER LogPath
    NotMandatory - path to export a log file containing script execution details.
    
    .EXAMPLE
    Invoke-RemoteScript -TargetComputers "Server01", "Server02" -Username "Admin" -Pass "Password123" -ScriptBlock { Get-Service -Name "wuauserv" }
    
    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$TargetComputers,

        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [string]$Pass,

        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Default", "Basic", "Negotiate", "CredSSP")]
        [string]$Authentication = "Default",

        [Parameter(Mandatory = $false)]
        [bool]$EnableNetworkAccess = $true,

        [Parameter(Mandatory = $false)]
        [switch]$UseSSL = $false,

        [Parameter(Mandatory = $false)]
        [string]$LogPath
    )
    BEGIN {
        if ($LogPath) {
            $ScriptExecutionLog = @()
        }
        Write-Verbose -Message "Checking connectivity to target computers..."
        $OnlineComputers = $TargetComputers | Where-Object { Test-Connection -ComputerName $_ -Count 1 -Quiet }
        if ($OnlineComputers.Count -eq 0) {
            Write-Warning "No online computers found. Exiting..."
            return
        }
        Write-Verbose -Message "Testing WS-Management connectivity..."
        $OnlineComputers = $OnlineComputers | Where-Object {
            Test-WsMan -ComputerName $_ -ErrorAction SilentlyContinue
        }
    }
    PROCESS {
        foreach ($Computer in $OnlineComputers) {
            try {
                $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, (ConvertTo-SecureString -String $Pass -AsPlainText -Force)
                Write-Verbose -Message "Connecting to $Computer..."
                $RemoteSession = New-PSSession -ComputerName $Computer -Credential $Credential -EnableNetworkAccess:$EnableNetworkAccess -Authentication $Authentication -UseSSL:$UseSSL -ErrorAction Stop
                Write-Verbose -Message "Executing script block on $Computer..."
                $Result = Invoke-Command -Session $RemoteSession -ScriptBlock $ScriptBlock -ErrorAction Stop
                if ($LogPath) {
                    $logEntry = @{
                        ComputerName = $Computer
                        Status       = "Success"
                        Result       = $Result
                        Timestamp    = Get-Date
                    }
                    $ScriptExecutionLog += New-Object PSObject -Property $logEntry
                }
            }
            catch {
                $ErrorMessage = $_.Exception.Message
                Write-Warning -Message "Failed to execute script on $Computer : $ErrorMessage"
                if ($LogPath) {
                    $logEntry = @{
                        ComputerName = $Computer
                        Status       = "Failed"
                        ErrorMessage = $ErrorMessage
                        Timestamp    = Get-Date
                    }
                    $ScriptExecutionLog += New-Object PSObject -Property $logEntry
                }
            }
            finally {
                if ($RemoteSession) {
                    Write-Verbose -Message "Disconnecting and removing session on $Computer..."
                    Disconnect-PSSession -Session $RemoteSession -ErrorAction SilentlyContinue
                    Remove-PSSession -Session $RemoteSession -ErrorAction SilentlyContinue
                }
            }
        }
    }
    END {
        if ($LogPath) {
            $ScriptExecutionLog | Export-Csv -Path $LogPath -NoTypeInformation
            Write-Verbose -Message "Script execution log exported to $LogPath"
        }
    }
}
