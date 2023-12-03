Function New-TCPListener {
    <#
    .SYNOPSIS
    Creates a new TCP listener on the specified port and listens for incoming connections for a specified duration.

    .DESCRIPTION
    This function creates a TCP listener on the specified port and listens for incoming connections. It provides the ability to set a timeout for how long the listener will wait for connections.

    .PARAMETER TCPPort
    Mandatory - specifies the TCP port on which the listener will be created. The port must be within the valid range of 0 to 65535.
    .PARAMETER Timeout
    NotMandatory - duration for which the listener will wait for incoming connections, timeout can be customized by providing a TimeSpan value, for example, '00:10:00' for 10 minutes.
    
    .EXAMPLE
    New-TCPListener -TCPPort 80
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Enter the TCP port you want to use to listen on, for example 3389")]
        [ValidateRange(0, 65535)]
        [int]$TCPPort,
        
        [Parameter(Mandatory = $false, HelpMessage = "Enter the duration for how long to listen (e.g., '00:05:00' for 5 minutes)")]
        [ValidateScript({ $_ -as [TimeSpan] })]
        [TimeSpan]$Timeout = [TimeSpan]::FromMinutes(5)
    )
    $Global:ProgressPreference = 'SilentlyContinue'
    $TestTCPPort = Test-NetConnection -ComputerName localhost -Port $TCPPort -WarningAction SilentlyContinue -ErrorAction Stop
    if ($TestTCPPort.TcpTestSucceeded -ne $True) {
        Write-Host ("TCP port {0} is available, continuing..." -f $TCPPort) -ForegroundColor Green
    }
    else {
        Write-Warning -Message ("TCP Port {0} is already listening, aborting..." -f $TCPPort)
        return
    }
    $IpEndpoint = New-Object System.Net.IPEndPoint([ipaddress]::any, $TCPPort) 
    $Listener = New-Object System.Net.Sockets.TcpListener $IpEndpoint
    $Listener.Start()
    Write-Host ("Now listening on TCP port {0}, press Escape or wait for timeout to stop listening" -f $TCPPort) -ForegroundColor Green
    $StartTime = Get-Date
    while ((Get-Date) -lt ($StartTime + $Timeout)) {
        if ($host.ui.RawUi.KeyAvailable) {
            $Key = $host.ui.RawUI.ReadKey("NoEcho,IncludeKeyUp,IncludeKeyDown")
            if ($Key.VirtualKeyCode -eq 27) {	
                $Listener.Stop()
                Write-Host ("Stopped listening on TCP port {0}" -f $TCPPort) -ForegroundColor Green
                return
            }
        }
    }
    $Listener.Stop()
    Write-Host ("Timeout reached. Stopped listening on TCP port {0}" -f $TCPPort) -ForegroundColor Yellow
}
