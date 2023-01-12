#requires -version 5.1
Function CIMSessionExecution {
    <#
    .SYNOPSIS
    Execute commands/scripts via CIM session.
    
    .DESCRIPTION
    This advanced Function can be used to execute commands to remote computer, now includes PsExec.
    
    .PARAMETER User
    Mandatory - user of the target machine.
    .PARAMETER Pass
    Mandatory - password on target machine.
    .PARAMETER Computer
    Mandatory - hostname of remote computer, you can add via pipeline.
    .PARAMETER ScriptBlock
    Mandatory - execute your command on a remote computer, either via example or custom one. 
    .PARAMETER Protocol
    NotMandatory - choose between those declared in validate param. set, default is predifened. 
    .PARAMETER Class
    NotMandatory - choose class, default(Process) is already declared, others unimplemented atm.
    .PARAMETER Method
    NotMandatory - choose method type of the class, for now you can create a process, terminate still under dev.
    .PARAMETER Authentication
    NotMandatory - type of authentication type you want to used fore remote machine.
    .PARAMETER OperationTimeoutSec
    NotMandatory - duration for which the cmdlet waits for a response from the server.
    .PARAMETER Port
    NotMandatory - default ports are 5985 (WinRM>HTTP) and 5986 WinRM>HTTPS, predefined is http.
    .PARAMETER SkipTestConnection
    NotMandatory - use this switch to test target connection prior to remote script execution.
    .PARAMETER WaitTime
    NotMandatory - define how second do you want to wait before restart, after actual exection finishes.
    .PARAMETER RestartTime
    NotMandatory - if planning to restart and wait for and e.g. PowerShell session, use this parametar to define how much do you wanna wait for restart.
    .PARAMETER WaitPS
    NotMandatory - if planning to restart and wait for and e.g. PowerShell session, use this parametar to say for how much do you wanna wait after execution and restart.
    
    .EXAMPLE
    $ScriptBlock = "Stop-Service -Name Spooler -Force" 
    CIMSessionExecution -Computer "your_computer_hostname" -User "your_user" -Pass "your_pass" -ScriptBlock $ScriptBlock -Verbose
    CIMSessionExecution -Computer "your_computer_hostname" -User "your_user" -Pass "your_pass" -ScriptBlock $ScriptBlock -RestartTime 10 -Verbose
    
    .NOTES
    v1.9
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$User,

        [Parameter(Mandatory = $true)]
        [string]$Pass,
 
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Computer,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Default", "Dcom", "Wsman")]
        [string]$Protocol = "Default",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Process", "Property")]
        [string]$Class = "Process",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Create", "Terminate")]
        [string]$Method = "Create",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Basic", "Default", "Negotiate", "Digest", "CredSsp", "Kerberos", "NtlmDomain")]
        [string]$Authentication = "Negotiate",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 3)]
        [int]$OperationTimeoutSec = 3,

        [Parameter(Mandatory = $false)]
        [ValidateSet(5985, 5986)]
        [int]$Port = 5985,

        [Parameter(Mandatory = $false)]
        [switch]$SkipTestConnection,

        [Parameter(Mandatory = $false)]
        [int]$WaitTime = 60,

        [Parameter(Mandatory = $false)]
        [int]$RestartTime,

        [Parameter(Mandatory = $false)]
        [int]$WaitPS = 300
    )
    BEGIN {
        $StartTime = Get-Date
        $SecRemotePassword = ConvertTo-SecureString -AsPlainText $Pass -Force
        $SecuredCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecRemotePassword
        if ((Get-Service -Name WinRM).Status -eq "Running") {
            Write-Verbose -Message "WinRM service is running on local computer..."
        }
        else {
            Write-Warning -Message "WinRM service is not running on local computer, setting up..."
            Set-WSManQuickConfig -Force -SkipNetworkProfileCheck
            Enable-PSRemoting -Force -SkipNetworkProfileCheck -Verbose
        }
        Write-Verbose -Message "Getting Interface Index from local ethernet NIC..."
        $NetIndex = (Get-NetAdapter -Name "Ethernet" -Physical -IncludeHidden).InterfaceIndex
        if (!(Get-NetConnectionProfile -InterfaceIndex $NetIndex).NetworkCategory -eq "Private") {
            Write-Warning -Message "Setting network profile to Private..."
            Set-NetConnectionProfile -InterfaceIndex $NetIndex -NetworkCategory Private -Verbose
        }
    }
    PROCESS {
        Write-Verbose -Message "Adding computer to TrustedHosts list and preparing..."
        Set-Item -Path "WSMan:\localhost\Client\TrustedHosts" $Computer -Concatenate -Force -Verbose
        Set-Location -Path "WSMan:\localhost\Client" -PassThru
        WinRM set winrm/config/client '@{AllowUnencrypted="true"}'
        Write-Verbose -Message "Checking Win version and WinRM on remote host..."
        if (!(Test-WSMan -ComputerName $Computer -Authentication Default -Credential $SecuredCredentials -ErrorAction SilentlyContinue)) {
            Write-Warning -Message "WinRM is not configured on remote computer: $Computer, configuring..."
            Invoke-WebRequest -Uri "https://download.sysinternals.com/files/PSTools.zip" -OutFile "$env:TEMP\PSTools.zip" -Verbose
            Expand-Archive -Path "$env:TEMP\PSTools.zip" -DestinationPath "$env:TEMP\PSTools" -Force -Verbose
            Write-Verbose -Message "PsExec downloaded, trying to enable WinRM..."
            $CommandLine = "Powershell Start-Process Powershell -ArgumentList 'Enable-PSRemoting -Force -SkipNetworkProfileCheck ; WinRM QuickConfig -Force -Quiet'"
            $SpSb = {
                param($Computer, $User, $Pass, $CommandLine)
                Start-Process -FilePath "$env:TEMP\PSTools\PsExec.exe" -ArgumentList "\\$Computer -u $User -p $Pass -s -d -accepteula $CommandLine" -WindowStyle Hidden -Wait
            }
            $SpJob = Start-Job -ScriptBlock $SpSb -ArgumentList $Computer, $User, $Pass, $CommandLine
            Write-Verbose -Message "Job executing, waiting for it to complete..."
            Wait-Job $SpJob -Verbose | Receive-Job -Wait
            Write-Warning -Message "Pausing for $WaitTime seconds, then continuing..." ; Start-Sleep -Seconds $WaitTime
            try {
                if (Get-WSManInstance -ResourceURI wmicimv2/win32_Service -SelectorSet @{ name = "winrm" } `
                        -Fragment Status -ComputerName $Computer -Credential $SecuredCredentials) {
                    Write-Verbose -Message "Remote computer is prepared, continuing..."
                }
            }
            catch [System.InvalidOperationException] {
                Write-Error -Message "Invalid Operation $_"
            }
            catch [System.UnauthorizedAccessException] {
                Write-Error -Message "Unauthorized access $_"
            }
            catch {
                Write-Error -Message "An exception occurred: $_"
            }
        }
        Write-Verbose -Message "Setting PS Cim ScriptBlock..."
        $ScriptBlockInvoke = { "Powershell -ExecutionPolicy Bypass -Command $ScriptBlock" }
        $SessionArgs = @{
            Computer            = $Computer
            Credential          = $SecuredCredentials
            SessionOption       = New-CimSessionOption -Protocol $Protocol
            Port                = $Port
            Authentication      = $Authentication 
            SkipTestConnection  = $SkipTestConnection
            OperationTimeoutSec = $OperationTimeoutSec
        }
        $MethodArgs = @{
            ClassName  = "Win32_$Class" 
            MethodName = $Method
            CimSession = New-CimSession @SessionArgs
            Arguments  = @{
                CommandLine = Invoke-Command -ScriptBlock $ScriptBlockInvoke
            }
        }
        Write-Verbose -Message "Detecting Windows version on remote computer: $Computer"
        $OsRCh = Invoke-Command -ComputerName $Computer -Credential $SecuredCredentials -ScriptBlock { [Environment]::OSVersion.Version.Major } -Authentication Default
        if ($OsRCh -match "10") {
            Write-Verbose -Message "Windows version detected: $OsRCh"
            #pause
            try {
                Write-Verbose -Message "Executing given command on Windows 10..."
                Invoke-CimMethod @MethodArgs -Verbose
            }
            catch {
                Write-Error "Error occurred when executing script on $Computer $($_.Exception.Message)"
            }
        }
        elseif ($OsRCh -match "6") {
            Write-Warning -Message "Windows version detected: $OsRCh"
            #pause
            try {
                Write-Verbose -Message "Executing given command on Windows 7..."
                Invoke-CimMethod @MethodArgs -Verbose
            }
            catch {
                Write-Error "Error occurred when executing script on $Computer $($_.Exception.Message)"
            }
        }
        else {
            throw "Other version of Windows detected: $OsRCh!"
        }
        if ($RestartTime) {
            Write-Warning -Message "Restarting computer in $RestartTime seconds!"
            $Lenght = $RestartTime / 100
            for ($RestartTime; $RestartTime -gt -1; $RestartTime--) {
                $Time = [int](([string]($RestartTime / 60)).Split('.')[0])
                Write-Progress -Activity "Restarting in..." -Status "$Time minutes $RestartTime seconds left" -PercentComplete ($RestartTime / $Lenght)
                Start-Sleep -Seconds 1
            }
            Restart-Computer -ComputerName $Computer -Impersonation Impersonate -DcomAuthentication PacketIntegrity -Credential $SecuredCredentials -Wait -For PowerShell -Timeout $WaitPS -Delay 2 -Force
        }
    }
    END {
        Write-Verbose -Message "Finished, cleaning up, stopping transcript and exiting..."
        Get-CimSession | Remove-CimSession -Verbose
        Remove-WSManInstance -ResourceURI "winrm/config/listener" -SelectorSet @{ Address = "*" ; Transport = "http" }
        $WinRMTH = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value 
        foreach ($TH in $WinRMTH) {
            Write-Warning -Message "Removing values from Trusted Hosts..." ; $TH = ""
            Set-Item -Path "WSMan:\localhost\Client\TrustedHosts" -Value $TH -PassThru -Force -Verbose
        }
        WinRM set winrm/config/client '@{AllowUnencrypted="false"}'
        if (Test-WSMan) {
            $WinRMs = Get-Service -Name WinRM
            $WinRMs | Stop-Service -Force -NoWait -PassThru -Verbose `
            | Set-Service -StartupType Disabled -Verbose
        }
        Set-Location -Path $env:SystemDrive
        Get-Job -Verbose | Remove-Job -Force -Verbose
        Remove-Item -Path "$env:TEMP\PSTools" -Recurse -WhatIf
        Clear-Variable -Name User, Pass, Computer -Force -Verbose
        Clear-History -Verbose
        Write-Verbose -Message "Finished, stopping transcript and exiting!"
        return "`nTime taken [$((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")]"
    }
}