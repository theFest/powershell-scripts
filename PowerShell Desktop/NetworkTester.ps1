Function NetworkTester {
    <#
    .SYNOPSIS
    Tests the network connectivity and availability of specified target hosts using various test types.
    
    .DESCRIPTION
    This function uses several different test types to check the connectivity and availability of specified target hosts, it can test a host's ping response time, port availability, trace route results, DNS resolution, and WS-Management connectivity.
    The test results are stored in a custom object that includes the target host name, test type, status, port number, response time, and any messages returned by the tests.
    
    .PARAMETER TargetHost
    NotMandatory - specifies one or more target hosts to test.
    .PARAMETER TestType
    NotMandatory - type of tests to perform on the target hosts. The parameter is mandatory, valid values are "Ping", "Port", "Trace", "DNS", "WsMan", or "All".
    .PARAMETER Port
    NotMandatory - specifies the port number to use for the port test, default value is 80.
    .PARAMETER Timeout
    NotMandatory - timeout value (in milliseconds) for the network tests, default value is 5000 milliseconds.
    .PARAMETER Ttl
    NotMandatory - the time-to-live (TTL) value for the trace route test, default is set to value 64.
    .PARAMETER MaxHops
    NotMandatory - maximum number of hops to allow for the trace route test, default value is 30.
    .PARAMETER DnsServer
    NotMandatory - specifies the DNS server to use for the DNS resolution test.
    .PARAMETER LogPath
    NotMandatory - path to a log file to store the test results.
    
    .EXAMPLE
    NetworkTester -TargetHost "computer" -TestType Ping
    NetworkTester -TargetHost "computer", "computer2", "computer3" -TestType Ping -LogPath "$env:USERPROFILE\Desktop\nt_res.csv"
    NetworkTester -TargetHost "computer" -TestType Port -Port 3389 -Timeout 10000
    NetworkTester -TargetHost "computer" -TestType Trace -Ttl 30
    NetworkTester -TargetHost "computer" -TestType DNS -DnsServer "8.8.8.8"
    NetworkTester -TargetHost "computer" -TestType WsMan
    
    .NOTES
    v0.0.1
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
        [string]$LogPath

        #[Parameter(Mandatory = $false)]
        #[string]$OfflinePath = "offline.csv", #"$env:USERPROFILE\Desktop\offline.csv",

        #[Parameter(Mandatory = $false)]
        #[string]$OnlinePath = "online.csv", #"$env:USERPROFILE\Desktop\online.csv"
    )
    BEGIN {
        $OnlineResults = @()
        $OfflineResults = @()
        if ($CsvPath) {
            $TargetHost = Import-Csv -Path $CsvPath | Select-Object -ExpandProperty TargetHost
        }
        $All = $TestType -eq "All"
        $TestTypes = if ($All) { "Ping", "Port", "Trace", "DNS", "WsMan" } else { $TestType }
    }
    PROCESS {
        if ($MaxHops -lt 1) {
            $MaxHops = 1
        }
        $Results = foreach ($HostName in $TargetHost) {
            foreach ($Type in $TestTypes) {
                $Result = [PSCustomObject]@{
                    TargetHost = $HostName
                    TestType   = $Type
                    Status     = $null
                    Port       = $Port
                    Time       = $null
                    Message    = $null
                }
                try {
                    switch ($Type) {
                        "Ping" {
                            $PingJob = Start-Job -ScriptBlock { Test-Connection -ComputerName $using:HostName -Count 1 }
                            Wait-Job $PingJob | Out-Null
                            $PingResult = Receive-Job $PingJob -ErrorAction SilentlyContinue
                            if ($PingResult) {
                                $Result.Status = $PingResult.ResponseTime -ge 0
                                $Result.Time = $PingResult.ResponseTime
                                $Result.Message = "Ping Test: $($PingResult.ResponseDetails)"
                            }
                            else {
                                $Result.Message = "Ping Test: Failed to ping host."
                            }
                        }
                        "Port" {
                            $Socket = New-Object System.Net.Sockets.TcpClient
                            $Connect = $Socket.BeginConnect($HostName, $Port, $null, $null)
                            try {
                                $Result.Status = $Connect.AsyncWaitHandle.WaitOne($Timeout, $false)
                                $Result.Time = $Timeout - $Connect.AsyncState
                                $Socket.EndConnect($Connect)
                                $Result.Message = "Port Test: $($Result.Status)"
                            }
                            catch {
                                $Result.Status = $false
                                $Result.Message = "Port Test: $($Error[0].Exception.Message)"
                            }
                        }
                        "Trace" {
                            $TraceRoute = Test-NetConnection -ComputerName $HostName -TraceRoute -Hops $MaxHops -ErrorAction SilentlyContinue
                            if ($TraceRoute) {
                                $Result.Status = $TraceRoute.TraceSucceeded
                                $Result.Time = $TraceRoute.TracerouteTime
                                if ($TraceRoute.TraceRoute) {
                                    $Result.Message = "Trace Test: $($TraceRoute.TraceRoute)"
                                }
                                else {
                                    $Result.Message = "Trace Test: No trace route results found."
                                }
                            }
                            else {
                                $Result.Message = "Trace Test: Trace route failed."
                            }
                        }
                        "DNS" {
                            try {
                                $DnsResult = Resolve-DnsName -Name $HostName -Server $DnsServer -ErrorAction Stop
                                $Result.Status = [bool]$DnsResult
                                $Result.Message = "DNS Test: Resolved successfully."
                            }
                            catch {
                                $Result.Status = $false
                                $Result.Message = "DNS Test: Failed to resolve. Error: $_"
                            }
                        }
                        "WsMan" {
                            $Job = Start-Job -ScriptBlock {
                                Test-WSMan -ComputerName $using:HostName -ErrorAction Stop
                            }
                            $Result.Status = $false
                            $Result.Time = 0
                            $Result.Message = "WSMan Test: Job started. Waiting for results..."
                            $Job | Wait-Job -Timeout $Timeout
                            if ($Job.State -eq "Completed") {
                                $Result.Status = $Job.ChildJobs[0].JobStateInfo.State -eq "Completed"
                                $Result.Time = $Job.ChildJobs[0].JobStateInfo.TotalSeconds
                                $Result.Message = "WSMan Test: $($Job.ChildJobs[0].JobStateInfo.State)"
                            }
                            elseif ($Job.State -eq "Failed") {
                                $Result.Message = "WSMan Test: $($Job.ChildJobs[0].JobStateInfo.State)"
                            }
                            Remove-Job $Job
                        }
                        default {
                            Write-Error "Invalid TestType: $Type"
                        }
                    }
                }
                catch {
                    $Result.Status = $false
                    $Result.Message = "Error: $($_.Exception.Message)"
                }
                $Result
                Get-Job -Name * -Verbose |  Wait-Job -Any | Remove-Job -Force -Verbose
            }
        }
    }
    END {
        $OnlineResults = $Results | Where-Object { $_.Status -eq $true }
        $OfflineResults = $Results | Where-Object { $_.Status -eq $false }
        if ($LogPath) {
            $Results | Export-Csv -Path $LogPath -NoTypeInformation -Append
        }
        if ($OnlinePath) {
            $OnlineResults | Export-Csv -Path $OnlinePath -NoTypeInformation
        }
        if ($OfflinePath) {
            $OfflineResults | Export-Csv -Path $OfflinePath -NoTypeInformation
        }
        return $Results | Format-Table -AutoSize
    }
}        
