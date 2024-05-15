function Sync-Time {
    <#
    .SYNOPSIS
    Synchronizes time settings on the local or remote computer.

    .DESCRIPTION
    Sync-Time is a PowerShell function that synchronizes time settings on the local or remote computer. It can configure the Windows Time service startup type, NTP server, time source, time offset, and other time-related settings.

    .EXAMPLE
    Sync-Time -Verbose
    Sync-Time -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass"

    .NOTES
    0.2.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Startup type for the Windows Time service")]
        [ValidateSet("Automatic", "Boot", "Disabled", "Manual", "System")]
        [string]$StartupType = "Automatic",

        [Parameter(Mandatory = $false, HelpMessage = "NTP server to synchronize time with")]
        [ValidateSet("time.nist.gov", "time.windows.com")]
        [string]$NTP_Server = "time.nist.gov",

        [Parameter(Mandatory = $false, HelpMessage = "Time source for the system clock")]
        [ValidateSet("LocalCMOSClock", "NTP", "NoSync")]
        [string]$TimeSource = "NTP",

        [Parameter(Mandatory = $false, HelpMessage = "Time offset in hours, must be a value between -12 and 12")]
        [ValidateRange(-12, 12)]
        [int]$TimeOffset = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Synchronize time on system startup")]
        [bool]$SyncOnStartup = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Specifies whether to set the local time server")]
        [bool]$SetLocalTimeServer = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Forces a time synchronization operation.")]
        [switch]$ForceSync,

        [Parameter(Mandatory = $false, HelpMessage = "Timeout period in seconds for the remote session")]
        [int]$TimeoutSeconds = 30,

        [Parameter(Mandatory = $false, HelpMessage = "Hostname of the remote computer")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, HelpMessage = "Username for remote authentication")]
        [string]$Username,

        [Parameter(Mandatory = $false, HelpMessage = "Password for remote authentication")]
        [string]$Pass
    )
    BEGIN {
        if ($ComputerName) {
            try {
                $Trusted = Get-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction SilentlyContinue | Select-String -Pattern $ComputerName
                if (-not $Trusted) {
                    $AddTrusted = Read-Host "The remote server is not in TrustedHosts. Do you want to add it? (Y/N)"
                    if ($AddTrusted -eq 'Y') {
                        Set-Item WSMan:\localhost\Client\TrustedHosts -Value $ComputerName -Concatenate
                        Write-Host "Added $ComputerName to TrustedHosts."
                    }
                    else {
                        Write-Error "You chose not to add $ComputerName to TrustedHosts. Cannot proceed."
                        return
                    }
                }
                Test-WsMan -ComputerName $ComputerName -ErrorAction Stop
                Write-Host "Test-WsMan successful. WSMan connection is available" -ForegroundColor Green
            }
            catch {
                Write-Error -Message "Test-WsMan failed. Unable to establish WSMan connection to $ComputerName!"
                return
            }
            try {
                $SecPass = ConvertTo-SecureString $Pass -AsPlainText -Force
                $Cred = New-Object System.Management.Automation.PSCredential ($Username, $SecPass)
                $Session = New-PSSession -ComputerName $ComputerName -Credential $Cred -ErrorAction Stop
            }
            catch {
                Write-Error -Message "Failed to establish a remote session, error: $_"
                return
            }
        }
        else {
            $W32tmS = @{
                FilePath    = "w32tm"
                WindowStyle = "Hidden"
                Wait        = $true
            }
            if (!(Get-Service -Name W32Time -ErrorAction SilentlyContinue)) {
                Write-Verbose -Message "Service is missing, installing and starting"
                $W32tmS.ArgumentList = "/register"
                Start-Process @W32tmS
                $Serw32time = Get-Service -Name W32Time
                $Serw32time | Start-Service -Verbose
            }
        }
    }
    PROCESS {
        if ($ComputerName) {
            try {
                $ScriptBlock = {
                    param($NewTime, $ForceSync, $TimeoutSeconds)     
                    if ($ForceSync) {
                        w32tm /resync /force
                    }
                    elseif ($NewTime) {
                        Set-Date $NewTime
                    }
                }
                $Params = @{
                    Session      = $Session
                    ScriptBlock  = $ScriptBlock
                    ArgumentList = $NewTime, $ForceSync, $TimeoutSeconds
                }
                Invoke-Command @Params
            }
            catch {
                Write-Error -Message "Failed to set time on the remote machine, error: $_"
                return
            }
        }
        else {
            Write-Output "Setting service to $StartupType and syncing time."
            Get-Service -Name W32Time | Set-Service -StartupType $StartupType -ErrorAction SilentlyContinue
            $W32tmS.ArgumentList = "/resync /force"
            Start-Process @W32tmS
            $W32tmS.ArgumentList = "/config /update /manualpeerlist:`"$NTP_Server,0x8`" /syncfromflags:manual"
            Start-Process @W32tmS
            $W32tmS.ArgumentList = "/config /update /reliable:yes /timesource:`"$TimeSource`" /offset:$TimeOffset"
            Start-Process @W32tmS -ErrorAction SilentlyContinue
            if ($SyncOnStartup -eq $true) {
                $W32tmS.ArgumentList = "/config /update /syncfromflags:manual /manualpeerlist:$NTP_Server"
                Start-Process @W32tmS
            }
            if ($SetLocalTimeServer -eq $true) {
                $W32tmS.ArgumentList = "/config /update /localclock"
                Start-Process @W32tmS
            }
            $Serw32time | Stop-Service -NoWait -PassThru -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 5
            $Serw32time | Start-Service -ErrorAction SilentlyContinue
            $W32tmS.ArgumentList = "/resync /rediscover"
            Start-Process @W32tmS
        }
    }
    END {
        if ($Session) {
            try {
                Remove-PSSession $Session -ErrorAction SilentlyContinue
            }
            catch {
                Write-Error -Message "Failed to close the remote session, error: $_"
            }
        }
        if ($Cred) {
            $Cred = $null
            [System.GC]::Collect()
        }
        Write-Verbose -Message "Time sync finished, current time: $(Get-Date)"
    }
}
