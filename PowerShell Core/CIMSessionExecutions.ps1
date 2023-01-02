Function CIMSessionExecutions {
    <#
    .SYNOPSIS
    Execute scripts via CIM session on multiple machines.

    .DESCRIPTION
    This function for example can be used to execute script, also provides output from remote computers.

    .PARAMETER ComputerName
    Mandatory - target machine/s.
    .PARAMETER RemoteComputerUser
    Mandatory - user of the target machines.
    .PARAMETER RemoteComputerPass
    Mandatory - password on target machines.
    .PARAMETER ScriptBlock
    Mandatory - scriptblock your commands on a remote computers, for example url to your script and execution.
    .PARAMETER Protocol
    NotMandatory - choose protocol you want to use.
    .PARAMETER Authentication
    NotMandatory - choose authentication type from set.
    .PARAMETER Class
    NotMandatory - choose class, default present, others unimplemented atm.
    .PARAMETER Method
    NotMandatory - choose method of a class, for now you can create or terminate a process.
    .PARAMETER OperationTimeoutSec
    NotMandatory - timeout for the operation, script or command.
    .PARAMETER Port
    NotMandatory - choose port you wanna use.
    .PARAMETER SkipTestConnection
    NotMandatory - use to speed up execution.

    .EXAMPLE
    $ScriptBlock = { Invoke-WebRequest https://www.timesynctool.com/NetTimeSetup-320a3.exe -UseBasicParsing -OutFile $env:TEMP\NetTimeSetup-320a3.exe }
    CIMSessionExecutions -ScriptBlock $ScriptBlock -ComputerName $ComputerNames -RemoteComputerUser "your_user" -RemoteComputerPass "your_pass"

    .NOTES
    v0.9
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $false, HelpMessage = "Specify targets")]
        [System.String]$ComputerName,

        [Parameter(Mandatory = $true, HelpMessage = "Username used for the target machine")]
        [string]$RemoteComputerUser,

        [Parameter(Mandatory = $true, HelpMessage = "Password used for the target machine")]
        [string]$RemoteComputerPass,

        [Parameter(Mandatory = $true, HelpMessage = "Enter commands you wanna execute on remote machine")]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false, HelpMessage = "Choose the protocol to use for CIM session")]
        [ValidateSet('Default', 'Dcom', 'Wsman')]
        [string]$Protocol = 'Wsman',

        [Parameter(Mandatory = $false, HelpMessage = "Authentication type used for the user's credentials")]
        [ValidateSet("Basic", "Default", "Negotiate", "Digest", "CredSsp", "Kerberos", "NtlmDomain")]
        [string]$Authentication = "Negotiate",

        [Parameter(Mandatory = $false, HelpMessage = "Enter name of Azure Resource for API App / Web App")]
        [ValidateSet("Process", "Property")]
        [string]$Class = "Process",

        [Parameter(Mandatory = $false, HelpMessage = "Enter name of Azure Resource for API App / Web App")]
        [ValidateSet("Create", "Terminate")]
        [string]$Method = "Create",

        [Parameter(Mandatory = $false, HelpMessage = "Duration for which the cmdlet waits for a response from the server")]
        [ValidateRange(0, 3)]
        [int]$OperationTimeoutSec = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Default ports are 5985 (WinRM>HTTP) and 5986 (WinRM>HTTPS")]
        [ValidateSet(5985, 5986)]
        [int]$Port,

        [Parameter(Mandatory = $false, HelpMessage = "To reduce some data transmission time use this switch")]
        [switch]$SkipTestConnection
    )
    BEGIN {
        $StartTime = Get-Date
        $ErrorActionPreference = "Stop"
        Start-Transcript -Path "$env:TEMP\CIMSessionExecutions.txt" -Force -Verbose
        $SecRemotePassword = ConvertTo-SecureString -AsPlainText $RemoteComputerPass -Force
        $SecuredCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $RemoteComputerUser, $SecRemotePassword
        if (Test-WSMan -ComputerName $ComputerName -Authentication $Authentication -Credential $SecuredCredentials -Verbose) {
            Write-Host "WinRM is configured on remote computer..." -ForegroundColor Green
        }
        Write-Host "Setting WinRM on remote host..." -ForegroundColor Cyan ; winrm set winrm/config/client '@{AllowUnencrypted="true"}'
        if (Get-WSManInstance -ResourceURI wmicimv2/win32_service -SelectorSet @{name = "winrm" } -Fragment Status -ComputerName $ComputerName -Credential $SecuredCredentials) {
            Write-Host "WinRM service is running on remote computer..." -ForegroundColor Green
        }
        $CheckLocal = Get-WSManInstance -ResourceURI wmicimv2/win32_service -SelectorSet @{name = "winrm" } -ComputerName $env:COMPUTERNAME
        Write-Host "Checking and setting WinRM on local machine..." -ForegroundColor Cyan
        Set-Location -Path WSMan:\localhost\Client -PassThru -Verbose | winrm get winrm/config
        Write-Host "Getting Interface Index from local ethernet NIC..." -ForegroundColor Cyan
        $NetIndex = (Get-NetAdapter -Name "Ethernet" -Physical -IncludeHidden).InterfaceIndex
        Write-Host "Setting network profile to Private..."
        Set-NetConnectionProfile -InterfaceIndex $NetIndex -NetworkCategory Private
        if ($CheckLocal) {
            Write-Host "WinRM service is running on local computer..." -ForegroundColor Green
        }
        Write-Host "Setting remote computer to TrustedHosts..." -ForegroundColor Green
        Set-Item WSMan:\localhost\Client\TrustedHosts -Value $ComputerName -Force -Verbose
    }
    PROCESS {
        $ScriptBlock = {
            Write-Verbose "Setting PS ScriptBlock..."
            "Powershell -ExecutionPolicy Bypass -Command '$ScriptBlock'"
        }
        $SessionArgs = @{
            ComputerName        = $ComputerName
            SessionOption       = New-CimSessionOption -Protocol $Protocol
            Port                = $Port 
            Authentication      = $Authentication
            SkipTestConnection  = $SkipTestConnection
            OperationTimeoutSec = $OperationTimeoutSec
        }
        $MethodArgs = @{
            ClassName  = "Win32_$Class" 
            MethodName = $Method
            CimSession = New-CimSession @SessionArgs -Credential $SecuredCredentials
            Namespace  = "root\cimv2"
            Arguments  = @{
                CommandLine = Invoke-Command -ScriptBlock $ScriptBlock
            }
        }
        foreach ($Computer in $ComputerName) {
            Write-Verbose "Connecting to $Computer..."
            try {
                Invoke-CimMethod @MethodArgs -Verbose
            }
            catch {
                Write-Error "Error occurred when executing script on $Computer $($_.Exception.Message)"
            }
        }
    }
    END {
        Write-Host "Finished, cleaning up, stopping transcript and exiting..." -ForegroundColor Cyan
        #Get-CimSession | Remove-CimSession -verbose
        Clear-Variable -Name RemoteComputerUser, RemoteComputerPass -Force -Verbose
        Write-Output "`nTime taken [$((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")]"
        Clear-History -Verbose
        Stop-Transcript
    }
}