Function Import-RegistryKey {
    <#
    .SYNOPSIS
    Imports a registry key from a local or remote machine.
    
    .DESCRIPTION
    This function allows you to import a registry key from either a local or remote machine.
    It establishes a remote PowerShell session if the ComputerName parameter is provided, copies the registry file to the remote machine, imports the registry key using the 'reg.exe' command, and removes the copied file afterwards. If no ComputerName is specified, the function imports the registry key locally.
    
    .PARAMETER ImportPath
    Mandatory - path to the registry file that needs to be imported. This parameter is mandatory.
    .PARAMETER ComputerName
    NotMandatory - name of the remote computer from which to import the registry key. This parameter is not mandatory. If provided, a remote session will be established.
    .PARAMETER Username
    NotMandatory - username for authentication when connecting to a remote computer. This parameter is not mandatory and is only required when the ComputerName parameter is provided.
    .PARAMETER Password
    NotMandatory - password for authentication when connecting to a remote computer. This parameter is not mandatory and is only required when the ComputerName parameter is provided.
    
    .EXAMPLE
    Import-RegistryKey -ImportPath "$env:USERPROFILE\Desktop\import.reg" -ComputerName "remote_hostname" -Username "remote_user" -Password "remote_pass" -Verbose
    
    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ImportPath,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string]$Username,
        
        [Parameter(Mandatory = $false)]
        [string]$Password
    )
    try {
        if ($ComputerName) {
            $Session = New-PSSession -ComputerName $ComputerName -Credential (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, (ConvertTo-SecureString -String $Password -AsPlainText -Force))
            $TestConnectionScriptBlock = {
                (Test-Connection -ComputerName $Using:ComputerName -Count 1 -Quiet) -and (Test-WSMan -ComputerName $Using:ComputerName -Authentication Default)
            }
            $isComputerReachable = Invoke-Command -Session $Session -ScriptBlock $TestConnectionScriptBlock
            if ($isComputerReachable) {
                $ImportScriptBlock = {
                    param($Path)
                    Start-Process -FilePath 'reg.exe' -ArgumentList 'import', $Path -Wait -NoNewWindow
                }
                $RemoteImportPath = "C:\Users\Default\AppData\Local\Temp\import.reg"
                Copy-Item -Path $ImportPath -Destination $RemoteImportPath -ToSession $Session -Force -Verbose
                Invoke-Command -Session $Session -ScriptBlock $ImportScriptBlock -ArgumentList $RemoteImportPath
                Invoke-Command -Session $Session -ScriptBlock {
                    param($Path)
                    Remove-Item $Path -Force
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
