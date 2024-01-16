Function Import-RegistryKey {
    <#
    .SYNOPSIS
    Imports a registry key from a local or remote machine.
    
    .DESCRIPTION
    This function allows you to import a registry key from either a local or remote machine.
    It establishes a remote PowerShell session if the ComputerName parameter is provided, copies the registry file to the remote machine, imports the registry key using the 'reg.exe' command, and removes the copied file afterwards. If no ComputerName is specified, the function imports the registry key locally.
    
    .PARAMETER ImportPath
    Mandatory - path to the registry file that needs to be imported.
    .PARAMETER ComputerName
    NotMandatory - name of the remote computer from which to import the registry key, if provided, a remote session will be established.
    .PARAMETER User
    NotMandatory - username for authentication when connecting to a remote computer, only required when the ComputerName parameter is provided.
    .PARAMETER Pass
    NotMandatory - password for authentication when connecting to a remote computer, only required when the ComputerName parameter is provided.
    
    .EXAMPLE
    Import-RegistryKey -ImportPath "$env:USERPROFILE\Desktop\import.reg" -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -Verbose
    
    .NOTES
    v0.0.4
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [Alias("i")]
        [ValidateNotNullOrEmpty()]
        [string]$ImportPath,

        [Parameter(Mandatory = $false)]
        [Alias("r")]
        [string]$RemoteImportPath = "C:\Users\Default\AppData\Local\Temp\import.reg",

        [Parameter(Mandatory = $false)]
        [Alias("c")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [Alias("u")]
        [string]$User,
        
        [Parameter(Mandatory = $false)]
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
