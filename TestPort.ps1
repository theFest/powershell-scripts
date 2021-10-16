Function TestPort {
    <#
    .SYNOPSIS
    Simple port tester/checker.
    
    .DESCRIPTION
    This function is testing/checking for open/closed ports.
    
    .PARAMETER Address
    Mandatory - declare address like www.google.com.  
    .PARAMETER Port
    Mandatory - define port of the destination address.   
    .PARAMETER Timeout
    Mandatory - you can set timeout to let's say 10000ms(10sec) or whatever suits you need.
    
    .EXAMPLE
    TestPort -Address www.google.com -Port 80 -Timeout 10000
    
    .NOTES
    v1
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Address,

        [Parameter(Mandatory = $true)]
        [string]$Port,

        [Parameter(Mandatory = $true)]
        [string]$Timeout
    )
    BEGIN {
        $Socket = New-Object System.Net.Sockets.TcpClient
    }
    PROCESS {
        $Result = $Socket.BeginConnect($Address, $Port, $null, $null)
        if ($Result.AsyncWaitHandle.WaitOne($Timeout, $False)) {
            Write-Output "Port $Port on $Address is open."
            $Socket.EndConnect($Result)
            $Socket.Connected | Out-Null
        }
        else {
            Write-Output "Timeout, port $Port on $Address is closed."
        }
    }
    END {
        $Socket.Close()
        $Socket.Dispose()
    }
}