#Requires -Version 3.0
Function Test-Subnet {
    <#
    .SYNOPSIS
    Tests connectivity to a range of IP addresses within a specified subnet.

    .DESCRIPTION
    This function pings a range of IP addresses within a given subnet and provides information about the connectivity.

    .PARAMETER Subnet
    Specifies the subnet to test, must be in the format "xxx.xxx.xxx.0".
    .PARAMETER Range
    The range of IP addresses to test within the subnet, defaults to 1..254.
    .PARAMETER Count
    Number of echo requests to send to each IP address, defaults to 1.
    .PARAMETER Delay
    Time, in seconds, to wait between echo requests, defaults to 1 second.
    .PARAMETER Buffer
    Size of the buffer, in bytes, to use in the echo request, defaults to 32 bytes.
    .PARAMETER TTL
    Time-to-Live value for the echo request, defaults to 80.
    .PARAMETER AsJob
    Run the command as a background job.
    .PARAMETER Resolve
    Resolve the hostnames of the IP addresses.
    .PARAMETER UseNBT
    Use NBTSTAT for hostname resolution when resolving hostnames.
    .PARAMETER Computername
    The computer names or IP addresses to test, defaults to the local machine.

    .EXAMPLE
    Test-Subnet -Subnet "192.168.1.0" -Range 1..10 -Count 2 -Delay 2 -Buffer 64 -TTL 64 -AsJob -Resolve

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(DefaultParameterSetName = "NoResolve")]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidatePattern("\d{1,3}\.\d{1,3}\.\d{1,3}\.0")]
        [string]$Subnet,

        [Parameter(Mandatory = $false, Position = 1)]
        [ValidateRange(1, 254)]
        [int[]]$Range = 1..254,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 10)]
        [int]$Count = 1,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 60)]
        [int]$Delay = 1,

        [Parameter(Mandatory = $false)]
        [ValidateScript({ $_ -ge 1 })]
        [int]$Buffer = 32,

        [Parameter(Mandatory = $false)]
        [ValidateScript({ $_ -ge 1 })]
        [int]$TTL = 80,

        [Parameter(Mandatory = $false)]
        [switch]$AsJob,

        [Parameter(Mandatory = $false, ParameterSetName = "Resolve")]
        [switch]$Resolve,

        [Parameter(Mandatory = $false, ParameterSetName = "Resolve")]
        [switch]$UseNBT,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [string[]]$Computername = $env:COMPUTERNAME
    )
    Write-Verbose -Message "Testing $Subnet"
    $Sb = {
        $ProgHash = @{
            Activity         = "Test Subnet from $($env:ComputerName)"
            Status           = "Pinging"
            CurrentOperation = $null
            PercentComplete  = 0
        }
        Write-Progress @ProgHash
        $i = 0
        $Total = ($using:Range).Count
        foreach ($Node in ($using:Range)) {
            $i++
            $ProgHash.PercentComplete = ($i / $Total) * 100
            $Target = ([Regex]"0$").Replace($using:Subnet, $Node)
            $ProgHash.CurrentOperation = $Target
            Write-Progress @ProgHash
            $PingHash = @{
                ComputerName = $Target
                Count        = $using:count
                Delay        = $using:delay
                BufferSize   = $using:Buffer
                TimeToLive   = $using:ttl
                Quiet        = $true
            }
            $Ping = Test-Connection @PingHash 
            if ($Ping -AND $using:Resolve) {
                $ProgHash.Status = "Resolving host name"
                Write-Progress @ProgHash
                $Hostname = [System.Net.Dns]::Resolve("$Target").Hostname
                if ($UseNBT -AND ($Hostname -eq $Target)) {
                    Write-Verbose -Message "Resolving with NBTSTAT"
                    [Regex]$Rx = "(?<Name>\S+)\s+<00>\s+UNIQUE"                                                              
                    $Nbt = nbtstat -A $Target | Out-String
                    $Hostname = $Rx.Match($Nbt).Groups["Name"].Value    
                }
            }
            else {
                $Hostname = $null
            }
            if ($PSVersionTable.PSVersion.Major -ge 3) {
                $ResultHash = [Ordered]@{
                    IPAddress  = $Target
                    Hostname   = $Hostname
                    Pinged     = $Ping
                    TTL        = $using:TTL
                    Buffersize = $using:Buffer
                    Delay      = $Using:Delay
                    TestDate   = Get-Date
                }
            }
            else {
                $ResultHash = @{
                    IPAddress  = $Target
                    Hostname   = $Hostname
                    Pinged     = $Ping
                    TTL        = $using:TTL
                    Buffersize = $using:Buffer
                    Delay      = $Using:Delay
                    TestDate   = Get-Date
                }
            }
            New-Object -TypeName PSObject -Property $ResultHash
        }
    }
    $IcmHash = @{
        Scriptblock  = $Sb
        Computername = $Computername
    }
    if ($AsJob) {
        Write-Verbose -Message "Creating a background job"
        $IcmHash.Add("AsJob", $true)
        $IcmHash.Add("JobName", "Ping $Subnet") 
    }
    Write-Verbose -Message "Running the command"
    Invoke-Command @IcmHash 
}
