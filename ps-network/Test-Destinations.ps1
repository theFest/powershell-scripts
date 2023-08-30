Function Test-Destinations {
    <#
    .SYNOPSIS
    Tests network connectivity to a list of destinations and logs the results to a CSV file.
    
    .DESCRIPTION
    This function allows you to test network connectivity to a list of destinations by sending ping requests.
    It logs the ping results, including round-trip times, to a CSV file. You can specify various options such as timeout, number of pings, and whether to resolve DNS.

    .PARAMETER List
    NotMandatory - an array of destination addresses to ping directly.
    .PARAMETER ImportCSV
    NotMandatory - path to a CSV file containing a list of destination addresses to ping.
    .PARAMETER Logfile
    Mandatory - the path to the output CSV file where ping results will be logged.
    .PARAMETER TimeoutMilliseconds
    NotMandatory - timeout duration in milliseconds for each ping request (default is 1000ms).
    .PARAMETER PingCount
    NotMandatory - number of ping requests to send and average for each destination (default is 4).
    .PARAMETER ResolveDNS
    NotMandatory - indicates whether to resolve domain names to IP addresses before pinging.
    
    .EXAMPLE
    "8.8.8.8", "www.google.com", "10.0.0.1" | Test-Destinations -Logfile "$env:USERPROFILE\Desktop\ping_results.csv" -ResolveDNS
    
    .NOTES
    v0.0.4
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [array]$List,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$ImportCSV,

        [Parameter(Mandatory = $true)]
        [string]$Logfile,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutMilliseconds = 1000,

        [Parameter(Mandatory = $false)]
        [int]$PingCount = 4,

        [Parameter(Mandatory = $false)]
        [switch]$ResolveDNS
    )
    BEGIN {
        $StartTime = Get-Date
        $NetworkAdapter = Get-CimInstance -Class Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 } | Select-Object -First 1
        $NetworkConfiguration = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled } | Select-Object -First 1
        $DHCPServer = $NetworkConfiguration.DHCPServer
        $MACAddress = $NetworkConfiguration.MACAddress
        $DNSServers = $NetworkConfiguration.DNSServerSearchOrder -join ","
        $NetEnabled = $NetworkAdapter.NetEnabled
        $LastReset = $NetworkAdapter.TimeOfLastReset
        $NetStatus = $NetworkAdapter.NetConnectionStatus
    }
    PROCESS {
        if ($List) {
            $ComputerList = $List
        }
        elseif ($ImportCSV) {
            $ComputerList = Get-Content $ImportCSV -Raw -ErrorAction Stop -Delimiter ","
        }
        else {
            throw "No valid input provided. Use -List or -ImportCSV parameters."
        }
        $PingResults = @()
        foreach ($Computer in $ComputerList) {
            $PingTimes = @()
            $ResolvedAddress = $null
            if ($ResolveDNS) {
                $ResolvedAddresses = [System.Net.Dns]::GetHostAddresses($Computer)
                if ($ResolvedAddresses.Length -gt 0) {
                    $ResolvedAddress = $ResolvedAddresses[0].IPAddressToString
                }
            }
            for ($i = 1; $i -le $PingCount; $i++) {
                $PingResult = [System.Net.NetworkInformation.Ping]::new().SendPingAsync($Computer, $TimeoutMilliseconds).GetAwaiter().GetResult()
                $PingTimes += $PingResult.RoundtripTime
            }
            $AverageTime = if ($PingTimes.Count -gt 0) { ($PingTimes | Measure-Object -Average).Average } else { $null }
            $PingResults += [PSCustomObject]@{
                DateTime        = Get-Date -Format "yyyy/MM/dd~HH/mm/ss/ff"
                Computer        = $Computer
                ResolvedAddress = $ResolvedAddress
                AvgRoundTrip    = $AverageTime
                DHCPServer      = $DHCPServer
                MACAddress      = $MACAddress
                DNSServers      = $DNSServers
                NetEnabled      = $NetEnabled
                LastReset       = $LastReset
                NetStatus       = $NetStatus
            }
        }
        $PingResults | Export-Csv $Logfile -NoTypeInformation -Append
    }
    END {
        $PingDuration = (Get-Date).Subtract($StartTime).ToString("hh\:mm\:ss\.fff")
        Write-Host "Total ping duration: $PingDuration" -ForegroundColor Cyan
    }
}
