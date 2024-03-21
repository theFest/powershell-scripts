Function Ping-IPRange {
    <#
    .SYNOPSIS
    Performs a ping sweep on a specified range of IP addresses.

    .DESCRIPTION
    This function allows you to perform a ping sweep on a specified range of IP addresses, uses ICMP echo requests to check the online status of each IP address within the given range.

    .PARAMETER Start
    Starting IP address for the ping sweep.
    .PARAMETER End
    Ending IP address for the ping sweep.
    .PARAMETER IPAddresses
    Array of manually defined IP addresses to perform a ping sweep against.
    .PARAMETER ExcludeAddresses
    Specifies an array of IP addresses to exclude from the ping sweep.
    .PARAMETER TimeoutMilliSec
    Number of milliseconds to wait between timeouts for ping responses, default is 4000 milliseconds.
    .PARAMETER DnsLookup
    Performs DNS lookup for each online IP address to retrieve its hostname.
    .PARAMETER OnlineOnly
    Returns only the online IP addresses.

    .EXAMPLE
    Ping-IPRange -Start 192.168.0.1 -End 192.168.0.100 -TimeoutMilliSec 4000 -DnsLookup -OnlineOnly

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(DefaultParameterSetName = "Dynamic")]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "Dynamic", HelpMessage = "Enter the IP address to start your scan from : ")]
        [ValidatePattern("\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")]
        [string]$Start,
    
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "Dynamic", HelpMessage = "Enter the last IP of the range you want to scan : ")]
        [ValidatePattern("\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}")]
        [string]$End,
    
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "List", ValueFromPipeline = $false, ValueFromPipelineByPropertyName = $false, HelpMessage = "Manually define an array of IP addresses to perform a ping sweep against. ")]
        [ValidateScript({ $_ | ForEach-Object { $_ -Match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" } })]
        [string[]]$IPAddresses,
    
        [Parameter(Mandatory = $false, Position = 2, ParameterSetName = "Dynamic", HelpMessage = "Enter the last IP of the range you want to scan : ")]
        [ValidateScript({ $_ | ForEach-Object { $_ -Match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" } })]
        [string[]]$ExcludeAddresses,
    
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Enter the number of milliseconds to wait between timeouts : ")]
        [int]$TimeoutMilliSec = 4000,
    
        [Parameter(Mandatory = $false)]
        [switch]$DnsLookup,
    
        [Parameter(Mandatory = $false)]
        [switch]$OnlineOnly
    )
    BEGIN {
        $Return = @()
        $IPRange = @()
        $StringBuilder = @()
    } 
    PROCESS {
        if ($PSCmdlet.ParameterSetName -eq "Dynamic") {
            $ClassD1 = $Start.Split(".")[-1]
            $ClassD2 = $End.Split(".")[-1]
            $ClassC1 = $Start.Split(".")[2] -Join "."
            $ClassC2 = $End.Split(".")[2] -Join "."
            $ClassB1 = $Start.Split(".")[1] -Join "."
            $ClassB2 = $End.Split(".")[1] -Join "."
            $ClassA1 = $Start.Split(".")[0] -Join "."
            $ClassA2 = $End.Split(".")[0] -Join "."
            Write-Verbose -Message "Validating subnet range"
            if ($ClassA1 -ne $ClassA2) {
                throw "[x] I would suggest using masscan instead | $ClassA1 != $ClassA2"
            }
            elseIf ($ClassB1 -gt $ClassB2) {
                throw "[x] Starting subnet is greater than your ending subnet | $ClassB1 > $ClassB2"
            }
            elseIf ($ClassB1 -ge $ClassB2 -and $ClassC1 -gt $ClassC2) {
                throw "[x] Starting subnet is greater than your ending subnet | $ClassC1 > $ClassC2"
            }
            elseIf ($ClassC1 -le $ClassC2 -and $ClassD1 -gt $ClassD2) {
                throw "[x] Starting subnet is greater than your ending subnet | $ClassD1 > $ClassD2"
            }
            else {
                Write-Verbose -Message "Starting and Ending Subnets are within the required parameters"
            }
            Write-Verbose -Message "Building range of IP addresses to perform ICMP checks against"
            $IpOd = $Start -Split "\."
            $IpDo = $End -Split "\."
            [array]::Reverse($IpOd)
            [array]::Reverse($IpDo)
            $Starting = [BitConverter]::ToUInt32([byte[]]$IpOd, 0)
            $Ending = [BitConverter]::ToUInt32([byte[]]$IpDo, 0)
            for ($IP = $Starting; $IP -lt $Ending; $IP++) {
                $GetIP = [BitConverter]::GetBytes($IP)
                [array]::Reverse($GetIP)
                $IPRange += $GetIP -Join "."
            }
            foreach ($Ipv4 in $IPRange) {
                If ($Ipv4 -notin $ExcludeAddresses) {
                    $StringBuilder += "Address='$($Ipv4)' or "
                }
            }
            $StringBuilder += "Address='$($End)') and"
        }
        else {
            $End = $IPAddresses[-1]
            foreach ($Ipv4 in $IPAddresses) {
                $StringBuilder += "Address='$($Ipv4)' or "
            }
            $StringBuilder += "Address='$($End)') and"
        }
        if ($StringBuilder.Count -lt 426) {
            $PingResults = Get-CimInstance -ClassName Win32_PingStatus -Filter "($StringBuilder Timeout=$TimeoutMillisec" | Select-Object -Property Address, StatusCode
            $Results = $PingResults
        }
        elseIf ($StringBuilder.Count -ge 426 -and $StringBuilder.Count -lt 852) {
            $MidIndex = [Int](($StringBuilder.Length + 1) / 2)
            $Split1 = $StringBuilder[0..($MidIndex - 1)]
            $Split2 = $StringBuilder[$MidIndex..($StringBuilder.Count - 1)]
            $IpFilter1 = "$($Split1[-1].Replace("or","and"))"
            $IpFilter2 = "$($Split2[-1].Replace("or","and"))"
            $PingResults = Get-CimInstance -ClassName Win32_PingStatus -Filter "$($Split1.Replace("$($Split1[-1])","$IpFilter1")) Timeout=$TimeoutMillisec" | Select-Object -Property Address, StatusCode
            $PingResults2 = Get-CimInstance -ClassName Win32_PingStatus -Filter "$($Split2.Replace("$($Split2[-1])","$IpFilter2")) Timeout=$TimeoutMillisec" | Select-Object -Property Address, StatusCode
            Write-Information -MessageData "426 seems to be the max amount of devices with Win32_PingStatus"
            $Results = $PingResults + $PingResults2
        }
        elseIf ($StringBuilder.Count -ge 852 -and $StringBuilder.Count -lt 1278) {
            $ThirdsIndex = [int](($StringBuilder.Count + 1) / 3)
            $Split1 = $StringBuilder[0..($ThirdsIndex - 1)]
            $Split2 = $StringBuilder[$Split1.Count..($Split1.Count + $ThirdsIndex - 1)]
            $Split3 = $StringBuilder[($Split1.Count + $ThirdsIndex)..($StringBuilder.Count)]
            $IpFilter1 = "$($Split1[-1].Replace("or","and"))"
            $IpFilter2 = "$($Split2[-1].Replace("or","and"))"
            $IpFilter3 = "$($Split3[-1].Replace("or","and"))"
            $PingResults = Get-CimInstance -ClassName Win32_PingStatus -Filter "$($Split1.Replace("$($Split1[-1])","$IpFilter1")) Timeout=$TimeoutMillisec" | Select-Object -Property Address, StatusCode
            $PingResults2 = Get-CimInstance -ClassName Win32_PingStatus -Filter "$($Split2.Replace("$($Split2[-1])","$IpFilter2")) Timeout=$TimeoutMillisec" | Select-Object -Property Address, StatusCode
            $PingResults3 = Get-CimInstance -ClassName Win32_PingStatus -Filter "$($Split3.Replace("$($Split3[-1])","$IpFilter3")) Timeout=$TimeoutMillisec" | Select-Object -Property Address, StatusCode
            Write-Information -MessageData "426 seems to be the max amount of devices with Win32_PingStatus"
            $Results = $PingResults + $PingResults2 + $PingResults3
        }
        elseIf ($StringBuilder.Count -ge 1278 -and $StringBuilder.Count -lt 1704) {
            $FourthIndex = [Int](($StringBuilder.Count + 1) / 4)
            $Split1 = $StringBuilder[0..($FourthIndex - 1)]
            $Split2 = $StringBuilder[$Split1.Count..($Split1.Count + $FourthIndex - 1)]
            $Split3 = $StringBuilder[($Split1.Count + $FourthIndex)..($StringBuilder.Count)]
            $IpFilter1 = "$($Split1[-1].Replace("or","and"))"
            $IpFilter2 = "$($Split2[-1].Replace("or","and"))"
            $IpFilter3 = "$($Split3[-1].Replace("or","and"))"
            $IpFilter4 = "$($Split4[-1].Replace("or","and"))"
            $PingResults = Get-CimInstance -ClassName Win32_PingStatus -Filter "$($Split1.Replace("$($Split1[-1])","$IpFilter1")) Timeout=$TimeoutMillisec" | Select-Object -Property Address, StatusCode
            $PingResults2 = Get-CimInstance -ClassName Win32_PingStatus -Filter "$($Split2.Replace("$($Split2[-1])","$IpFilter2")) Timeout=$TimeoutMillisec" | Select-Object -Property Address, StatusCode
            $PingResults3 = Get-CimInstance -ClassName Win32_PingStatus -Filter "$($Split3.Replace("$($Split3[-1])","$IpFilter3")) Timeout=$TimeoutMillisec" | Select-Object -Property Address, StatusCode
            $PingResults4 = Get-CimInstance -ClassName Win32_PingStatus -Filter "$($Split4.Replace("$($Split4[-1])","$IpFilter4")) Timeout=$TimeoutMillisec" | Select-Object -Property Address, StatusCode
            Write-Information -MessageData "426 seems to be the max amount of devices with Win32_PingStatus"
            $Results = $PingResults + $PingResults2 + $PingResults3 + $PingResults4
        }
        else {
            Write-Error -Message "I have not created enough statements yet to handle more than 1278 IP Addresses!"
        }
        foreach ($Device in $Results) {
            switch ($Device.StatusCode) {
                0 { $StatusCode = "Online" }
                11001 { $StatusCode = "Buffer Too Small" }
                11002 { $StatusCode = "Destination Net Unreachable" }
                11003 { $StatusCode = "Destination Host Unreachable" }
                11004 { $StatusCode = "Destination Protocol Unreachable" }
                11005 { $StatusCode = "Destination Port Unreachable" }
                11006 { $StatusCode = "No Resources" }
                11007 { $StatusCode = "Bad Option" }
                11008 { $StatusCode = "Hardware Error" }
                11009 { $StatusCode = "Packet Too Big" }
                11010 { $StatusCode = "Request Timed Out" }
                11011 { $StatusCode = "Bad Request" }
                11012 { $StatusCode = "Bad Route" }
                11013 { $StatusCode = "TimeToLive Expired Transit" }
                11014 { $StatusCode = "TimeToLive Expired Reassembly" }
                11015 { $StatusCode = "Parameter Problem" }
                11016 { $StatusCode = "Source Quench" }
                11017 { $StatusCode = "Option Too Big" }
                11018 { $StatusCode = "Bad Destination" }
                11032 { $StatusCode = "Negotiating IPSEC" }
                11050 { $StatusCode = "General Failure" }
                default {
                    $StatusCode = "Undocumnted Result: $Code" 
                }
            }
            if ($DnsLookup) {
                $Return += New-Object -TypeName PSCustomObject -Property @{
                    IPAddress = $Device.Address;
                    Hostname  = $(if ($Device.StatusCode -eq 0) { 
                            try { [System.Net.DNS]::GetHostByAddress($Device.Address).HostName } 
                            catch {} 
                        } 
                        else { 
                            try { [System.Net.DNS]::GetHostByName($Device.Address).HostName } 
                            catch {} 
                        });
                    Status    = $StatusCode;
                }
            }
            else {
                $Return += New-Object -TypeName PSCustomObject -Property @{
                    IPAddress = $Device.Address;
                    Status    = $StatusCode;
                }
            }
        }
    } 
    END {
        if ($OnlineOnly) {
            $Return | Where-Object -Property Status -eq "Online"
        }
        else {
            return $Return
        }
    }
}
