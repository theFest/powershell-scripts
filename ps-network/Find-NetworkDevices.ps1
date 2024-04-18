Function Find-NetworkDevices {
    <#
    .SYNOPSIS
    Scans local network devices to check their online/offline status, hostname, and ping time.

    .DESCRIPTION
    This function performs a network scan within a specified subnet range to identify local devices, it uses PowerShell runspaces for parallel execution to improve performance.

    .PARAMETER Subnet
    Specifies the subnet to scan, default is "192.168.0".
    .PARAMETER StartIP
    Specifies the starting IP address for the scan range, default is 1.
    .PARAMETER EndIP
    Specifies the ending IP address for the scan range, default is 254.
    .PARAMETER TimeoutMilliseconds
    Specifies the timeout in milliseconds for the ICMP ping request, default is 500.

    .EXAMPLE
    Find-NetworkDevices -Subnet "192.168.1" -StartIP 1 -EndIP 100 -TimeoutMilliseconds 300 -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Subnet = "192.168.0",

        [Parameter(Mandatory = $false)]
        [int]$StartIP = 1,

        [Parameter(Mandatory = $false)]
        [int]$EndIP = 254,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutMilliseconds = 500
    )
    BEGIN {
        Write-Verbose "Initializing...please wait..."
        $Results = @()
        $RunspacePool = [runspacefactory]::CreateRunspacePool(1, [Environment]::ProcessorCount)
        $RunspacePool.Open()
        $Runspaces = @()
    }
    PROCESS {
        foreach ($i in $StartIP..$EndIP) {
            $Ip = "$Subnet.$i"
            $Runspace = [powershell]::Create().AddScript({
                    param($Ip, $TimeoutMilliseconds)
                    $Ping = New-Object System.Net.NetworkInformation.Ping
                    $PingResult = $Ping.Send($Ip, $TimeoutMilliseconds)
                    if ($PingResult.Status -eq 'Success') {
                        try {
                            $Hostname = [System.Net.Dns]::GetHostEntry($Ip).HostName
                        }
                        catch {
                            $Hostname = "N/A"
                        }
                        $Status = "Online"
                        $PingTime = $PingResult.RoundtripTime
                    }
                    else {
                        $Hostname = "N/A"
                        $Status = "Offline"
                        $PingTime = $null
                    }
                    $Details = @{
                        IP       = $Ip
                        Hostname = $Hostname
                        Status   = $Status
                        PingTime = $PingTime
                    }
                    $Details
                }).AddArgument($Ip).AddArgument($TimeoutMilliseconds)
            $Runspace.RunspacePool = $RunspacePool
            $Runspaces += [PSCustomObject]@{
                Pipe = $Runspace
                Ip   = $Ip
            }
        }
        $Runspaces | ForEach-Object {
            $Result = $_.Pipe.BeginInvoke()
            $_ | Add-Member -MemberType NoteProperty -Name "AsyncResult" -Value $Result
        }
        $Runspaces | ForEach-Object {
            $Details = $_.Pipe.EndInvoke($_.AsyncResult)
            $_.Pipe.Dispose()
            $Results += $Details
            Write-Verbose "Device [$($Details.IP)] scanned. Status: $($Details.Status), Hostname: $($Details.Hostname), PingTime: $($Details.PingTime) ms"
        }
    }
    END {
        Write-Progress -Activity "Scanning for devices" -Status "Completed" -Completed
        $RunspacePool.Close()
        $RunspacePool.Dispose()
        $Results
    }
}
