Function Get-RemoteRules {
    <#
    .SYNOPSIS
    Retrieve firewall rules from a remote computer using WinRM.

    .DESCRIPTION
    This function retrieves firewall rules from a specified remote computer, it establishes a session, retrieves the firewall rules, and then closes the session.

    .PARAMETER ComputerName
    Mandatory - name of the remote computer from which to retrieve firewall rules.
    .PARAMETER Username
    Mandatory - username used for authentication to the remote computer.
    .PARAMETER Pass
    Mandatory - password associated with the provided username for authentication.

    .EXAMPLE
    Get-RemoteRules -ComputerName 'remote_computer' -Username 'remote_user' -Password 'remote_pass'

    .NOTES
    v0.0.1
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [string]$Pass
    )
    Write-Verbose -Message "Adding client machine to TrustedHosts"
    $CurrentTrustedHosts = Get-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction SilentlyContinue
    if ($null -eq $CurrentTrustedHosts) {
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value $ComputerName -Force
    }
    else {
        $ExistingValue = $CurrentTrustedHosts.Value
        if ($ExistingValue -notlike "*$ComputerName*") {
            Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$ExistingValue,$ComputerName" -Force
        }
    }
    try {
        $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
        $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
        $FirewallRules = Invoke-Command -Session $Session -ScriptBlock {
            Get-NetFirewallRule | Select-Object DisplayName, Action, Direction, Enabled
        }
        Remove-PSSession -Session $Session
        return $FirewallRules
    }
    finally {
        Write-Verbose -Message "Removing client machine from TrustedHosts"
        $CurrentTrustedHosts = Get-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction SilentlyContinue
        if ($null -ne $CurrentTrustedHosts) {
            $ExistingValue = $CurrentTrustedHosts.Value
            $NewValue = $ExistingValue -replace ",?$ComputerName", ""
            Set-Item WSMan:\localhost\Client\TrustedHosts -Value $NewValue -Force
        }
    }
}
