Function SetDNS {
    <#
    .SYNOPSIS
    This function is used to set DNS.

    .DESCRIPTION
    This function is used to set DNS using WMI method for Windows 7 compatibility.

    .PARAMETER ConnectionType
    Mandatory - choose connection type.
    .PARAMETER AdapterSNm
    Mandatory - adapter manufacturer.
    .PARAMETER PrimaryDNS
    Mandatory - preferred DNS server.
    .PARAMETER SecondaryDNS
    Mandatory - alternate DNS server(fail-safe).
    .PARAMETER FlushDNS
    NotMandatory - switch FlushDNS.
    .PARAMETER RegisterDNS
    NotMandatory - switch RegisterDNS.
    .PARAMETER IpConfigAll
    PNotMandatory - output results.

    .EXAMPLE
    SetDNS -ConnectionType LAN -PrimaryDNS 1.1.1.1 -SecondaryDNS 8.8.8.8 -IpConfigAll

    .NOTES
    v0.3.2
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateSet("LAN", "WAN", "VPN", "WiFi", "Ethernet", "ServiceName", "All")]
        [string]$ConnectionType = "LAN",

        [Parameter(Mandatory = $false)]
        [ValidateSet("RTL*", "Intel*", "Broadcom*", "Qualcomm*", "Marvell*", "VIA*", "All")]
        [string]$AdapterSNm = "",

        [Parameter(Mandatory = $true)]
        [ipaddress]$PrimaryDNS,

        [Parameter(Mandatory = $true)]
        [ipaddress]$SecondaryDNS,

        [Parameter()]
        [switch]$FlushDNS,

        [Parameter()]
        [switch]$RegisterDNS,

        [Parameter()]
        [switch]$IpConfigAll
    )
    $Adapters = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IpEnabled = $true"
    switch ($ConnectionType) {
        "LAN" {
            $Adapters = $Adapters | Where-Object {
                $_.IPAddress -like "192.168.*" `
                    -or $_.IPAddress -like "172.*.*.*" `
                    -or $_.IPAddress -like "10.*.*.*"
            }
        }
        "WAN" {
            $Adapters = $Adapters | Where-Object {
                $_.IPAddress -notlike "192.168.*" `
                    -and $_.IPAddress -like "172.*.*.*" `
                    -and $_.IPAddress -notlike "10.*.*.*"
                Write-Host "n/a { route }" -ForegroundColor DarkMagenta
            }
        }
        "VPN" {
            $Adapters = $Adapters | Where-Object {
                $_.Description -match "VPN"
            }
        }
        "WiFi" {
            $Adapters = Get-NetAdapter -Physical `
            | Where-Object { $_.MediaType -eq '802.11' }
        }
        "Ethernet" {
            $Adapters = Get-NetAdapter -Physical `
            | Where-Object { $_.MediaType -eq '802.3' }
        }
        "ServiceName" {
            $Adapters = $Adapters | Where-Object {
                $_.ServiceName -match $AdapterSNm
            }
        }
        "All" {
            Write-Host "implementation ongoing..." -ForegroundColor DarkGreen
        }
        default {
            throw "Invalid ConnectionType value"
        }
    }
    $Adapters | ForEach-Object {
        $AbOut = @{
            "Adapter"             = $_
            "DNSServer"           = $_.DNSServerSearchOrder
            "FullDNSRegistration" = $_.FullDNSRegistrationEnabled
        }
        return $AbOut
    }
    $ServersDNS = $PrimaryDNS, $SecondaryDNS
    $Adapters.SetDNSServerSearchOrder($ServersDNS)
    $Adapters.SetDynamicDNSRegistration($true)
    if ($FlushDNS) {
        Write-Verbose -Message "Flushing DNS cache..."
        ipconfig /flushdns | Out-Null
    }
    if ($RegisterDNS) {
        Write-Host "Registering DNS..."
        ipconfig /registerdns | Out-Null
    }
    if ($IpConfigAll) {
        Write-Host "Registering DNS..."
        ipconfig /all | Out-Host
    }
}
