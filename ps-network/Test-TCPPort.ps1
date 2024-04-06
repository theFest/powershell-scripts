Function Test-TCPPort {
    <#
    .SYNOPSIS
    Tests the connectivity of a TCP port on a specified address.

    .DESCRIPTION
    This function checks the connectivity of a specified TCP port on a given address. It attempts to establish a connection to the specified port and address. If the connection is successful, it reports that the port is open. If the connection attempt times out or fails, it reports that the port is closed.

    .PARAMETER Address
    Address to which the function will attempt to connect.
    .PARAMETER Port
    Port number to which the function will attempt to connect.
    .PARAMETER Duration
    Duration of the test in the specified time unit, default is 60 seconds.
    .PARAMETER TimeUnit
    Time unit for the duration parameter, valid values are Seconds, Minutes, Hours; default is Seconds.
    .PARAMETER Quiet
    Output of open port messages. If this switch is not used, the function outputs a message when a port is found to be open.
    .PARAMETER OutputPath
    Path where immediate output (if any) will be written, default is $env:TEMP\results.txt.
    .PARAMETER OutputInterval
    Interval (in seconds) for immediate output, default is 0 (no immediate output).

    .EXAMPLE
    Test-TCPPort -Address "localhost" -Port 80
    Test-TCPPort -Address "www.google.com" -Port 80 -Duration 60 -TimeUnit Seconds -OutputInterval 10

    .NOTES
    v0.1.7
    #>
    [CmdletBinding(ConfirmImpact = "None")]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Alias("a")]
        [string]$Address,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 65535)]
        [Alias("p")]
        [int]$Port,

        [Parameter(Mandatory = $false)]
        [Alias("d")]
        [int]$Duration = 60,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Seconds", "Minutes", "Hours")]
        [Alias("t")]
        [string]$TimeUnit = "Seconds",

        [Parameter(Mandatory = $false)]
        [Alias("qt")]
        [switch]$Quiet,

        [Parameter(Mandatory = $false)]
        [Alias("o")]
        [string]$OutputPath = "$env:TEMP\results.txt",

        [Parameter(Mandatory = $false)]
        [Alias("i")]
        [int]$OutputInterval = 0
    )
    BEGIN {
        $Results = @()
        $CurrentTime = Get-Date
        $Socket = New-Object System.Net.Sockets.TcpClient
        $WriteInterval = [TimeSpan]::FromSeconds($OutputInterval)
        $ImmediateOutputEndTime = $CurrentTime.Add($WriteInterval)
        $IOutputWriter = $null
        if ($OutputInterval -gt 0) {
            $IOutputWriter = [System.IO.StreamWriter]::new($OutputPath, $false)
        }
    }
    PROCESS {
        $TimeSpan = switch ($TimeUnit) {
            "Minutes" { [TimeSpan]::FromMinutes($Duration) }
            "Hours" { [TimeSpan]::FromHours($Duration) }
            default { [TimeSpan]::FromSeconds($Duration) }
        }
        $EndTime = $CurrentTime.Add($TimeSpan)
        while ($CurrentTime -le $EndTime) {
            if (!$Socket.Connected) {
                if (!$Socket.Client.Connected) {
                    $Result = $Socket.BeginConnect($Address, $Port, $null, $null)
                    $Result.AsyncWaitHandle.WaitOne() | Out-Null
                    $Socket.EndConnect($Result) | Out-Null
                }
                if ($Socket.Connected) {
                    $Results += [PSCustomObject]@{
                        DateTime = $CurrentTime
                        Address  = $Address
                        Port     = $Port
                        Status   = "Open"
                    }
                    if (-not $Quiet) {
                        Write-Output "$CurrentTime, Port $Port on $Address is open."
                    }
                }
            }
            if ($OutputInterval -gt 0 -and $CurrentTime -ge $ImmediateOutputEndTime) {
                $Status = if ($Socket.Connected) { "Open" } else { "Closed" }
                $IOutputWriter.WriteLine("$CurrentTime, Immediate output: Port $Port on $Address is $Status")
                $IOutputWriter.Flush()
                $ImmediateOutputEndTime = $ImmediateOutputEndTime.Add($WriteInterval)
            }
            $CurrentTime = Get-Date
        }
    }
    END {
        Write-Verbose -Message "Closing test and disposing..."
        if ($null -ne $Socket -and $Socket.Connected) {
            $Socket.Close()
            $Socket.Dispose()
        }
        if (!$Socket.Connected) {
            $Results += [PSCustomObject]@{
                DateTime = $CurrentTime
                Address  = $Address
                Port     = $Port
                Status   = "Closed"
            }
            if (-not $Quiet) {
                Write-Warning -Message "$CurrentTime, Timeout, port: $Port on $Address is closed!"
            }
        }
        if ($IOutputWriter) {
            $IOutputWriter.Close()
            $IOutputWriter.Dispose()
            Write-Host "Immediate output has been written to $OutputPath" -ForegroundColor Green
        }
        return $Results
    }
}
