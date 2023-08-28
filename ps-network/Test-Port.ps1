Function Test-Port {
    <#
    .SYNOPSIS
    Tests the connectivity to a specific port on a given address.

    .DESCRIPTION
    This function tests the connectivity to a specified port on a given address for a defined duration. It reports whether the port is open or closed during the test period.

    .PARAMETER Address
    Mandatory - the address (hostname or IP address) to test the port against.
    .PARAMETER Port
    Mandatory - port number to test for connectivity.
    .PARAMETER Duration
    NotMandatory - duration of the test in the specified time units.
    .PARAMETER TimeUnit
    NotMandatory - time unit for the Duration parameter (Seconds, Minutes, or Hours).
    .PARAMETER Quiet
    NotMandatory - if present, suppresses output to the console.
    .PARAMETER OutputPath
    NotMandatory - path to the file where the results will be saved.
    .PARAMETER OutputInterval
    NotMandatory - interval (in seconds) at which intermediate results will be written to OutputPath.

    .EXAMPLE
    Test-Port -Address "www.google.com" -Port 80 -Duration 60 -TimeUnit Seconds -OutputInterval 10

    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$Address,

        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 65535)]
        [int]$Port,

        [Parameter()]
        [int]$Duration = 60,

        [Parameter()]
        [ValidateSet("Seconds", "Minutes", "Hours")]
        [string]$TimeUnit = "Seconds",

        [Parameter()]
        [switch]$Quiet,

        [Parameter()]
        [string]$OutputPath = "$env:TEMP\ImmediateOutput.txt",

        [Parameter()]
        [int]$OutputInterval = 0
    )
    BEGIN {
        $Results = @()
        $CurrentTime = Get-Date
        $Socket = New-Object System.Net.Sockets.TcpClient
        $WriteInterval = [TimeSpan]::FromSeconds($OutputInterval)
        $ImmediateOutputEndTime = $CurrentTime.Add($WriteInterval)
        $ImmediateOutputWriter = $null
        if ($OutputInterval -gt 0) {
            $ImmediateOutputWriter = [System.IO.StreamWriter]::new($OutputPath, $false)
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
                $Result = $Socket.BeginConnect($Address, $Port, $null, $null)
                $WaitHandle = $Result.AsyncWaitHandle
                $WaitHandle.WaitOne(1000, $false) | Out-Null
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
                $ImmediateOutputWriter.WriteLine("$CurrentTime, Immediate output: Port $Port on $Address is $Status.")
                $ImmediateOutputWriter.Flush()
                $ImmediateOutputEndTime = $ImmediateOutputEndTime.Add($WriteInterval)
            }
            $CurrentTime = Get-Date
        }
    }
    END {
        Write-Verbose -Message "Closing test and disposing..."
        $Socket.Close()
        $Socket.Dispose()
        if (!$Socket.Connected) {
            $Results += [PSCustomObject]@{
                DateTime = $CurrentTime
                Address  = $Address
                Port     = $Port
                Status   = "Closed"
            }
            if (-not $Quiet) {
                Write-Output "$CurrentTime, Timeout, port: $Port on $Address is closed."
            }
        }
        if ($ImmediateOutputWriter) {
            $ImmediateOutputWriter.Close()
            $ImmediateOutputWriter.Dispose()
            Write-Output "Immediate output has been written to $OutputPath."
        }
        return $Results
    }
}
