function Export-RegistryKey {
    <#
    .SYNOPSIS
    Exports a registry key to a .reg file, either from the local computer or a remote computer.

    .DESCRIPTION
    This function allows exporting a specified registry key from either a local or remote computer to a .reg file. When run against a remote computer, it creates a PowerShell session and uses `reg.exe` to export the registry key.
    It also provides options for supplying credentials for the remote connection. The exported file can be saved locally or on a remote system.

    .EXAMPLE
    Export-RegistryKey -RegPath "HKCU\AppEvents" -LocalExportPath "$env:USERPROFILE\Desktop\local_reg_export.reg" -Verbose
    "HKLM\SOFTWARE" | Export-RegistryKey -LocalExportPath "$env:USERPROFILE\Desktop\remote_reg_export.reg" -ComputerName "remote_hostname" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.5.4
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Registry path to export, either local or remote")]
        [ValidateNotNullOrEmpty()]
        [Alias("r")]
        [string]$RegPath,

        [Parameter(Mandatory = $true, HelpMessage = "Local path where the exported registry file will be saved")]
        [ValidateNotNullOrEmpty()]
        [Alias("l")]
        [string]$LocalExportPath,

        [Parameter(Mandatory = $false, HelpMessage = "Remote path where the exported registry file will be temporarily saved on the remote computer")]
        [Alias("e")]
        [string]$RemoteExportPath = "C:\Users\Default\AppData\Local\Temp\exported.reg",

        [Parameter(Mandatory = $false, HelpMessage = "Remote computer name for the export operation")]
        [Alias("c")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, HelpMessage = "Username for remote connection")]
        [Alias("u")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for remote connection")]
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
                Write-Verbose "Connecting to remote computer: $ComputerName"
                $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
                $ExportScriptBlock = {
                    param($RegPath, $RemoteExportPath)
                    Start-Process -FilePath 'reg.exe' -ArgumentList 'export', $RegPath, $RemoteExportPath -Wait -NoNewWindow
                }
                Invoke-Command -Session $Session -ScriptBlock $ExportScriptBlock -ArgumentList $RegPath, $RemoteExportPath
                Copy-Item -FromSession $Session -Path $RemoteExportPath -Destination $LocalExportPath -Force
                Invoke-Command -Session $Session -ScriptBlock { Remove-Item -Path $using:RemoteExportPath -Force }
                Write-Host "Registry key exported from remote computer to '$LocalExportPath'" -ForegroundColor Green
            }
            else {
                Write-Error -Message "Failed to connect to remote computer: $ComputerName"
            }
        }
        else {
            Write-Verbose -Message "Exporting registry key from local machine..."
            Start-Process -FilePath 'reg.exe' -ArgumentList 'export', $RegPath, $LocalExportPath -Wait -NoNewWindow
            if (Test-Path $LocalExportPath) {
                Write-Host "Registry key exported to '$LocalExportPath'" -ForegroundColor Green
            }
            else {
                Write-Error -Message "Failed to export registry key to '$LocalExportPath'"
            }
        }
    }
    catch {
        Write-Error -Message "Error occurred: $_"
    }
    finally {
        if ($Session) {
            Write-Verbose -Message "Closing remote session..."
            Remove-PSSession -Session $Session -Verbose
        }
    }
}
