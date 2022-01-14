Function PingTest {
    <#
    .SYNOPSIS
    Simple ping tester using a loop.
    
    .DESCRIPTION
    With this function you can test list of destinations by specifying timeframe.
    
    .PARAMETER List
    Mandatory - array of destinations that you want to ping. 
    .PARAMETER ImportCSV
    Mandatory - csv that contains the destinations you want to ping.    
    .PARAMETER Logfile
    Mandatory - output path for logfile, in CSV format.
    
    .EXAMPLE
    "8.8.8.8", "9.9.9.9" | PingTest -Logfile "$env:USERPROFILE\Desktop\your_ping_results.csv"
    PingTest -ImportCSV "$env:USERPROFILE\Desktop\your_list_to_ping.csv" -Logfile "$env:USERPROFILE\Desktop\your_ping_results.csv"
    
    .NOTES
    v3
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [array]$List,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 1)]
        [string]$ImportCSV,

        [Parameter(Mandatory = $true)]
        [string]$Logfile
    )
    BEGIN {
        $StartTime = Get-Date
        $Net = Get-CimInstance -Class Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 } | Select-Object -First 1
        $NetConf = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | Select-Object -First 1
        $DHCPServer = [string]$NetConf.DHCPServer
        $MACAddress = [string]$NetConf.MACAddress
        $DNSServers = [string]$NetConf.DNSServerSearchOrder
        $NetEnabled = [bool]$Net.NetEnabled  
        $LastReset = [string]$Net.TimeOfLastReset
        $NetStatus = [int]$Net.NetConnectionStatus            
    }
    PROCESS {
        $PingReturns = @{}
        if ($List) {
            $ComputerList = $List
        }
        else {
            $ComputerList = Get-Content $ImportCSV
            $ComputerList = $ComputerList -split ","
        }
        foreach ($Computer in $ComputerList) {
            $PingReturns[$Computer] = [System.Net.NetworkInformation.Ping]::new().SendPingAsync($Computer)
        }
        while ($false -in $PingReturns.Values.IsCompleted) { Start-Sleep -Milliseconds 300 }
        $PingResult = foreach ($Computer in $ComputerList) {
            $Result = $PingReturns[$Computer].Result
            [PSCustomObject]@{
                DateTime   = Get-Date -Format yyyy/MM/dd~HH/mm/ss/ff
                Computer   = $Computer
                Address    = $Result.Address.IPAddressToString
                Time       = $Result.RoundtripTime
                Bytes      = $Result.Buffer.Count
                TTL        = $Result.Options.Ttl
                Status     = if ($Result.Address.IPAddressToString) { $Result.Status } else { "Failed" }
                DHCPServer = $DHCPServer
                MACAddress = $MACAddress
                DNSServers = $DNSServers
                NetEnabled = $NetEnabled
                LastReset  = $LastReset
                NetStatus  = $NetStatus
            }
        }
        $PingResult | Export-Csv $Logfile -NoTypeInformation -Append
    }
    END {
        Write-Host "Total ping duration: $((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")" -ForegroundColor Cyan 
    }
}