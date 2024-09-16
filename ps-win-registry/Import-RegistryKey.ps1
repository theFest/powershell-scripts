function Import-RegistryKey {
    <#
    .SYNOPSIS
    Imports a registry key from a .reg file, either to the local computer or to a remote computer.

    .DESCRIPTION
    This function allows importing a registry key from a specified .reg file into the local or remote computer. If a remote computer is specified, it transfers the registry file to the remote system, imports it using `reg.exe`, and cleans up the temporary file.

    .EXAMPLE
    Import-RegistryKey -ImportPath "$env:USERPROFILE\Desktop\local_reg_export.reg" -Verbose
    Import-RegistryKey -ImportPath "$env:USERPROFILE\Desktop\local_reg_export.reg" -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.5.4
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specifies the local path of the registry key to be imported")]
        [ValidateNotNullOrEmpty()]
        [Alias("i")]
        [string]$ImportPath,

        [Parameter(Mandatory = $false, HelpMessage = "Temporary path on the remote computer where the registry key will be stored before importing")]
        [Alias("r")]
        [string]$RemoteImportPath = "C:\Users\Default\AppData\Local\Temp\import.reg",

        [Parameter(Mandatory = $false, HelpMessage = "Name of the remote computer where the registry key will be imported")]
        [Alias("c")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, HelpMessage = "User account used for authentication when connecting to the remote computer")]
        [Alias("u")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for the user account used for authentication")]
        [Alias("p")]
        [string]$Pass
    )
    try {
        $Session = $null
        if ($ComputerName) {
            $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecurePassword
            $IsComputerReachable = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
            if ($IsComputerReachable) {
                Write-Verbose -Message "Connecting to remote computer: $ComputerName"
                $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
                $ImportScriptBlock = {
                    param($Path)
                    Start-Process -FilePath 'reg.exe' -ArgumentList 'import', $Path -Wait -NoNewWindow
                }
                Write-Verbose -Message "Copying registry file to remote computer..."
                Copy-Item -Path $ImportPath -Destination $RemoteImportPath -ToSession $Session -Force
                Write-Verbose -Message "Starting registry import on remote computer..."
                Invoke-Command -Session $Session -ScriptBlock $ImportScriptBlock -ArgumentList $RemoteImportPath
                Invoke-Command -Session $Session -ScriptBlock {
                    param($Path)
                    Remove-Item -Path $Path -Force -Verbose
                } -ArgumentList $RemoteImportPath
                Write-Host "Registry key successfully imported on remote computer '$ComputerName' from '$ImportPath'" -ForegroundColor Green
            }
            else {
                Write-Error -Message "Failed to connect to remote computer: $ComputerName"
            }
        }
        else {
            Write-Verbose -Message "Importing registry key on local machine..."
            Start-Process -FilePath 'reg.exe' -ArgumentList 'import', $ImportPath -Wait -NoNewWindow
            if (Test-Path $ImportPath) {
                Write-Host "Registry key successfully imported on local machine from '$ImportPath'" -ForegroundColor Green
            }
            else {
                Write-Error -Message "Failed to import registry key from '$ImportPath'"
            }
        }
    }
    catch {
        Write-Error -Message "Error occurred: $_"
    }
    finally {
        if ($Session) {
            Write-Verbose -Message "Closing remote session..."
            Remove-PSSession -Session $Session
        }
    }
}
