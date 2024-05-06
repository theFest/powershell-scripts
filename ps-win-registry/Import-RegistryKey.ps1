Function Import-RegistryKey {
    <#
    .SYNOPSIS
    Imports a registry key from a local or remote machine.

    .DESCRIPTION
    This function imports a registry key from a specified location to either the local computer or a remote computer.
    It establishes a remote PowerShell session if the ComputerName parameter is provided, copies the registry file to the remote machine, imports the registry key using the 'reg.exe' command, and removes the copied file afterwards. If no ComputerName is specified, the function imports the registry key locally.

    .PARAMETER ImportPath
    Specifies the path of the registry key to be imported.
    .PARAMETER RemoteImportPath
    Path where the registry key will be temporarily stored on the remote computer before importing.
    .PARAMETER ComputerName
    Name of the remote computer where the registry key will be imported.
    .PARAMETER User
    User account to be used for authentication when connecting to the remote computer.
    .PARAMETER Pass
    Password for the user account used for authentication.

    .EXAMPLE
    Import-RegistryKey -ImportPath "$env:USERPROFILE\Desktop\import.reg" -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -Verbose

    .NOTES
    v0.1.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specifies the local path of the registry key to be imported")]
        [ValidateNotNullOrEmpty()]
        [Alias("i")]
        [string]$ImportPath,

        [Parameter(Mandatory = $false, HelpMessage = "Specifies the temporary path on the remote computer where the registry key will be stored before importing")]
        [Alias("r")]
        [string]$RemoteImportPath = "C:\Users\Default\AppData\Local\Temp\import.reg",

        [Parameter(Mandatory = $false, HelpMessage = "Specifies the name of the remote computer where the registry key will be imported")]
        [Alias("c")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, HelpMessage = "Specifies the user account used for authentication when connecting to the remote computer")]
        [Alias("u")]
        [string]$User,
        
        [Parameter(Mandatory = $false, HelpMessage = "Specifies the password for the user account used for authentication")]
        [Alias("p")]
        [string]$Pass
    )
    try {
        if ($ComputerName) {
            $Session = New-PSSession -ComputerName $ComputerName -Credential (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (ConvertTo-SecureString -String $Pass -AsPlainText -Force))
            $TestConnectionScriptBlock = {
                (Test-Connection -ComputerName $Using:ComputerName -Count 1 -Quiet) -and (Test-WSMan -ComputerName $Using:ComputerName -Authentication Default)
            }
            $isComputerReachable = Invoke-Command -Session $Session -ScriptBlock $TestConnectionScriptBlock
            if ($isComputerReachable) {
                $ImportScriptBlock = {
                    param($Path)
                    Start-Process -FilePath 'reg.exe' -ArgumentList 'import', $Path -Wait -NoNewWindow
                }
                Copy-Item -Path $ImportPath -Destination $RemoteImportPath -ToSession $Session -Force -Verbose
                Invoke-Command -Session $Session -ScriptBlock $ImportScriptBlock -ArgumentList $RemoteImportPath
                Invoke-Command -Session $Session -ScriptBlock {
                    param($Path)
                    Remove-Item $Path -Force -Verbose
                } -ArgumentList $RemoteImportPath
            }
            else {
                Write-Error -Message "Failed to establish a connection to the remote computer '$ComputerName'."
            }
        }
        else {
            Start-Process -FilePath 'reg.exe' -ArgumentList 'import', $ImportPath -Wait -NoNewWindow
        }
        Write-Host "Registry key imported from '$ImportPath'." -ForegroundColor Green
    }
    catch {
        Write-Error -Message $_.Exception.Message
    }
    finally {
        if ($Session) {
            Remove-PSSession -Session $Session -Verbose
        }
    }
}
