Function Install-GitAndGitHubCLI {
    <#
    .SYNOPSIS
    Installs Git and GitHub CLI using Chocolatey package manager.

    .DESCRIPTION
    This function checks for the presence of Chocolatey package manager. If Chocolatey is not installed and the InstallChocolatey parameter is specified, it installs Chocolatey.
    If Chocolatey is already installed, it optionally upgrades Chocolatey if the UpgradeChocolatey parameter is specified. After ensuring Chocolatey is available, it installs Git and GitHub CLI packages using Chocolatey.

    .PARAMETER InstallChocolatey
    Chocolatey should be installed if it's not already present.
    .PARAMETER UpgradeChocolatey
    Chocolatey should be upgraded if it's already installed.

    .EXAMPLE
    Install-GitAndGitHubCLI

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$InstallChocolatey,

        [Parameter(Mandatory = $false)]
        [switch]$UpgradeChocolatey
    )
    Write-Verbose -Message "Check for presence of Chocolatey..."
    if (-not(Get-Command choco.exe -ErrorAction SilentlyContinue)) {
        if ($InstallChocolatey) {
            Write-Verbose -Message "Chocolatey download and installation in progress..."
            try {
                Write-Verbose -Message "Installing Chocolatey..."
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            }
            catch {
                Write-Error -Message "Failed to install Chocolatey: $($_.Exception.Message)"
                return
            }
        }
        else {
            Write-Error -Message "Chocolatey is not installed!"
            return
        }
    }
    elseif ($UpgradeChocolatey) {
        Write-Verbose -Message "Upgrading Chocolatey..."
        try {
            Write-Verbose -Message "Upgrading Chocolatey..."
            choco upgrade chocolatey -y
        }
        catch {
            Write-Error -Message "Failed to upgrade Chocolatey: $($_.Exception.Message)"
            return
        }
    }
    Write-Verbose -Message "Installing Git and GitHub CLI using Chocolatey..."
    $Packages = @('git', 'gh')
    foreach ($Package in $Packages) {
        if (-not(Get-Command $Package -ErrorAction SilentlyContinue)) {
            try {
                Write-Verbose -Message "Installing $Package using Chocolatey..."
                choco install $Package -y
                Write-Host "$Package installation successful" -ForegroundColor Green
            }
            catch {
                Write-Error -Message "Failed to install $Package : $($_.Exception.Message)"
            }
        }
        else {
            Write-Host "$Package is already installed" -ForegroundColor DarkGreen
        }
    }
}
