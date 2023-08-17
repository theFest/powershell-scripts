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
    0.1.2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Method of remote execution.")]
        [ValidateSet("CIM", "WMI", "PSRemoting", "PSSession", "DCOM", "PsExec", "SSH")]
        [string]$ExecutionMethod,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the CSV file containing computer inventory")]
        [string]$ComputerInventoryFile,
    
        [Parameter(Mandatory = $true, HelpMessage = "Command to execute remotely")]
        [string]$ExecutionCommand,

        [Parameter(Mandatory = $false, HelpMessage = "Protocol to use for remote execution")]
        [ValidateSet("Default", "Dcom", "Wsman")]
        [string]$Protocol = "Default",

        [Parameter(Mandatory = $false, HelpMessage = "WMI class name for CIM execution")]
        [ValidateSet("Process", "Property")]
        [string]$Class = "Process",

        [Parameter(Mandatory = $false, HelpMessage = "Method to use for CIM execution")]
        [ValidateSet("Create", "Terminate")]
        [string]$Method = "Create",

        [Parameter(Mandatory = $false, HelpMessage = "Authentication type for remote execution")]
        [ValidateSet("Basic", "Default", "Negotiate", "Digest", "CredSsp", "Kerberos", "NtlmDomain")]
        [string]$Authentication = "Negotiate",

        [Parameter(Mandatory = $false, HelpMessage = "Duration to wait for a response from the server")]
        [ValidateRange(0, 3)]
        [int]$OperationTimeoutSec = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Port for remote execution")]
        [ValidateSet(5985, 5986)]
        [int]$Port,

        [Parameter(Mandatory = $false, HelpMessage = "Skip testing the connection before execution")]
        [switch]$SkipTestConnection,
    
        [Parameter(Mandatory = $false, HelpMessage = "Encoding for the output")]
        [ValidateSet("UTF8", "UTF32", "UTF7", "ASCII", "BigEndianUnicode", "Default", "OEM")]
        [string]$Encoding = "UTF8",
    
        [Parameter(Mandatory = $false, HelpMessage = "Delimiter for output")]
        [string]$Delimiter = ",",
    
        [Parameter(Mandatory = $false, HelpMessage = "Use if executing via CIM")]
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
                    try {
                        $SessionArgs = @{
                            Computer      = $Computer.HostName
                            Credential    = $Computer.Credential
                            SessionOption = New-CimSessionOption -Protocol $Protocol
                        }
                        $CimSession = New-CimSession @SessionArgs
                        $MethodArgs = @{
                            ClassName  = "Win32_$Class"
                            MethodName = $Method
                            CimSession = $CimSession
                            Arguments  = @{
                                CommandLine = $ExecutionCommand
                            }
                        }
                        if ($AsJob) {
                            $JobScriptBlock = {
                                param ($CimMethodArgs)
                                Invoke-CimMethod @CimMethodArgs
                            }
                            $JobArgs = @($MethodArgs)
                            Start-Job -ScriptBlock $JobScriptBlock -ArgumentList $JobArgs
                        }
                        else {
                            Invoke-CimMethod @MethodArgs
                        }
                        Remove-CimSession $CimSession
                        $Result = [PSCustomObject]@{
                            Computer = $Computer.HostName
                            Status   = "Success"
                        }
                        $Results += $Result
                    }
                    catch {
                        $ErrorResult = [PSCustomObject]@{
                            Computer = $Computer.HostName
                            Status   = "Error: $_"
                        }
                        $Results += $ErrorResult
                    }
                }
            }            
            "WMI" {
                foreach ($Computer in $Computers) {
                    try {
                        $ConnectionOptions = New-Object System.Management.ConnectionOptions
                        $ConnectionOptions.Username = $Computer.Credential.UserName
                        $ConnectionOptions.Password = $Computer.Credential.GetNetworkCredential().Password
                        $ManagementScope = New-Object System.Management.ManagementScope("\\$($Computer.HostName)\root\cimv2", $ConnectionOptions)
                        $ManagementScope.Connect()
                        $Query = "SELECT * FROM Win32_Process WHERE Name = '$ExecutionCommand'"
                        $QueryOptions = New-Object System.Management.ObjectQueryOptions
                        $ManagementObjectSearcher = New-Object System.Management.ManagementObjectSearcher($ManagementScope, $Query, $QueryOptions)
                        $Results = $ManagementObjectSearcher.Get()
                        $Result = [PSCustomObject]@{
                            Computer = $Computer.HostName
                            Status   = "Success"
                            Count    = $Results.Count
                        }
                        $Results += $Result
                    }
                    catch {
                        $ErrorResult = [PSCustomObject]@{
                            Computer = $Computer.HostName
                            Status   = "Error: $_"
                        }
                        $Results += $ErrorResult
                    }
                }
            }
            "PSRemoting" {
                foreach ($Computer in $Computers) {
                    try {
                        $Session = New-PSSession -ComputerName $Computer.HostName -Credential $Computer.Credential
                        Invoke-Command -Session $Session -ScriptBlock {
                            param ($Command)
                            Invoke-Expression $Command
                        } -ArgumentList $ExecutionCommand
                        Remove-PSSession $Session              
                        $Result = [PSCustomObject]@{
                            Computer = $Computer.HostName
                            Status   = "Success"
                        }
                    }
                    catch {
                        $Result = [PSCustomObject]@{
                            Computer = $Computer.HostName
                            Status   = "Error: $_"
                        }
                    }
                    $Results += $Result
                }
            }
            "PSSession" {
                foreach ($Computer in $Computers) {
                    try {
                        $Session = New-PSSession -ComputerName $Computer.HostName -Credential $Computer.Credential
                        $ScriptBlock = {
                            param ($Command)
                            Invoke-Expression $Command
                        }                    
                        Invoke-Command -Session $Session -ScriptBlock $ScriptBlock -ArgumentList $ExecutionCommand             
                        Remove-PSSession $Session           
                        $Result = [PSCustomObject]@{
                            Computer = $Computer.HostName
                            Status   = "Success"
                        }
                    }
                    catch {
                        $Result = [PSCustomObject]@{
                            Computer = $Computer.HostName
                            Status   = "Error: $_"
                        }
                    }
                    $Results += $Result
                }                
            }
            "DCOM" {
                foreach ($Computer in $Computers) {
                    try {
                        $WmiConnectionOptions = New-Object System.Management.ConnectionOptions
                        $WmiConnectionOptions.Username = $Computer.Credential.UserName
                        $WmiConnectionOptions.Password = $Computer.Credential.GetNetworkCredential().Password
                        $WmiScope = New-Object System.Management.ManagementScope("\\$($Computer.HostName)\root\cimv2", $WmiConnectionOptions)
                        $WmiScope.Connect()
                        $WmiClass = New-Object System.Management.ManagementClass($WmiScope, (New-Object System.Management.ManagementPath("Win32_Process")), $null)
                        $WmiProcess = $WmiClass.CreateInstance()
                        $WmiProcess.Create($ExecutionCommand)
                        $Result = [PSCustomObject]@{
                            Computer = $Computer.HostName
                            Status   = "Success"
                        }
                        $Results += $Result
                    }
                    catch {
                        $ErrorResult = [PSCustomObject]@{
                            Computer = $Computer.HostName
                            Status   = "Error: $_"
                        }
                        $Results += $ErrorResult
                    }
                }
            }
            "PsExec" {
                foreach ($Computer in $Computers) {
                    try {
                        $PsExecPath = "$env:TEMP\PSTools\PsExec.exe"
                        $PsExecArgs = "\\$($Computer.HostName) -u $($Computer.Credential.UserName) -p $($Computer.Credential.GetNetworkCredential().Password) $ExecutionCommand"
                        Start-Process -FilePath $PsExecPath -ArgumentList $PsExecArgs -Wait
                        $Result = [PSCustomObject]@{
                            Computer = $Computer.HostName
                            Status   = "Success"
                        }
                        $Results += $Result
                    }
                    catch {
                        $ErrorResult = [PSCustomObject]@{
                            Computer = $Computer.HostName
                            Status   = "Error: $_"
                        }
                        $Results += $ErrorResult
                    }
                }
            }
            "SSH" {
                if (-not (Get-Module -Name Posh-SSH -ListAvailable)) {
                    Write-Verbose "Installing Posh-SSH module..."
                    Install-Module -Name Posh-SSH -Force
                }
                foreach ($Computer in $Computers) {
                    try {
                        $SSHSession = New-SSHSession -ComputerName $Computer.HostName -Credential $Computer.Credential
                        $SSHResult = Invoke-SSHCommand -SSHSession $SSHSession -Command $ExecutionCommand
                        Remove-SSHSession -SSHSession $SSHSession
                        $Result = [PSCustomObject]@{
                            Computer = $Computer.HostName
                            Status   = "Success"
                            Output   = $SSHResult.Output
                        }
                        $Results += $Result
                    }
                    catch {
                        $ErrorResult = [PSCustomObject]@{
                            Computer = $Computer.HostName
                            Status   = "Error: $_"
                        }
                        $Results += $ErrorResult
                    }
                }
            }
        }
    }
    END {
        Get-Job -ErrorAction SilentlyContinue -Verbose | Remove-Job -ErrorAction SilentlyContinue -Verbose
        Set-Location -Path $env:SystemDrive
        Write-Host "Finished, cleaning up, stopping transcript and exiting..." -ForegroundColor Cyan
        Get-CimSession | Remove-CimSession -ErrorAction SilentlyContinue -Verbose
        Clear-Variable -Name RemoteComputerUser, RemoteComputerPass -Force -Verbose
        Write-Output "`nTime taken [$((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")]"
        Clear-History -Verbose
        Stop-Transcript
    }
}
