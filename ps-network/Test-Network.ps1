Function Test-Network {
    <#
    .SYNOPSIS
    Tests the network connectivity and availability of specified target hosts using various test types.
    
    .DESCRIPTION
    This function uses several different test types to check the connectivity and availability of specified target hosts.
    It includes ping response time, port availability, trace route results, DNS resolution, and WS-Management connectivity. The test results are stored in custom objects that include the target host name, test type, status, port number, response time, and any messages returned by the tests.
    
    .PARAMETER TargetHost
    Mandatory - specifies one or more target hosts to test.
    .PARAMETER TestType
    Mandatory - type of tests to perform on the target hosts. Valid values are "Ping", "Port", "Trace", "DNS", "WsMan", or "All".
    .PARAMETER Port
    NotMandatory - the port number to use for the port test. Default value is 80.
    .PARAMETER Timeout
    NotMandatory - timeout value (in milliseconds) for the network tests. Default value is 5000 milliseconds.
    .PARAMETER Ttl
    NotMandatory - time-to-live (TTL) value for the trace route test. Default is set to value 64.
    .PARAMETER MaxHops
    NotMandatory - maximum number of hops to allow for the trace route test. Default value is 30.
    .PARAMETER DnsServer
    NotMandatory - specifies the DNS server to use for the DNS resolution test.
    .PARAMETER LogPath
    NotMandatory - path to a log file to store the test results.
    .PARAMETER ExportPath
    NotMandatory - path to a CSV file to export the test results.

    .EXAMPLE
    Test-Network -TargetHost "google.com" -TestType Ping
    Test-Network -TargetHost "remote_host" -TestType WsMan
    Test-Network -TargetHost "remote_host" -TestType Trace -Ttl 30
    Test-Network -TargetHost "0.pool.ntp.org" -TestType DNS -DnsServer "8.8.8.8"
    Test-Network -TargetHost "1.pool.ntp.org" -TestType Port -Port 3389 -Timeout 10000
    "1.1.1.1", "8.8.8.8", "9.9.9.9" | Test-Network -TestType Ping -LogPath "$env:USERPROFILE\Desktop\nt_res.csv"

    .NOTES
    Version: 0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]]$TargetHost,

        [Parameter(Mandatory = $true)]
        [ValidateSet("All", "Ping", "Port", "Trace", "DNS", "WsMan")]
        [string]$TestType,

        [Parameter(Mandatory = $false)]
        [int]$Port = 80,

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 5000,

        [Parameter(Mandatory = $false)]
        [int]$Ttl = 64,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxHops = 30,

        [Parameter(Mandatory = $false)]
        [string]$DnsServer,

        [Parameter(Mandatory = $false)]
        [string]$LogPath,

        [Parameter(Mandatory = $false)]
        [string]$ExportPath
    )
    BEGIN {
        $TestTypes = @("Ping", "Port", "Trace", "DNS", "WsMan")
        $All = ($TestType -eq "All")
        if ($All) {
            $TestTypes = @("Ping", "Port", "Trace", "DNS", "WsMan")
        }
        else {
            $TestTypes = @($TestType)
        }
        $OnlineResults = @()
        $OfflineResults = @()
    }
    PROCESS {
        foreach ($HostName in $TargetHost) {
            foreach ($Type in $TestTypes) {
                $Result = [PSCustomObject]@{
                    TargetHost = $HostName
                    TestType   = $Type
                    Status     = $false
                    Port       = $Port
                    Time       = $null
                    Message    = $null
                }
                try {
                    switch ($Type) {
                        "Ping" {
                            $PingResult = Test-Connection -ComputerName $HostName -Count 1 -ErrorAction Stop
                            $Result.Status = ($PingResult.ResponseTime -ge 0)
                            $Result.Time = $PingResult.ResponseTime
                            $Result.Message = "Ping Test: $($PingResult.ResponseDetails)"
                        }
                        "Port" {
                            $Socket = New-Object System.Net.Sockets.TcpClient
                            $Connect = $Socket.BeginConnect($HostName, $Port, $null, $null)
                            $Result.Status = $Connect.AsyncWaitHandle.WaitOne($Timeout, $false)
                            $Result.Time = $Timeout - $Connect.AsyncState
                            if ($Result.Status) {
                                $Socket.EndConnect($Connect)
                                $Result.Message = "Port Test: Success"
                            }
                            else {
                                $Result.Message = "Port Test: Connection timed out"
                            }
                        }
                        "Trace" {
                            $TraceRoute = Test-NetConnection -ComputerName $HostName -TraceRoute -Hops $MaxHops -ErrorAction Stop
                            $Result.Status = $TraceRoute.TraceSucceeded
                            $Result.Time = $TraceRoute.TracerouteTime
                            if ($TraceRoute.TraceRoute) {
                                $Result.Message = "Trace Test: $($TraceRoute.TraceRoute -join ' -> ')"
                            }
                            else {
                                $Result.Message = "Trace Test: No trace route results found."
                            }
                        }
                        "DNS" {
                            Resolve-DnsName -Name $HostName -Server $DnsServer -ErrorAction Stop
                            $Result.Status = $true
                            $Result.Message = "DNS Test: Resolved successfully."
                        }
                        "WsMan" {
                            $WsManResult = Test-WSMan -ComputerName $HostName -ErrorAction Stop
                            $Result.Status = ($null -ne $WsManResult)
                            $Result.Message = "WSMan Test: $($WsManResult.State)"
                        }
                    }
                }
                catch {
                    $Result.Message = "Error: $($_.Exception.Message)"
                }
                if ($Result.Status) {
                    $OnlineResults += $Result
                }
                else {
                    $OfflineResults += $Result
                }
            }
        }
    }
    END {
        $Results = $OnlineResults + $OfflineResults | Sort-Object TargetHost
        if ($LogPath) {
            $Results | Export-Csv -Path $LogPath -NoTypeInformation
        }
        if ($ExportPath) {
            $Results | Export-Csv -Path $ExportPath -NoTypeInformation
        }
        $Results | Format-Table -AutoSize
        "Online hosts: $($OnlineResults.Count)", "Offline hosts: $($OfflineResults.Count)" | Out-Host
    }
}
