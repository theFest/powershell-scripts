Function Install-RSATandADTools {
    <#
    .SYNOPSIS
    Installs Remote Server Administration Tools (RSAT) and Active Directory Tools.

    .DESCRIPTION
    This function installs Remote Server Administration Tools (RSAT) and Active Directory Tools on the local or a remote computer using WinRM.

    .PARAMETER DownloadVersion
    Version of RSAT to download and install. Valid values are "Old" (default) and "New".
    .PARAMETER InstallPath
    Path where the RSAT installer file will be downloaded and executed. Default is "$env:TEMP".
    .PARAMETER ComputerName
    Name of the remote computer where RSAT will be installed.
    .PARAMETER User
    Username to use for authentication on the remote computer.
    .PARAMETER Pass
    Password to use for authentication on the remote computer.

    .EXAMPLE
    Install-RSATandADTools -DownloadVersion New -Verbose
    Install-RSATandADTools -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.4.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Old", "New")]
        [string]$DownloadVersion = "Old",

        [Parameter(Mandatory = $false)]
        [string]$InstallPath = "$env:TEMP",

        [Parameter(Mandatory = $false)]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Pass
    )
    try {
        if ($ComputerName) {
            $SessionParams = @{
                ComputerName = $ComputerName
                Credential   = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, ($Pass | ConvertTo-SecureString -AsPlainText -Force)
            }
            $Session = New-PSSession @SessionParams
            Invoke-Command -Session $Session -ScriptBlock {
                param ($DownloadVersion, $InstallPath)
                Install-RSATandADTools -DownloadVersion $DownloadVersion -InstallPath $InstallPath
            } -ArgumentList $DownloadVersion, $InstallPath
        }
        else {
            if (-not (Test-Path $InstallPath)) {
                New-Item -Path $InstallPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
            }
            $RSATInstaller = Join-Path -Path $InstallPath -ChildPath "RSATInstaller.msu"
            $DownloadURL = switch ($DownloadVersion) {
                "New" { "https://download.microsoft.com/download/1/D/8/1D8B5022-5477-4B9A-8104-6A71FF9D98AB/WindowsTH-KB2693643-x64.msu" }
                "Old" { "https://download.microsoft.com/download/1/D/8/1D8B5022-5477-4B9A-8104-6A71FF9D98AB/WindowsTH-RSAT_WS2016-x64.msu" }
            }
            $RSATInstalledOld = Get-WindowsCapability -Online | Where-Object { $_.Name -eq "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0" -and $_.State -eq "Installed" }
            $RSATInstalledNew = Get-HotFix -Id KB2693643
            if ($RSATInstalledOld -or $RSATInstalledNew) {
                Write-Host "RSAT is already installed;`nRSATOld: $($RSATInstalledOld.Name)`nRSATNew: $($RSATInstalledNew.HotFixID)" -ForegroundColor DarkGreen
            }
            else {
                Write-Verbose -Message "Downloading RSAT from $DownloadURL. Please wait..."
                Invoke-WebRequest -Uri $DownloadURL -OutFile $RSATInstaller -ErrorAction Stop | Out-Null
                Write-Host "Installing RSAT. This may take some time..." -ForegroundColor Yellow
                Start-Process -FilePath "wusa.exe" -ArgumentList "/quiet", "/norestart", $RSATInstaller -Wait -ErrorAction Stop | Out-Null
                Write-Verbose -Message "Adding RSAT capability for Active Directory..."
                Add-WindowsCapability -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 -Online -ErrorAction Stop | Out-Null
                Write-Verbose -Message "RSAT installation and capability addition complete"
            }
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
        return
    }
    finally {
        if ($ComputerName) {
            Remove-PSSession -Session $Session -Verbose
        }
    }
}
