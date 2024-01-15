Function Set-RemoteDNSConfig {
    <#
    .SYNOPSIS
    Change DNS settings on remote computers.

    .DESCRIPTION
    This function changes the DNS settings on specified remote computers for adapters that are currently up, allows modifying the PrimaryDNS and SecondaryDNS for the specified network adapters.

    .PARAMETER PrimaryDNS
    Specifies the primary DNS address to be set.
    .PARAMETER SecondaryDNS
    Specifies the secondary DNS address to be set.
    .PARAMETER ComputerName
    Specifies the name of the remote computer, defaults to the local computer if not provided.
    .PARAMETER User
    Specifies the username for remote access.
    .PARAMETER Pass
    Specifies the password for remote access.

    .EXAMPLE
    Set-RemoteDNSConfig -PrimaryDNS "1.1.1.1" -SecondaryDNS "8.8.8.8" -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$PrimaryDNS,

        [Parameter(Mandatory = $false)]
        [string]$SecondaryDNS,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Pass
    )
    BEGIN {
        if ($ComputerName -and $User -and $Pass) {
            $SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecPass
        }
    }
    PROCESS {
        $Results = foreach ($Adapter in (Invoke-Command -ComputerName $ComputerName -Credential $Credentials -ScriptBlock {
                    Get-NetAdapter | Where-Object Status -eq 'Up'
                })) {
            $Result = [PSCustomObject]@{
                AdapterName     = $Adapter.Name
                DNSChangeStatus = "No change"
            }
            try {
                $DnsServers = Invoke-Command -ComputerName $ComputerName -Credential $Credentials -ScriptBlock {
                    (Get-NetIPConfiguration -InterfaceIndex $args[0].ifIndex -ErrorAction Stop).DNSServer.ServerAddresses
                } -ArgumentList $Adapter
                Write-Host ("Retrieved DNS settings for adapter {0} on {1}" -f $Adapter.Name, $ComputerName)
            }
            catch {
                Write-Warning -Message ("Could not retrieve DNS settings for adapter {0} on {1}" -f $Adapter.Name, $ComputerName)
                continue
            }
            if ($DnsServers -notcontains $PrimaryDNS -or $DnsServers -notcontains $SecondaryDNS) {
                try {
                    $WmiParams = @{
                        Class        = "Win32_NetworkAdapterConfiguration"
                        ComputerName = $ComputerName
                        Credential   = $Credentials
                        ErrorAction  = 'Stop'
                    }
                    $AdapterConfig = Get-WmiObject @WmiParams | Where-Object { $_.InterfaceIndex -eq $Adapter.ifIndex }
                    $AdapterConfig.SetDNSServerSearchOrder(@($PrimaryDNS, $SecondaryDNS))
                    $Result.DNSChangeStatus = "Changed"
                    Write-Host ("Changing DNS settings for {0} to {1} and {2} (Previous setting was {3}) on {4}" -f $Adapter.Name, $PrimaryDNS, $SecondaryDNS, $($DnsServers -join ', '), $ComputerName) -ForegroundColor Green
                }
                catch {
                    Write-Warning -Message ("Error changing DNS settings for adapter {0} on {1}" -f $Adapter.Name, $ComputerName)
                    $Result.DNSChangeStatus = "Error"
                }
            }
            else {
                $Result.DNSChangeStatus = "Skipped"
                Write-Host ("Adapter {0} already has {1} and {2} configured on {3}, skipping..." -f $adapter.Name, $PrimaryDNS, $SecondaryDNS, $ComputerName) -ForegroundColor Yellow
            }
            $Result
        }
    }
    END {
        $Results | Format-Table -AutoSize
    }
}
