function Add-WifiProfile {
    <#
    .SYNOPSIS
    Adds a Wi-Fi profile to the system using netsh.

    .DESCRIPTION
    This function generates a Wi-Fi profile XML based on provided SSID, security mode, and password (if applicable), and adds it to the system using netsh wlan add profile.

    .EXAMPLE
    Add-WifiProfile -SSID "MyWiFiNetwork" -Pass "MyPassword"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (	
        [Parameter(Mandatory = $true, HelpMessage = "Specify the SSID (network name) of the Wi-Fi network")]
        [Alias("n")]
        [string]$SSID,
    
        [Parameter(Mandatory = $false, HelpMessage = "Security mode of the Wi-Fi network, values are 'WPA2PSK' or 'None'")]
        [Alias("m")]
        [ValidateSet("WPA2PSK", "None")]
        [string]$SecurityMode,
    
        [Parameter(Mandatory = $false, HelpMessage = "Password for the Wi-Fi network, optional if SecurityMode is 'None'")]
        [Alias("p")]
        [string]$Pass
    )
    if (!$Pass) {
        $SecurityMode = "None"
    }
    else {
        $SecurityMode = "WPA2PSK"
    }
    Write-Verbose -Message "Generating security configuration XML based on security mode..."
    $SecurityXml = switch ($SecurityMode) {
        "WPA2PSK" {
            @"
            <security>
                <authEncryption>
                    <authentication>WPA2PSK</authentication>
                    <encryption>AES</encryption>
                    <useOneX>false</useOneX>
                </authEncryption>
                <sharedKey>
                    <keyType>passPhrase</keyType>
                    <protected>false</protected>
                    <keyMaterial>$Pass</keyMaterial>
                </sharedKey>
            </security>
    "@
        }
        "None" {
    @"
            <security>
                <authEncryption>
                    <authentication>open</authentication>
                    <encryption>none</encryption>
                    <useOneX>false</useOneX>
                </authEncryption>
            </security>
    "@
        }
    }
    $ProfileFileName = "WiFiProfile.xml"
    $SSIDHex = ($SSID.ToCharArray() | ForEach-Object {'{0:X}' -f ([int]$_)}) -join ''
    $XmlContent = @"
    <?xml version="1.0"?>
    <WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
        <name>$SSID</name>
        <SSIDConfig>
            <SSID>
                <hex>$SSIDHex</hex>
                <name>$SSID</name>
            </SSID>
        </SSIDConfig>
        <connectionType>ESS</connectionType>
        <connectionMode>auto</connectionMode>
        <MSM>
    $SecurityXml
        </MSM>
    </WLANProfile>
"@
            $XmlContent > ($ProfileFileName)
            netsh wlan add profile filename="$ProfileFileName"
        }
    }
}
