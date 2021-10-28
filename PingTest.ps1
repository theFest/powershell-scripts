Function PingTest {
    <#
    .SYNOPSIS
    Simple ping tester.
    
    .DESCRIPTION
    With this function you can test list of destinations by specifying timeframe.
    
    .PARAMETER StringList
    Mandatory - list of destinations that you want to ping.    
    .PARAMETER Logfile
    Mandatory - output path for logfile, in CSV format.    
    .PARAMETER Intervall
    Mandatory - interval that waits between each ping.    
    .PARAMETER IntervallUnit
    Mandatory - intervallUnit that relates to intervall. Described in validateset.   
    .PARAMETER Duration
    Mandatory - duration that relates to timeframe. Described in validateset.    
    .PARAMETER EndTimeFrame
    Mandatory - declare when you want loop/ping test to end. 
    
    .EXAMPLE
    PingTest -stringlist "8.8.8.8", "9.9.9.9" -Intervall 1 -IntervallUnit ms -Logfile "path_you_want_your_logfile_to_be_saved.csv" -Duration AddSeconds -EndTimeFrame 10
    
    .NOTES
    v1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [array]$StringList,
 
        [Parameter(Position = 1, Mandatory = $true)]
        [string]$Logfile,
 
        [Parameter(Position = 2, Mandatory = $true)]
        [int]$Intervall,
 
        [Parameter(Position = 4, Mandatory = $true)]
        [ValidateSet('ms', 's', 'm')]
        [string]$IntervallUnit,

        [Parameter(Position = 5, Mandatory = $true)]
        [ValidateSet('AddDays', 'AddHours', 'AddMinutes', 'AddSeconds')]
        [string]$Duration,

        [Parameter(Position = 6, Mandatory = $true)]
        [int]$EndTimeFrame
    )
    $Ping = New-Object system.net.networkinformation.ping
    #$IpConfig = (Get-NetIPConfiguration -InterfaceAlias Ethernet)
    #$Gate = $IpConfig.IPv4DefaultGateway.NextHop
    #$Dns = $IpConfig.DNSServer.ServerAddresses
    $DurationTime = (Get-Date).$Duration($EndTimeFrame)
    $ResultBlock = {
        [PSCustomObject]@{
            Date     = Get-Date
            Computer = $Entry
            Status   = $Ping.Send($Entry).Status
            Latency  = $Ping.Send($Entry).RoundtripTime
            #Gateway  = $Gate
            #DNS      = [string]$Dns
        } | Export-Csv $Logfile -NoTypeInformation -Append
    }
    if ($IntervallUnit) {
        Start-Sleep -Seconds $Intervall
    }
    $PingReturns = @()
    while ((Get-Date) -le $DurationTime) {
        foreach ($Entry in $StringList) {
            $PingReturns += $Ping.send($Entry)
            Invoke-Command -ScriptBlock $ResultBlock
        }
    }
}