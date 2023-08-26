Function Set-DNS {
    <#
    .SYNOPSIS
    Set DNS servers for network adapters using WMI method.

    .DESCRIPTION
    This function sets DNS servers for network adapters using the Win32_NetworkAdapterConfiguration class.

    .PARAMETER DNSPrimary
    Mandatory - Preferred DNS server.
    .PARAMETER DNSSecondary
    Mandatory - Alternate DNS server (fail-safe).
    .PARAMETER Adapter
    Mandatory - Name of the network adapter. Use 'Ethernet' to target physical adapters, or leave empty for all adapters.

    .EXAMPLE
    Set-DNS -DNSPrimary "8.8.8.8" -DNSSecondary "9.9.9.9" -Adapter "Ethernet"

    .NOTES
    Version: 0.3.5
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, HelpMessage = "primary DNS server")]
        [ipaddress]$DNSPrimary,

        [Parameter(Mandatory = $true, HelpMessage = "secondary DNS server")]
        [ipaddress]$DNSSecondary,

        [Parameter(Mandatory = $true, HelpMessage = "action to perform")]
        [ValidateSet(
            "Ethernet",
            "Local Area Connection",
            "*",
            "Wireless",
            "VPN",
            "Bluetooth",
            "Mobile Broadband",
            "Tunnel",
            "Loopback",
            "Virtual",
            "VLAN",
            "Team",
            "Aggregate",
            "WAN Miniport",
            "ISATAP",
            "Teredo"
        )]
        [string]$Adapter
    )
    $Query = "SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled = 'True'"   
    if ($Adapter -eq "Ethernet") {
        $Query += " AND MACAddress IS NOT NULL"
    }   
    $NetworkAdapters = Get-WmiObject -Query $Query   
    foreach ($NetworkAdapter in $NetworkAdapters) {
        $DNS_Servers = $DNSPrimary, $DNSSecondary
        $NetworkAdapter | ForEach-Object {
            $_.SetDNSServerSearchOrder($DNS_Servers)
            $_.SetDynamicDNSRegistration($true)
        }
    }  
    try {
        Write-Output "Flushing and registering DNS."
        $FlushDnsProcess = Start-Process -FilePath "ipconfig" -ArgumentList "/flushdns" -PassThru -Wait -NoNewWindow
        if ($FlushDnsProcess.ExitCode -ne 0) {
            throw "Failed to flush DNS cache."
        }
        $RegisterDnsProcess = Start-Process -FilePath "ipconfig" -ArgumentList "/registerdns" -PassThru -Wait -NoNewWindow
        if ($RegisterDnsProcess.ExitCode -ne 0) {
            throw "Failed to register DNS."
        }
        Write-Output "DNS cache flushed and registered successfully."
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "DNS maintenance completed." -ForegroundColor Cyan
    }
}
