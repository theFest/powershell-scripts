#Requires -Version 4.0
Function Set-DNS {
    <#
    .SYNOPSIS
    This function is used to set DNS.

    .DESCRIPTION
    This function is used to set DNS using WMI method for Windows 7 compatibility.

    .PARAMETER ConnectionType
    Mandatory - the type of connection to target for DNS configuration.
    .PARAMETER AdapterSNm
    Mandatory - the manufacturer of the adapter to target for DNS configuration.
    .PARAMETER PrimaryDNS
    Mandatory - the preferred DNS server.
    .PARAMETER SecondaryDNS
    Mandatory - the alternate DNS server (fail-safe).
    .PARAMETER FlushDNS
    NotMandatory - whether to flush the DNS cache after configuration.
    .PARAMETER RegisterDNS
    NotMandatory - whether to register the DNS settings after configuration.
    .PARAMETER IpConfigAll
    NotMandatory - whether to display the IP configuration details after configuration.

    .EXAMPLE
    Set-DNS -ConnectionType LAN -PrimaryDNS 1.1.1.1 -SecondaryDNS 8.8.8.8 -IpConfigAll

    .NOTES
    Version: 0.0.4
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("LAN", "WAN", "VPN", "WiFi", "Ethernet", "ServiceName", "All")]
        [string]$ConnectionType,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Enter a partial adapter name to filter by manufacturer")]
        [ValidateSet("RTL*", "Intel*", "Broadcom*", "Qualcomm*", "Marvell*", "VIA*", "All")]
        [string]$AdapterSNm,

        [Parameter(Mandatory = $true, HelpMessage = "IP address of the preferred DNS server")]
        [ipaddress]$PrimaryDNS,

        [Parameter(Mandatory = $true, HelpMessage = "IP address of the alternate DNS server")]
        [ipaddress]$SecondaryDNS,

        [Parameter(Mandatory = $false, HelpMessage = "flush the DNS cache after configuration.")]
        [switch]$FlushDNS,

        [Parameter(Mandatory = $false, HelpMessage = "register DNS settings after configuration")]
        [switch]$RegisterDNS,

        [Parameter(Mandatory = $false, HelpMessage = "display IP configuration details after configuration")]
        [switch]$IpConfigAll
    )
    $Adapters = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IpEnabled = $true"
    switch ($ConnectionType) {
        "LAN" {
            $Adapters = $Adapters | Where-Object {
                $_.IPAddress -match "^(192\.168\.|172\.|10\.)"
            }
        }
        "WAN" {
            $Adapters = $Adapters | Where-Object {
                $_.IPAddress -notmatch "^(192\.168\.|172\.|10\.)"
                Write-Host "n/a { route }" -ForegroundColor DarkMagenta
            }
        }
        "VPN" {
            $Adapters = $Adapters | Where-Object {
                $_.Description -match "VPN"
            }
        }
        "WiFi" {
            $Adapters = $Adapters | Where-Object {
                $_.NetConnectionID -match "Wi-Fi"
            }
        }
        "Ethernet" {
            $Adapters = $Adapters | Where-Object {
                $_.NetConnectionID -match "Ethernet"
            }
        }
        "ServiceName" {
            if ($AdapterSNm) {
                $Adapters = $Adapters | Where-Object {
                    $_.ServiceName -like $AdapterSNm
                }
            }
        }
        "All" {
            Write-Host "implementation ongoing..." -ForegroundColor DarkGreen
        }
        default {
            throw "Invalid ConnectionType value"
        }
    }
    foreach ($Adapter in $Adapters) {
        $Adapter.DNSServerSearchOrder = @($PrimaryDNS, $SecondaryDNS)
        $Adapter.SetDynamicDNSRegistration($true)
    }
    if ($FlushDNS) {
        Write-Verbose -Message "Flushing DNS cache..."
        ipconfig /flushdns | Out-Null
        Clear-DnsClientCache -Verbose -ErrorAction SilentlyContinue
    }
    if ($RegisterDNS) {
        Write-Verbose -Message "Registering DNS..."
        ipconfig /registerdns | Out-Null
        Register-DnsClient -Verbose -ErrorAction SilentlyContinue
    }
    if ($IpConfigAll) {
        Write-Verbose -Message "Results..."
        ipconfig /all | Out-Host
    }
}
