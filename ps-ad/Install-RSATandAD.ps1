Function Install-RSATandADTools {
    <#
    .SYNOPSIS
    Installs RSAT and adds Active Directory capability.

    .DESCRIPTION
    This function downloads and installs Remote Server Administration Tools (RSAT) on the local machine. Additionally, it adds the Active Directory capability.

    .PARAMETER DownloadURL
    NotMandatory - specifies the URL from which to download the RSAT installer.
    .PARAMETER InstallPath
    NotMandatory - directory path where the RSAT installer will be downloaded and installed.

    .EXAMPLE
    Install-RSATandADTools -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$DownloadURL = "https://download.microsoft.com/download/1/D/8/1D8B5022-5477-4B9A-8104-6A71FF9D98AB/WindowsTH-RSAT_WS2016-x64.msu",

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$InstallPath = "$env:TEMP"
    )
    try {
        if (-not (Test-Path $InstallPath)) {
            New-Item -Path $InstallPath -ItemType Directory -Force -ErrorAction Stop
        }
        $RSATInstaller = Join-Path -Path $InstallPath -ChildPath "RSATInstaller.msu"
        Write-Verbose -Message "Downloading RSAT from $DownloadURL. Please wait..."
        Invoke-WebRequest -Uri $DownloadURL -OutFile $RSATInstaller
        Write-Verbose -Message "Installing RSAT. This may take some time..."
        Start-Process -FilePath "wusa.exe" -ArgumentList "/quiet", "/norestart", $RSATInstaller -Wait
        Write-Verbose -Message "Adding RSAT capability for Active Directory..."
        Add-WindowsCapability -Name Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0 -Online
        Write-Verbose -Message "RSAT installation and capability addition complete"
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Checking for AD module..." -ForegroundColor DarkCyan
        if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
            Write-Warning -Message "Active Directory module not found. Importing..."
            Import-Module -Name ActiveDirectory -Force -Verbose
        }
        else {
            Write-Host "Active Directory module is already imported" -ForegroundColor DarkGreen
        }
    }
}
