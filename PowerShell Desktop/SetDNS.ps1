Function SetDNS {
    <#
    .SYNOPSIS
    This function is used to set DNS.

    .DESCRIPTION
    This function is used to set DNS using WMI method for Windows 7 compatibility.

    .PARAMETER ConnectionType
    Mandatory - choose connection type.
    .PARAMETER PrimaryDNS
    Mandatory - preferred DNS server.
    .PARAMETER SecondaryDNS
    Mandatory - alternate DNS server(fail-safe).

    .EXAMPLE
    SetDNS -ConnectionType LAN -PrimaryDNS 1.1.1.1 -SecondaryDNS 8.8.8.8
    SetDNS -ConnectionType WAN -PrimaryDNS 8.8.8.8 -SecondaryDNS 1.0.0.1
    SetDNS -ConnectionType VPN -PrimaryDNS 9.9.9.9 -SecondaryDNS 8.8.4.4
    SetDNS -ConnectionType WiFi -PrimaryDNS 149.112.112.112 -SecondaryDNS 208.67.220.220
    SetDNS -ConnectionType Ethernet -PrimaryDNS 208.67.222.222 -SecondaryDNS 8.26.56.26

    .NOTES
    v0.3.1
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateSet("LAN", "WAN", "VPN", "WiFi", "Ethernet", "All")]
        [string]$ConnectionType = "LAN",

        [Parameter(Mandatory = $true)]
        [ipaddress]$PrimaryDNS,

        [Parameter(Mandatory = $true)]
        [ipaddress]$SecondaryDNS
    )
    $Adapters = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IpEnabled = $true"
    switch ($ConnectionType) {
        "LAN" {
            $Adapters = $Adapters | Where-Object {
                $_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*.*.*"
            }
        }
        "WAN" {
            $Adapters = $Adapters | Where-Object {
                $_.IPAddress -notlike "192.168.*" -and $_.IPAddress -notlike "10.*.*.*"
                Write-Host "n/a { route }" -ForegroundColor DarkMagenta
            }
        }
        "VPN" {
            $Adapters = $Adapters | Where-Object {
                $_.Description -match "VPN"
            }
        }
        "WiFi" {
            $Adapters = Get-NetAdapter -Physical | Where-Object { $_.MediaType -eq '802.11' }
        }
        "Ethernet" {
            $Adapters = Get-NetAdapter -Physical | Where-Object { $_.MediaType -eq '802.3' }
        }
        "All" {
            Write-Host "implementation ongoing..." -ForegroundColor DarkGreen
        }
        default {
            throw "Invalid ConnectionType value"
        }
    }
    $ServersDNS = $PrimaryDNS, $SecondaryDNS
    $Adapters.SetDNSServerSearchOrder($ServersDNS)
    $Adapters.SetDynamicDNSRegistration($true)
    Write-Verbose -Message "Flushing and registering DNS..."
    Start-Process cmd -ArgumentList " /c ipconfig /flushdns" -Wait -WindowStyle Hidden
    Start-Process cmd -ArgumentList " /c ipconfig /registerdns" -Wait -WindowStyle Hidden
}
