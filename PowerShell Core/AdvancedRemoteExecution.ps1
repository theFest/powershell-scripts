Class ComputerCredentials {
    [string]$HostName
    [string]$Username
    [SecureString]$Password
    ComputerCredentials(
        [string]$HostName,
        [string]$Username,
        [PSCredential]$Password) {
        $this.HostName = $HostName
        $this.Username = $Username
        $this.Password = $Password.Password
    }
}
Function AdvancedRemoteExecution {
    <#
    .SYNOPSIS
    Execute commands and scripts via various types of deployments.
    
    .DESCRIPTION
    With this function can be used to deploy to targets from dictionary file, headers of .csv file should be 'Hostname', 'Username'and 'Password'.
    
    .PARAMETER ExecutionMethod
    NotMandatory - pick a type of execution method. 
    .PARAMETER ComputerInventoryFile
    Mandatory - target machine/s.
    .PARAMETER ExecutionCommand
    Mandatory - command, cmdlet or script. 
    .PARAMETER Protocol
    NotMandatory - choose protocol you want to use.
    .PARAMETER Class
    NotMandatory - choose class, default present, others unimplemented atm.
    .PARAMETER Method
    NotMandatory - choose method of a class, for now you can create or terminate a process.
    .PARAMETER Authentication
    NotMandatory - choose authentication type from validate set.
    .PARAMETER OperationTimeoutSec
    NotMandatory - timeout for the operation, script or command.
    .PARAMETER Port
    NotMandatory - choose port you wanna use.
    .PARAMETER SkipTestConnection
    NotMandatory - use to speed up execution. 
    .PARAMETER EncryptionKey
    NotMandatory - still untested.
    .PARAMETER Encoding
    NotMandatory - not yet fully implemented
    .PARAMETER Delimiter
    NotMandatory - default is set to comma, choose otherwise if your .csv file has other.
    .PARAMETER AsJob
    NotMandatory - partially implemented for now.
    
    .EXAMPLE
    $ExecutionCommand = "Stop-Service -Name Spooler -NoWait -Force"
    AdvancedRemoteExecution -ExecutionCommand "$ExecutionCommand" -ComputerInventoryFile "$env:USERPROFILE\Desktop\list.csv" -ExecutionMethod CIM -AsJob
    
    .NOTES
    1.0.1
    #>
    [CmdletBinding(DefaultParameterSetName = "AdvancedRemoteExecution")]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("CIM", "WMI", "PSRemoting", "PSSession", "DCOM", "PsExec", "PaExec")]
        [string]$ExecutionMethod,

        [Parameter(Mandatory = $false)]
        [string]$ComputerInventoryFile,
    
        [Parameter(Mandatory = $true)]
        [string]$ExecutionCommand,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Default", "Dcom", "Wsman")]
        [string]$Protocol = "Default",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Process", "Property")]
        [string]$Class = "Process",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Create", "Terminate")]
        [string]$Method = "Create",
    
        [Parameter(Mandatory = $false, HelpMessage = "Authentication type used for the user's credentials")]
        [ValidateSet("Basic", "Default", "Negotiate", "Digest", "CredSsp", "Kerberos", "NtlmDomain")]
        [string]$Authentication = "Negotiate",

        [Parameter(Mandatory = $false, HelpMessage = "Duration for which the cmdlet waits for a response from the server")]
        [ValidateRange(0, 3)]
        [int]$OperationTimeoutSec = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Default ports are 5985 (WinRM>HTTP) and 5986 (WinRM>HTTPS")]
        [ValidateSet(5985, 5986)]
        [int]$Port,

        [Parameter(Mandatory = $false, HelpMessage = "To reduce some data transmission time use this switch")]
        [switch]$SkipTestConnection,

        [Parameter(Mandatory = $false)]
        [string]$EncryptionKey,
    
        [Parameter(Mandatory = $false)]
        [ValidateSet("UTF8", "UTF32", "UTF7", "ASCII", "BigEndianUnicode", "Default", "OEM")]
        [string]$Encoding = "UTF8",
    
        [Parameter(Mandatory = $false)]
        [string]$Delimiter = ",",
    
        [switch]$AsJob
    )
    BEGIN {
        $StartTime = Get-Date
        Start-Transcript -Path "$env:TEMP\CIMSessionExecutions.txt" -Force -Verbose
        Set-Location -Path "WSMan:\localhost\Client" -PassThru
        WinRM set winrm/config/client '@{AllowUnencrypted="true"}'       
        if (!(Test-Path -Path "$env:TEMP\PSTools")) {
            Invoke-WebRequest -Uri "https://download.sysinternals.com/files/PSTools.zip" -OutFile "$env:TEMP\PSTools.zip" -Verbose
            Expand-Archive -Path "$env:TEMP\PSTools.zip" -DestinationPath "$env:TEMP\PSTools" -Force -Verbose
        }
        Write-Verbose -Message "PsExec downloaded, trying to enable WinRM..."
        if ($ComputerInventoryFile) {
            $Computers = Import-Csv -Path $ComputerInventoryFile `
            | ForEach-Object {
                $Hostname = $_.Hostname
                $Username = $_.Username
                $Password = ConvertTo-SecureString $_.Password -AsPlainText -Force
                $SecCreds = New-Object System.Management.Automation.PSCredential ($Username, $Password)
                [PSCustomObject]@{
                    HostName   = $Hostname
                    Username   = $Username
                    Credential = $SecCreds
                }
            }
            $Results = @()
            $OnlineC = @()
            $Computers | ForEach-Object {
                $PingResults = Test-Connection -ComputerName $_.Hostname -Count 1 -AsJob
                Write-Host $_.Hostname
                Wait-Job -Job $PingResults -Verbose
                $PingResults = Receive-Job -Job $PingResults
                $Result = [PSCustomObject]@{
                    HostName = $_.Hostname
                    Status   = if ($PingResults.StatusCode -eq 0) { 
                        "Online" 
                    }
                    else { 
                        "Offline" 
                    }
                }
                $Results += $Result
                if ($PingResults.StatusCode -eq 0) {
                    $OnlineC += $_
                }
            }
            $Results | Export-Csv -Path "$env:USERPROFILE\Desktop\pingResults.csv" -Force -NoTypeInformation
            $Results | Format-Table -Property HostName, Status
            $PingResultJob = Get-Job | Write-Output
            $PingResultJob | Remove-Job -Force -Verbose
            foreach ($Computer in $OnlineC) {
                $CompExecHost = $Computer.Hostname
                $CompExecUser = $Computer.Username
                $CompExecPass = $Computer.Credential
                Set-Item -Path "WSMan:\localhost\Client\TrustedHosts" $Computer.Hostname -Concatenate -Force
                if (!(Test-WSMan -ComputerName $Computer.Hostname -Credential $Computer.Credential -Authentication Default -ErrorAction SilentlyContinue)) {
                    $CommandLine = "Powershell Start-Process Powershell -ArgumentList 'Enable-PSRemoting -Force -SkipNetworkProfileCheck ; WinRM QuickConfig -Force -Quiet'"
                    $SpSb = {
                        param($CompExecHost, $CompExecUser, $CompExecPass, $CommandLine)
                        Start-Process -FilePath "$env:TEMP\PSTools\PsExec.exe" -ArgumentList "\\$CompExecHost -u $CompExecUser -p $CompExecPass -s -d -i -accepteula $CommandLine" -WindowStyle Normal -Wait
                    }
                    $SpJob = Start-Job -ScriptBlock $SpSb -ArgumentList $Computer.Hostname, $Computer.Username, $Computer.Credential.GetNetworkCredential().Password, $CommandLine
                    Start-Sleep -Seconds 3            
                    Write-Verbose -Message "Job executing, waiting for it to complete..."
                    Get-Job -Name * -Verbose
                    Wait-Job $SpJob -Verbose | Receive-Job -Wait -WriteEvents -Verbose
                }
            }
        }
    }
    PROCESS {
        switch ($ExecutionMethod) {
            "CIM" {
                foreach ($Computer in $Computers) {
                    $ScriptBlockInvoke = { "Powershell -ExecutionPolicy Bypass -Command $ExecutionCommand" }
                    Write-Host CIM
                    $SessionArgs = @{
                        Computer      = $Computer.HostName
                        Credential    = $Computer.Credential
                        SessionOption = New-CimSessionOption -Protocol $Protocol 
                        #Port                = $Port
                        #Authentication      = $Authentication 
                        #SkipTestConnection  = $SkipTestConnection
                        #OperationTimeoutSec = $OperationTimeoutSec
                    }
                    $MethodArgs = @{
                        ClassName  = "Win32_$Class" 
                        MethodName = $Method
                        CimSession = New-CimSession @SessionArgs
                        Arguments  = @{
                            CommandLine = Invoke-Command -ScriptBlock $ScriptBlockInvoke
                        }
                    }
                    if ($AsJob) {
                        $execjob = { Invoke-CimMethod @MethodArgs }
                        Invoke-Command -ScriptBlock $execjob #-AsJob
                    }
                    else {
                        Invoke-CimMethod @MethodArgs -Verbose
                    }
                }
            }
            "WMI" {
                $Connection = New-CimInstance -ComputerName $Computer.HostName -Credential $Computer.Credential
                Invoke-WmiMethod -InputObject $Connection -Name $ExecutionCommand
            }
            "PSRemoting" {
                $Session = New-PSSession -ComputerName $Computer.HostName -Credential $Computer.Credential
                Invoke-Command -Session $Session -ScriptBlock { $ExecutionCommand }
                Remove-PSSession $Session
            }
            "PSSession" {
                $Session = New-PSSession -ComputerName $Computer.HostName -Credential $Computer.Credential
                Invoke-Command -Session $Session -ScriptBlock { $ExecutionCommand }
                Remove-PSSession $Session
            }
            "DCOM" {
                $Connection = New-Object -ComObject $ExecutionCommand -ArgumentList $Computer.HostName, $Computer.Credential
                $Connection.Execute()
            }
            "PsExec" {
                PsExec.exe \$Computer.HostName -u $Computer.Username -p $Computer.Password $ExecutionCommand
            }
            "PaExec" {
                PaExec.exe \$Computer.HostName -u $Computer.Username -p $Computer.Password $ExecutionCommand
            }
        }
    }
    END {
        Get-Job -Verbose | Remove-Job -Verbose
        Set-Location -Path $env:SystemDrive
        Write-Host "Finished, cleaning up, stopping transcript and exiting..." -ForegroundColor Cyan
        Get-CimSession | Remove-CimSession -Verbose
        Clear-Variable -Name RemoteComputerUser, RemoteComputerPass -Force -Verbose
        Write-Output "`nTime taken [$((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")]"
        Clear-History -Verbose
        Stop-Transcript
        if ($EncryptionKey) {
            Encrypt-File -Path "$env:USERPROFILE\Desktop\executionResults.csv" -EncryptionKey $EncryptionKey
        }
    }
}