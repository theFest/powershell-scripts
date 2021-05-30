Function SetDNS {
    <#
    .SYNOPSIS
    This function is used to set DNS.
    
    .DESCRIPTION
    This function is used to set DNS using WMI method for Windows 7 compatibility.

    .PARAMETER DNSprimary
    Mandatory - preferred DNS server.
    .PARAMETER DNSsecondary
    Mandatory - alternate DNS server(fail-safe).

    .EXAMPLE
    SetDNS -DNSprimary 8.8.8.8 -DNSsecondary 9.9.9.9
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$DNSprimary,

        [Parameter(Mandatory = $true)]
        [string]$DNSsecondary
    )
    Write-Output -InputObject 'Unable to reach S3, setting DNS.'
    #WriteLog -LogMessage "Unable to reach S3, setting DNS." -LogSeverity Information
    $DNS_Servers = $DNSprimary, $DNSsecondary
    $Set_DNS = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IpEnabled = $true" | `
    Where-Object { $_.ServiceName -match 'RTL*' }
    $Set_DNS.SetDNSServerSearchOrder($DNS_Servers)
    $Set_DNS.SetDynamicDNSRegistration($true)
    #WriteLog -LogMessage "Flushing and registering DNS." -LogSeverity Information
    Write-Output -InputObject 'Flushing and registering DNS.'
    Start-Process cmd -ArgumentList " /c ipconfig /flushdns" -Wait -WindowStyle Hidden
    Start-Process cmd -ArgumentList " /c ipconfig /registerdns" -Wait -WindowStyle Hidden
}