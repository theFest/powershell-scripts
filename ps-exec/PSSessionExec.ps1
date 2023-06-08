Function PSSessionExec {
    <#
    .SYNOPSIS
    Establishes PowerShell sessions to remote computers and executes a specified script block within those sessions.

    .DESCRIPTION
    This function function allows you to remotely execute a script block on multiple computers. It establishes a PowerShell session with each specified computer, securely authenticates using the provided username and password, and then invokes the given script block within each session. The function handles checking the online status of the computers, testing WS-Management connectivity, and disconnecting and removing the sessions after execution.

    .PARAMETER ComputerName
    Mandatory - array of computer names to establish PowerShell sessions with. The function checks if the computers are online by performing a ping test before establishing sessions.
    .PARAMETER Username
    Mandatory - username to authenticate with when establishing the PowerShell sessions.
    .PARAMETER Pass
    Mandatory - password to authenticate with when establishing the PowerShell sessions. The password is securely stored as a secure string.
    .PARAMETER ScriptBlock
    Mandatory - script block to be executed within each PowerShell session. The script block can contain any valid PowerShell commands.
    .PARAMETER Authentication
    NotMandatory - authentication mechanism to use when establishing the PowerShell sessions, available options are "Default", "Basic", "Negotiate", and "CredSSP".
    .PARAMETER EnableNetworkAccess
    NotMandatory - enable network access within the PowerShell sessions. By default, network access is enabled.
    .PARAMETER UseSSL
    NotMandatory - use SSL encryption when establishing the PowerShell sessions. By default, SSL is not used.
        
    .EXAMPLE
    PSSessionExec -ComputerName "remote_pc1", "remote_pc2" -Username "remote_user" -Pass "remote_pass" -ScriptBlock { Stop-Service -Name Spooler -Force } -Verbose
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ComputerName,

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
        [switch]$UseSSL = $false
    )
    BEGIN {
        Write-Verbose -Message "Checking if the computers are online"
        $OnlineComputers = @()
        foreach ($Computer in $ComputerName) {
            if (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
                $OnlineComputers += $Computer
                Write-Host "Ping test succeeded for $Computer" -ForegroundColor Green
            }
            else {
                Write-Warning -Message "Ping failed for $Computer!"
            }
        }
        if ($OnlineComputers.Count -eq 0) {
            Write-Warning -Message "No online computers found. Exiting..."
            return
        }
        Write-Verbose -Message "Testing WS-Management connectivity"
        foreach ($Computer in $OnlineComputers) {
            try {
                Test-WsMan -ComputerName $Computer -ErrorAction Stop | Out-Null
                Write-Host "WS-Man test succeeded for $Computer" -ForegroundColor Green
            }
            catch {
                Write-Warning -Message "WS-Management connectivity test failed for $Computer!"
                $OnlineComputers = $OnlineComputers | Where-Object { $_ -ne $Computer }
            }
        }
    }
    PROCESS {
        foreach ($Computer in $OnlineComputers) {
            $Session = $null
            try {
                Write-Verbose -Message "Securing creds and crafting PSCredential object..."
                $SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
                $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecPass
                Write-Verbose -Message "Creating a new session and invoking the script block within the session..."
                $Session = New-PSSession -ComputerName $Computer -Credential $Credential -EnableNetworkAccess:$EnableNetworkAccess -Authentication $Authentication -UseSSL:$UseSSL
                Invoke-Command -Session $Session -ScriptBlock $ScriptBlock
            }
            catch {
                throw $_
            }
            finally {
                Write-Verbose -Message "Disconnecting and removing the session"
                if ($Session) {
                    if ($Session.State -eq "Opened") {
                        Disconnect-PSSession -Session $Session -ErrorAction SilentlyContinue
                    }
                    Remove-PSSession -Session $Session
                }
            }
        }
    }
}
