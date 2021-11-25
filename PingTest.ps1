Function PingTest {
    <#
    .SYNOPSIS
    Simple ping tester using a loop.
    
    .DESCRIPTION
    With this function you can test list of destinations by specifying timeframe.
    
    .PARAMETER ArrayList
    Mandatory - array of destinations that you want to ping. 
    .PARAMETER ImportCSV
    Mandatory - csv that contains the destinations you want to ping.    
    .PARAMETER Logfile
    Mandatory - output path for logfile, in CSV format.    
    .PARAMETER Interval
    Mandatory - interval that waits between each ping.    
    .PARAMETER IntervalUnit
    NotMandatory - interval unit that relates to interval. Described in validateset.   
    .PARAMETER Duration
    NotMandatory - duration that relates to timeframe. Described in validateset.    
    .PARAMETER EndTimeFrame
    NotMandatory - declare when you want loop/ping test to end. It's set to 60 seconds.
    
    .EXAMPLE
    PingTest -ArrayList "8.8.8.8", "9.9.9.9" -Intervall 1 -IntervallUnit ms -Logfile "path_you_want_your_logfile_to_be_saved.csv" -Duration AddSeconds -EndTimeFrame 20
    PingTest -ImportCSV "$env:USERPROFILE\Desktop\your_list_to_ping.csv" -Interval 1 -IntervalUnit ms -Logfile "$env:USERPROFILE\Desktop\your_ping_results.csv" -Duration AddSeconds -EndTimeFrame 20
    
    .NOTES
    v2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 0)]
        [array]$ArrayList,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, Position = 1)]
        [string]$ImportCSV,

        [Parameter(Mandatory = $true)]
        [string]$Logfile,
 
        [Parameter(Mandatory = $false)]
        [int]$Interval = 1,
 
        [Parameter(Mandatory = $false)]
        [ValidateSet('ms', 's', 'm')]
        [string]$IntervalUnit = 'ms',

        [Parameter(Mandatory = $false)]
        [ValidateSet('AddDays', 'AddHours', 'AddMinutes', 'AddSeconds')]
        [string]$Duration = 'AddSeconds',

        [Parameter(Mandatory = $false)]
        [int]$EndTimeFrame = 60
    )
    BEGIN {
        $StartTime = Get-Date
        $Ping = New-Object System.Net.NetworkInformation.Ping
        $Net = Get-CimInstance -Class Win32_NetworkAdapter | Where-Object { $_.NetConnectionStatus -eq 2 } | Select-Object -First 1
        $NetConf = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | Select-Object -First 1
        $IPAddress = [string]$NetConf.IPAddress.Item(0)
        $DHCPServer = [string]$NetConf.DHCPServer
        $MACAddress = [string]$NetConf.MACAddress
        $DNSServers = [string]$NetConf.DNSServerSearchOrder
        $NetEnabled = [bool]$Net.NetEnabled  
        $LastReset = [string]$Net.TimeOfLastReset
        $NetStatus = [int]$Net.NetConnectionStatus            
    }
    PROCESS {
        $DurationTime = (Get-Date).$Duration($EndTimeFrame)
        $PingReturns = @()
        if ($ArrayList) {
            $StringList = $ArrayList
        }
        else {
            $StringList = Get-Content $ImportCSV
        }
        while ((Get-Date) -le $DurationTime) {
            foreach ($Entry in $StringList) {
                $PingReturns += $Ping.Send($Entry)
                if ($IntervalUnit) {
                    Start-Sleep -Seconds $Interval
                }
                [PSCustomObject]@{
                    DateTime    = Get-Date -Format yyyy/MM/dd~HH/mm/ss/ff
                    Destination = $Entry
                    Status      = $Ping.Send($Entry).Status
                    Latency     = $Ping.Send($Entry).RoundtripTime
                    IPAddress   = $IPAddress
                    DHCPServer  = $DHCPServer
                    MACAddress  = $MACAddress
                    DNSServers  = $DNSServers
                    NetEnabled  = $NetEnabled
                    LastReset   = $LastReset
                    NetStatus   = $NetStatus
                } | Export-Csv $Logfile -NoTypeInformation -Append
            }
        }
    }
    END {
        Write-Host "Total ping duration: $((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")" -ForegroundColor Cyan 
    }
}