Function Install-OpenSSH {
    <#
    .SYNOPSIS
    Install OpenSSH function installs OpenSSH on a local or remote computer.

    .DESCRIPTION
    This function is used to install OpenSSH on a local computer or a remote computer. It provides the option to specify various parameters for the installation.

    .PARAMETER ComputerName
    NotMandatory - name of the target computer where OpenSSH will be installed. Defaults to the local computer.
    .PARAMETER Username
    NotMandatory - username used for remote installation on the target computer.
    .PARAMETER Pass
    NotMandatory - password associated with the provided username for remote installation.
    .PARAMETER InstallerPath
    NotMandatory - path where the OpenSSH installer MSI will be downloaded and stored. Defaults to the temporary directory.
    .PARAMETER OpenSSHMsiUrl
    NotMandatory - URL of the OpenSSH installer MSI. You can provide "latest" to always download the latest version.
    .EXAMPLE
    
    Install-OpenSSH
    Install-OpenSSH -computerName "remote_host" -username "remote_user" -pass "remote_pass"

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Pass,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$InstallerPath = "$env:TEMP\OpenSSHInstaller.msi",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$OpenSSHMsiUrl = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.2.2.0p1-Beta/OpenSSH-Win64-v9.2.2.0.msi"
    )
    try {
        if ($ComputerName -eq $env:COMPUTERNAME) {
            Write-Host "Installing OpenSSH locally..." -ForegroundColor Cyan
            Start-Process -Wait -FilePath msiexec.exe -ArgumentList "/i `"$InstallerPath`" /qn"
        }
        else {
            if (-not $Username -or -not $Pass) {
                Write-Error "For remote installation, both username and password are required."
                return
            }
            $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential($Username, $SecurePassword)
            Invoke-WebRequest -Uri $OpenSSHMsiUrl -OutFile $InstallerPath
            Write-Host "Copying OpenSSH installer to $ComputerName..." -ForegroundColor Cyan
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
            Copy-Item -Path $InstallerPath -Destination "C:\Users\$Username\AppData\Local\Temp\OpenSSHInstaller.msi" -ToSession $Session
            Write-Host "Installing OpenSSH on $ComputerName..." -ForegroundColor Cyan
            $InstallScript = {
                param ($Path)
                Start-Process -Wait -FilePath msiexec.exe -ArgumentList "/i `"$Path`" /qn"
            }
            Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock $InstallScript -ArgumentList ("C:\Users\$Username\AppData\Local\Temp\OpenSSHInstaller.msi")
        }
        Write-Host "OpenSSH installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Error -Message "Error: $_"
    }
    finally {
        if ($Session) {
            Remove-PSSession $Session -Verbose
        }
        Remove-Item -Path $InstallerPath -Force -Verbose -ErrorAction SilentlyContinue
    }
}
    