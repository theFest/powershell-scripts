function RemoteExportRegKey {
    <#
    .SYNOPSIS
    Exports a registry key from a remote or local computer.

    .DESCRIPTION
    This function exports a specified registry key from a remote or local computer and saves it to a specified local path.

    .PARAMETER RegPath
    Specifies the registry path to export, either local or remote.
    .PARAMETER LocalExportPath
    Specifies the local path where the exported registry file will be saved.
    .PARAMETER RemoteExportPath
    Specifies the remote path where the exported registry file will be temporarily saved on the remote computer, if not provided, a default path will be used.
    .PARAMETER ComputerName
    Specifies the name of the remote computer from which to export the registry key, if not provided, the export will be performed on the local computer.
    .PARAMETER Username
    Specifies the username to use for the remote connection, required when exporting from a remote computer.
    .PARAMETER Pass
    Specifies the password to use for the remote connection, required when exporting from a remote computer.

    .EXAMPLE
    RemoteExportRegKey -RegPath "HKCU\AppEvents" -LocalExportPath "$env:USERPROFILE\Desktop\AppEvents.reg" -Verbose
    "HKCU\you_key\you_subkey" | RemoteExportRegKey -LocalExportPath "$env:USERPROFILE\Desktop\you_subkey.reg" -ComputerName "remote_hostname" -Username "remote_user" -Pass "remote_pass"

    .NOTES
    Version: 0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RegPath,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$LocalExportPath,

        [Parameter(Mandatory = $false)]
        [string]$RemoteExportPath = "C:\Users\Default\AppData\Local\Temp\exported.reg",

        [Parameter(Mandatory = $false)]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [string]$Pass
    )
    try {
        $Session = $null
        if ($ComputerName) {
            $TestConnectionScriptBlock = {
                param($Using:ComputerName)
                $isReachable = (Test-Connection -ComputerName $Using:ComputerName -Count 1 -Quiet) -and (Test-WSMan -ComputerName $Using:ComputerName -Authentication Default)
                if ($isReachable) {
                    Write-Host "Connection to the remote computer '$Using:ComputerName' established..." -ForegroundColor Green
                }
                else {
                    Write-Host "Failed to establish a connection to the remote computer '$Using:ComputerName'" -ForegroundColor Red 
                }
                $isReachable
            }
            $isComputerReachable = Invoke-Command -ComputerName $ComputerName -ScriptBlock $TestConnectionScriptBlock -Credential (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, (ConvertTo-SecureString -String $Pass -AsPlainText -Force))
            if ($isComputerReachable) {
                $Session = New-PSSession -ComputerName $ComputerName -Credential (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, (ConvertTo-SecureString -String $Pass -AsPlainText -Force))
                $ExportScriptBlock = {
                    param($RegPath, $RemoteExportPath)
                    Write-Verbose -Message "Export on the remote computer has started..."
                    Start-Process -FilePath 'reg.exe' -ArgumentList 'export', $RegPath, $RemoteExportPath -Wait -NoNewWindow
                }
                $ExportJob = Invoke-Command -Session $Session -AsJob -ScriptBlock $ExportScriptBlock -ArgumentList $RegPath, $RemoteExportPath
                Wait-Job $ExportJob | Out-Null ; Receive-Job $ExportJob | Out-Null
                Copy-Item -FromSession $Session -Path $RemoteExportPath -Destination $LocalExportPath -Force -Verbose
                Invoke-Command -Session $Session -ScriptBlock {
                    param($RemoteExportPath)
                    Remove-Item -Path $RemoteExportPath -Force
                } -ArgumentList $RemoteExportPath
            }
            else {
                Write-Error -Message "Failed to establish a connection to the remote computer '$ComputerName'"
            }
        }
        else {
            Write-Verbose -Message "Export on the local computer has started..."
            Start-Process -FilePath 'reg.exe' -ArgumentList 'export', $RegPath, $LocalExportPath -Wait -NoNewWindow
        }
        if (Test-Path $LocalExportPath) {
            Write-Host "Registry key exported to '$LocalExportPath'" -ForegroundColor Green
        }
        else {
            Write-Error -Message "Failed to export the registry key"
        }
    }
    catch {
        Write-Error -Message $_.Exception.Message
    }
    finally {
        if ($Session) {
            Write-Verbose -Message "Finished, closing PS Session and exiting..."
            Remove-PSSession -Session $Session -Verbose -ErrorAction SilentlyContinue
        }
    }
}
