Function New-UDPListener {
    <#
    .SYNOPSIS
    Creates a new UDP listener on the specified port and listens for incoming UDP datagrams for a specified duration.

    .DESCRIPTION
    This function creates a UDP listener on the specified port and listens for incoming UDP datagrams. It allows setting a timeout for how long the listener will wait for incoming datagrams.

    .PARAMETER UDPPort
    Mandatory - specifies the UDP port on which the listener will be created. The port must be within the valid range of 0 to 65535.
    .PARAMETER Timeout
    NotMandatory - duration for which the listener will wait for incoming datagrams, timeout can be customized by providing a TimeSpan value, for example, '00:10:00' for 10 minutes.
    
    .EXAMPLE
    New-UDPListener -UDPPort 67
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Enter the UDP port you want to use to listen on, for example 5000")]
        [ValidateRange(0, 65535)]
        [int]$UDPPort,
        
        [Parameter(Mandatory = $false, HelpMessage = "Enter the duration for how long to listen (e.g., '00:05:00' for 5 minutes)")]
        [ValidateScript({ $_ -as [TimeSpan] })]
        [TimeSpan]$Timeout = [TimeSpan]::FromMinutes(5)
    )
    $Global:ProgressPreference = 'SilentlyContinue'
    try {
        $UDPObject = New-Object System.Net.Sockets.Udpclient($UDPPort)
        $Computername = "localhost"
        $UDPObject.Connect($Computername, $UDPPort)    
        $ASCIIEncoding = New-Object System.Text.ASCIIEncoding
        $Bytes = $ASCIIEncoding.GetBytes("$(Get-Date -UFormat "%Y-%m-%d %T")")
        [void]$UDPObject.Send($Bytes, $Bytes.length)    
        $UDPObject.Close()
        Write-Host ("UDP port {0} is available, continuing..." -f $UDPPort) -ForegroundColor Green
    }
    catch {
        Write-Warning -Message ("UDP Port {0} is already listening, aborting..." -f $UDPPort)
        return
    }
    $Endpoint = New-Object System.Net.IPEndPoint([IPAddress]::Any, $UDPPort)
    $UDPClient = New-Object System.Net.Sockets.UdpClient $UDPPort
    Write-Host ("Now listening on UDP port {0}, press Escape or wait for timeout to stop listening" -f $UDPPort) -ForegroundColor Green
    $StartTime = Get-Date
    while ((Get-Date) -lt ($StartTime + $Timeout)) {
        if ($host.ui.RawUi.KeyAvailable) {
            $Key = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp,IncludeKeyDown")
            if ($Key.VirtualKeyCode -eq 27) {	
                $UDPClient.Close()
                Write-Host ("Stopped listening on UDP port {0}" -f $UDPPort) -ForegroundColor Green
                return
            }
        }
        if ($UDPClient.Available) {
            $Content = $UDPClient.Receive([ref]$Endpoint)
            Write-Host "$($Endpoint.Address.IPAddressToString):$($Endpoint.Port) $([Text.Encoding]::ASCII.GetString($Content))"
        }
    }
    $UDPClient.Close()
    Write-Host ("Timeout reached. Stopped listening on UDP port {0}" -f $UDPPort) -ForegroundColor Yellow
}
