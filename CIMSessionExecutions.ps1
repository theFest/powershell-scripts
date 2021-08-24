Function CIMSessionExecutions {
    <#
    .SYNOPSIS
    Execute scripts via CIM session on multiple machines.
    
    .DESCRIPTION
    This function for example can be used to execute script, also provides output from remote computers.
    
    .PARAMETER User
    Mandatory - user of the target machines.
    .PARAMETER Password
    Mandatory - password on target machines.
    .PARAMETER ComputersList
    Mandatory - CSV list of computers. Header should be defined as 'Name' or whatever you like.
    .PARAMETER Header
    Mandatory - declare your CSV header, choose the name that you want. In this example it's 'Name'.
    .PARAMETER Class
    NotMandatory - choose class, default present, others unimplemented atm.
    .PARAMETER Method
    NotMandatory - choose method of a class, for now you can create or terminate a process.
    .PARAMETER ExecuteCommand
    Mandatory - execute or terminate your command on a remote computers, for example url to your script and execution.
    
    .EXAMPLE
    CIMSessionExecutions -User "your_user" -Password "your_pass" -Header Name -ComputersList C:\your_csv_path\computers.txt -ExecuteCommand 'powershell -executionpolicy bypass -Command "Invoke-WebRequest https://path_to_your_script/your_script.ps1 -UserAgent "your_secret" -UseBasicParsing -OutFile $env:TEMP\Script.ps1; & Invoke-Expression $env:TEMP\Script.ps1'    
    
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
        [string]$Password,
 
        [Parameter(Mandatory = $true)]
        [string]$ComputersList,

        [Parameter(Mandatory = $true)]
        [string]$Header,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Process', 'Property')]
        [string]$Class = 'Process',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Create', 'Terminate')]
        [string]$Method = 'Create',

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ExecuteCommand
    )
    $Pass = ConvertTo-SecureString -AsPlainText $Password -Force
    $SecureCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass
    $Computers = Import-Csv -Path $ComputersList -Header $Header
    $SessionArgs = @{
        ComputerName  = $Computers.$Header
        Credential    = Get-Credential -Credential $SecureCredentials
        SessionOption = New-CimSessionOption -Protocol Dcom
    }
    $MethodArgs = @{
        ClassName  = "Win32_$Class"
        MethodName = "$Method"
        CimSession = New-CimSession @SessionArgs
        Arguments  = @{
            CommandLine = $ExecuteCommand
        }
    }
    foreach ($Computer in $ComputersList) {
        Invoke-CimMethod @MethodArgs
    }
}
