Function Install-WinSCP {
    <#
    .SYNOPSIS
    Installs WinSCP on a local or remote computer.

    .DESCRIPTION
    This function installs WinSCP on a local computer or a remote computer, allows for specifying various parameters such as ComputerName, User, Pass, InstallerPath, and WinSCPExeUrl.

    .PARAMETER ComputerName
    Name of the target computer where WinSCP will be installed, if not provided, WinSCP will be installed locally.
    .PARAMETER User
    Username used for remote installation on the target computer.
    .PARAMETER Pass
    Password associated with the provided username for remote installation.
    .PARAMETER InstallerPath
    Path where the WinSCP installer will be downloaded and stored, defaults to the temporary directory.
    .PARAMETER WinSCPExeUrl
    URL of the WinSCP installer, you can provide "latest" to always download the latest version.

    .EXAMPLE
    Install-WinSCP
    Install-WinSCP -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$Pass,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$InstallerPath = "$env:TEMP\WinSCP-6.1.2.msi",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$WinSCPExeUrl = "https://winscp.net/download/files/202402110407ce3a7f5e2facd16827774a96b75cbde3/WinSCP-6.1.2.msi"
    )
    try {
        $WinSCPName = [System.IO.Path]::GetFileName($WinSCPExeUrl)
        if (-not $ComputerName) {
            Write-Host "Installing WinSCP locally..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri $WinSCPExeUrl -OutFile $InstallerPath -ErrorAction Stop -Verbose
            Start-Process -Wait -FilePath $InstallerPath -ErrorAction Stop
        }
        else {
            if (-not ($User -and $Pass)) {
                throw "For remote installation, both username and password are required."
            }
            $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential($User, $SecurePassword)
            Write-Host "Copying WinSCP installer to $ComputerName..." -ForegroundColor Cyan
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
            Invoke-WebRequest -Uri $WinSCPExeUrl -OutFile $InstallerPath -ErrorAction Stop -Verbose
            Copy-Item -Path $InstallerPath -Destination "C:\Users\$User\AppData\Local\Temp\$WinSCPName" -ToSession $Session -ErrorAction Stop -Verbose
            Write-Host "Installing WinSCP on $ComputerName..." -ForegroundColor Cyan
            Invoke-Command -Session $Session -ScriptBlock {
                param($Path)
                Start-Process -Wait -FilePath $Path -ErrorAction Stop
            } -ArgumentList "C:\Users\$User\AppData\Local\Temp\$WinSCPName"
        }
        Write-Host "WinSCP installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Error -Message "Error: $_"
    }
    finally {
        if ($Session) {
            Remove-PSSession $Session -Verbose
        }
        if (Test-Path -Path $InstallerPath) {
            Remove-Item -Path $InstallerPath -Force -Verbose
        }
    }
}
