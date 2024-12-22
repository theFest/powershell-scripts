function Receive-WebSocketMessageStream {
    <#
    .SYNOPSIS
    Connects to a WebSocket server and continuously receives and displays text messages.
    
    .DESCRIPTION
    This function establishes a WebSocket connection to the specified URL and continuously listens for incoming text messages. When a text message is received, it is displayed on the console.

    .EXAMPLE
    Receive-WebSocketMessageStream -Url "wss://echo.websocket.org"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "URL of the WebSocket server to connect to")]
        [string]$Url
    )
    $WebSocket = [System.Net.WebSockets.ClientWebSocket]::new()
    $Uri = [System.Uri]$Url
    $CancellationToken = [System.Threading.CancellationToken]::None
    $WebSocket.ConnectAsync($Uri, $CancellationToken).Wait()
    while ($true) {
        $Buffer = New-Object Byte[] 1024
        $Result = $WebSocket.ReceiveAsync($Buffer, $cancellationToken).Result
        if ($Result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Text) {
            $Message = [System.Text.Encoding]::UTF8.GetString($Buffer, 0, $Result.Count)
            Write-Host "Received message: $Message" -ForegroundColor DarkCyan
        }
    }
}
