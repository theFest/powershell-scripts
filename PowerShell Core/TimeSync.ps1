Function TimeSync {
    <#
    .SYNOPSIS
    This function is syncing time.

    .DESCRIPTION
    This function starts Windows Time service. Creates a service if one is not present.
    After it sets it service to the specified startup type, then resyncs time and outputs the results. It also allows the user to specify a time offset, a time source, whether to sync time on startup, whether to set the time server as the local time server, and the level of verbosity.
    Additionally, it uses splatting by default when calling the `w32tm` command, which makes the script more readable and maintainable.

    .PARAMETER StartupType
    The startup type of the Windows Time service. Possible values are Automatic, Boot, Disabled, Manual, and System. Default is Automatic.
    .PARAMETER NTP_Server
    The NTP server to use for time synchronization. Possible values are time.nist.gov and time.windows.com. Default is time.nist.gov.
    .PARAMETER TimeSource
    The time source to use for time synchronization. Possible values are 'LocalCMOSClock', 'NTP', and 'NoSync'. Default is 'NTP'.
    .PARAMETER TimeOffset
    The time offset to use for time synchronization. Default is 0.
    .PARAMETER SyncOnStartup
    Whether to sync time on startup. Default is $false.
    .PARAMETER SetLocalTimeServer
    Whether to set the time server as the local time server. Default is $false.
    .PARAMETER Verbosity
    The level of verbosity. Possible values are 'Silent', 'Verbose', and 'Debug'. Default is 'Silent'.
    
    .EXAMPLE
    TimeSync -StartupType Automatic -NTP_Server time.nist.gov -TimeSource NTP -TimeOffset 0 -SyncOnStartup $true -SetLocalTimeServer $true -Verbosity Verbose

    .NOTES
    v1.1
    #>
    [CmdletBinding()]
    Param(
        [ValidateSet('Automatic', 'Boot', 'Disabled', 'Manual', 'System')]
        [string]$StartupType = 'Automatic',

        [ValidateNotNullOrEmpty()]
        [ValidateSet('time.nist.gov', 'time.windows.com')]
        [string]$NTP_Server = 'time.nist.gov',

        [ValidateSet('LocalCMOSClock', 'NTP', 'NoSync')]
        [string]$TimeSource = 'NTP',

        [ValidateRange(-12, 12)]
        [int]$TimeOffset = 0,

        [ValidateSet("True", "False")]
        [bool]$SyncOnStartup = $false,

        [ValidateSet("True", "False")]
        [bool]$SetLocalTimeServer = $false,

        [ValidateSet("Silent", "Verbose", "Debug")]
        [string]$Verbosity = "Silent"
    )
    BEGIN {
        $W32tmS = @{
            FilePath    = "w32tm"
            WindowStyle = "Hidden"
            Wait        = $true
        }
        if (!(Get-Service -Name W32Time -ErrorAction SilentlyContinue)) {
            Write-Verbose -Message 'Service is missing, installing and starting.'
            $W32tmS.ArgumentList = "/register"
            Start-Process @W32tmS
            $Serw32time = Get-Service -Name W32Time
            $Serw32time | Start-Service -Verbose
        }
    }
    PROCESS {
        Write-Output 'Setting service to Automatic and syncing time.'
        Get-Service -Name W32Time | Set-Service -StartupType $StartupType
        $W32tmS.ArgumentList = "/resync /force"
        Start-Process @W32tmS
        $W32tmS.ArgumentList = "/config /update /manualpeerlist:`"$NTP_Server,0x8`" /syncfromflags:manual"
        Start-Process @W32tmS
        $W32tmS.ArgumentList = "/config /update /reliable:yes /timesource:`"$TimeSource`" /offset:$TimeOffset"
        Start-Process @W32tmS
        if ($SyncOnStartup -eq $true) {
            $W32tmS.ArgumentList = "/config /update /syncfromflags:manual /manualpeerlist:$NTP_Server"
            Start-Process @W32tmS
        }
        if ($SetLocalTimeServer -eq $true) {
            $W32tmS.ArgumentList = "/config /update /localclock"
            Start-Process @W32tmS
        }
        $Serw32time | Stop-Service -NoWait -PassThru -Force
        Start-Sleep -Seconds 5
        $Serw32time | Start-Service -Verbose
        $W32tmS.ArgumentList = "/resync /rediscover"
        Start-Process @W32tmS
    }
    END {
        if ($Verbosity -eq "Verbose") {
            Write-Output (w32tm /query /status)
        }
        Write-Verbose -Message "Time sync finished."
    }
}