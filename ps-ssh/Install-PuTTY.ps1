Function Install-PuTTY {
    <#
    .SYNOPSIS
    Installs PuTTY on a local or remote computer.

    .DESCRIPTION
    This function installs PuTTY on a local computer or a remote computer, allowing for specifying various parameters such as ComputerName, User, Pass, InstallerPath, and PuTTYMsiUrl.

    .PARAMETER ComputerName
    Name of the target computer where PuTTY will be installed, if not provided, PuTTY will be installed locally.
    .PARAMETER User
    Username used for remote installation on the target computer.
    .PARAMETER Pass
    Password associated with the provided username for remote installation.
    .PARAMETER InstallerPath
    Path where the PuTTY installer will be downloaded and stored, defaults to the temporary directory.
    .PARAMETER PuTTYMsiUrl
    URL of the PuTTY installer, you can provide "latest" to always download the latest version.

    .EXAMPLE
    Install-PuTTY
    Install-PuTTY -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

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
        [string]$InstallerPath = "$env:TEMP\putty-64bit-0.80-installer.msi",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$PuTTYMsiUrl = "https://the.earth.li/~sgtatham/putty/0.80/w64/putty-64bit-0.80-installer.msi"
    )
    try {
        $PuTTYName = [System.IO.Path]::GetFileName($PuTTYMsiUrl)
        if (-not $ComputerName) {
            Write-Host "Installing PuTTY locally..." -ForegroundColor Cyan
            Invoke-WebRequest -Uri $PuTTYMsiUrl -OutFile $InstallerPath -ErrorAction Stop -Verbose
            Start-Process -FilePath $InstallerPath -ArgumentList "/passive" -Wait -ErrorAction Stop
        }
        else {
            if (-not ($User -and $Pass)) {
                throw "For remote installation, both username and password are required!"
            }
            $SecPass = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential($User, $SecPass)
            Write-Host "Copying PuTTY installer to $ComputerName..." -ForegroundColor Cyan
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
            Invoke-WebRequest -Uri $PuTTYMsiUrl -OutFile $InstallerPath -ErrorAction Stop -Verbose
            Copy-Item -Path $InstallerPath -Destination "C:\Users\$User\AppData\Local\Temp\$PuTTYName" -ToSession $Session -ErrorAction Stop -Verbose
            Write-Host "Installing PuTTY on $ComputerName..." -ForegroundColor Cyan
            Invoke-Command -Session $Session -ScriptBlock {
                param($Path)
                Start-Process -Wait -FilePath $Path -ErrorAction Stop
            } -ArgumentList "C:\Users\$User\AppData\Local\Temp\$PuTTYName"
        }
        Write-Host "PuTTY installed successfully" -ForegroundColor Green
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
