Function Install-OpenSSH {
    <#
    .SYNOPSIS
    Installs OpenSSH on a local or remote computer.

    .DESCRIPTION
    This function is used to install OpenSSH on a local computer or a remote computer, it provides the option to specify various parameters for the installation.

    .PARAMETER ComputerName
    Name of the target computer where OpenSSH will be installed, defaults to the local computer.
    .PARAMETER User
    Username used for remote installation on the target computer.
    .PARAMETER Pass
    Password associated with the provided username for remote installation.
    .PARAMETER InstallerPath
    Path where the OpenSSH installer MSI will be downloaded and stored, defaults to the temporary directory.
    .PARAMETER OpenSSHMsiUrl
    URL of the OpenSSH installer MSI, you can provide "latest" to always download the latest version.

    .EXAMPLE
    Install-OpenSSH -Verbose
    Install-OpenSSH -computerName "remote_host" -username "remote_user" -pass "remote_pass"

    .NOTES
    v0.1.8
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName = $env:COMPUTERNAME,
    
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$User,
    
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Pass,
    
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$InstallerPath = "$env:TEMP\OpenSSH-Win64-v9.5.0.0.msi",
    
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$OpenSSHMsiUrl = "https://github.com/PowerShell/Win32-OpenSSH/releases/download/v9.5.0.0p1-Beta/OpenSSH-Win64-v9.5.0.0.msi"
    )
    try {
        $OSSHName = [System.IO.Path]::GetFileName($OpenSSHMsiUrl)
        Write-Verbose -Message "Installer Path: $InstallerPath"
        Write-Verbose -Message "OpenSSH MSI URL: $OpenSSHMsiUrl"
            
        if ($ComputerName -eq $env:COMPUTERNAME) {
            Write-Host "Installing OpenSSH locally..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri $OpenSSHMsiUrl -OutFile $InstallerPath -ErrorAction Stop -Verbose
            Start-Process -FilePath $InstallerPath -ArgumentList "/passive" -Wait -ErrorAction Stop
        }
        else {
            if (-not $User -or -not $Pass) {
                Write-Error "For remote installation, both username and password are required!"
                return
            }
            $SecPass = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential($User, $SecPass)
            Invoke-WebRequest -Uri $OpenSSHMsiUrl -OutFile $InstallerPath -Verbose
            Write-Host "Copying OpenSSH installer to $ComputerName..." -ForegroundColor Cyan
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
            Copy-Item -Path $InstallerPath -Destination "C:\Users\$User\AppData\Local\Temp\$OSSHName" -ToSession $Session
            Write-Host "Installing OpenSSH on $ComputerName..." -ForegroundColor Cyan
            $InstallScript = {
                param ($Path)
                Start-Process -Wait -FilePath msiexec.exe -ArgumentList "/i `"$Path`" /qn"
            }
            Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock $InstallScript -ArgumentList ("C:\Users\$User\AppData\Local\Temp\$OSSHName")
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
