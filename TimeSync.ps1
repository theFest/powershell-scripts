Function TimeSync {
    <#
    .SYNOPSIS
    This function is syncing time.
    
    .DESCRIPTION
    This function starts Windows Time service. Creates a service if one is not present.
    After it sets it service to automatic by default, then resyncs time and outputs the results.

    .EXAMPLE
    TimeSync -StartupType Automatic

    .NOTES
    https://docs.microsoft.com/en-us/troubleshoot/windows-server/identity/time-synchronization-not-succeed-non-ntp
    #>
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [ValidateSet('Automatic', 'Boot', 'Disabled', 'Manual', 'System')]
        [string]$StartupType = 'Automatic'
    )
    BEGIN {
        if (!(Get-Service -Name W32Time -ErrorAction SilentlyContinue)) {
            Write-Output 'Service is missing, installing and starting.'
            Start-Process W32tm -ArgumentList " /register" -WindowStyle Hidden -Wait
            Net Start W32Time
        }
    }
    PROCESS {
        Write-Output 'Setting service to Automatic and syncing time.'
        Get-Service -Name W32Time | Set-Service -StartupType $StartupType
        Start-Process W32tm -ArgumentList " /resync /force" -WindowStyle Hidden -Wait  
        #^^ w32tm /config /manualpeerlist: NTP_server_IP_Address, 0x8 /syncfromflags: MANUAL
        #^^ net stop w32time
        #^^ net start w32time
        #^^ w32tm /resync
    }
    END {
        return W32tm /query /status
        Write-Output 'Time sync finished.'
    }
}