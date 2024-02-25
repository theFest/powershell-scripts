Function Start-WinGetUpdate {
    <#
    .SYNOPSIS
    Automates the update process for WinGet and associated components.

    .DESCRIPTION
    This function automates the process of updating WinGet and its dependencies, such as VCLibs, on a Windows 10 Professional machine.
    It checks for the latest version of WinGet, downloads and installs it if necessary, installs or updates VCLibs, and upgrades all installed software using WinGet.

    .PARAMETER SkipVersionCheck
    Skips the WinGet version check, if specified, the script proceeds without checking for the latest version of WinGet.
    .PARAMETER SkipWinGetInstall
    Skips the installation of WinGet, if specified, the script does not attempt to install or update WinGet.
    .PARAMETER SkipVCLibsInstall
    Skips the installation or update of VCLibs, if specified, the script does not attempt to install or update VCLibs.
    .PARAMETER IncludeUnknown
    Includes unknown software during the WinGet upgrade, if specified, the script upgrades all software, including those with unknown sources.
    .PARAMETER SilentMode
    Enables silent mode during WinGet upgrade, if specified, the script upgrades software without user interaction.

    .EXAMPLE
    Start-WinGetUpdate

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$SkipVersionCheck,

        [Parameter(Mandatory = $false)]
        [switch]$SkipWinGetInstall,

        [Parameter(Mandatory = $false)]
        [switch]$SkipVCLibsInstall,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeUnknown,

        [Parameter(Mandatory = $false)]
        [switch]$SilentMode
    )
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
        Write-Error -Message "This script requires administrator privileges. Exiting now..."
        return
    }
    $WindowsEdition = (Get-ComputerInfo).OsName
    if ($WindowsEdition -notlike "*Microsoft Windows 10 Pro*") {
        Write-Error -Message "This script requires Windows 10 Professional edition. Exiting now..."
        return
    }
    $GitHubUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    $GithubHeaders = @{
        "Accept"               = "application/vnd.github.v3+json"
        "X-GitHub-Api-Version" = "2023-12-18" #"2022-11-28"
    }
    $Architecture = (Get-CimInstance -ClassName Win32_ComputerSystem).SystemType
    switch ($Architecture) {
        "x64-based PC" { $Arch = "x64" }
        "ARM64-based PC" { $Arch = "arm64" }
        "x86-based PC" { $Arch = "x86" }
        default {
            Write-Error -Message "Your running an unsupported architecture. Exiting now..."
            return
        }
    }
    $VCLibsUrl = "https://aka.ms/Microsoft.VCLibs.$Arch.14.00.Desktop.appx"
    if (!$SkipWinGetInstall) {
        $CheckWinGet = try { (Get-AppxPackage -Name Microsoft.DesktopAppInstaller).Version } catch { $null }
        if ($SkipVersionCheck -eq $false -or $null -eq $CheckWinGet) {
            $installMessage = if ($null -eq $CheckWinGet) { "WinGet is not installed, downloading and installing WinGet..." } else { "Checking if there's a newer version of WinGet to download and install..." }
            Write-Host $installMessage -ForegroundColor Yellow
            try {
                $GitHubInfoRestData = Invoke-RestMethod -Uri $GitHubUrl -Method Get -Headers $GithubHeaders -TimeoutSec 10 -ErrorAction Stop
                $LatestVersion = $GitHubInfoRestData.tag_name.Substring(1)
                $GitHubInfo = [PSCustomObject]@{
                    Tag         = $LatestVersion
                    DownloadUrl = $GitHubInfoRestData.assets | Where-Object { $_.name -like "*.msixbundle" } | Select-Object -ExpandProperty browser_download_url
                    OutFile     = "$env:TEMP\WinGet_$LatestVersion.msixbundle"
                }
            }
            catch {
                Write-Error -Message "Failed to retrieve WinGet information: $_"
                return
            }
            if ($CheckWinGet -le $GitHubInfo.Tag) {
                Write-Host "WinGet has a newer version $($GitHubInfo.Tag), downloading and installing it..." -ForegroundColor DarkCyan
                Invoke-WebRequest -UseBasicParsing -Uri $GitHubInfo.DownloadUrl -OutFile $GitHubInfo.OutFile
                try {
                    Add-AppxPackage -Path $GitHubInfo.OutFile -ErrorAction Stop
                }
                catch {
                    Write-Error -Message "Failed to install WinGet: $_"
                    return
                }
            }
            else {
                Write-Host "You are already on the latest version of WinGet $($CheckWinGet), no need to update" -ForegroundColor DarkGreen
            }
        }
    }
    if (!$SkipVCLibsInstall) {
        $CheckVCLibs = Get-AppxPackage -Name "Microsoft.VCLibs.140.00" -AllUsers | Where-Object { $_.Architecture -eq $Arch }
        $VCLibsOutFile = "$env:TEMP\Microsoft.VCLibs.140.00.$Arch.appx"
        if ($null -eq $CheckVCLibs) {
            try {
                Write-Output "Microsoft.VCLibs is not installed, downloading and installing it now..."
                Invoke-WebRequest -UseBasicParsing -Uri $VCLibsUrl -OutFile $VCLibsOutFile -ErrorAction Stop -Verbose
                Add-AppxPackage -Path $VCLibsOutFile -ErrorAction Stop
            }
            catch {
                Write-Error -Message "Failed to install Microsoft.VCLibs: $_"
                return
            }
        }
    }
    Write-Verbose -Message "Checking if any software needs to be updated"
    try {
        $WinGetArgs = @("upgrade", "--all", "--force", "--accept-source-agreements")
        if ($IncludeUnknown) { $WinGetArgs += "--include-unknown" }
        if ($SilentMode) { $WinGetArgs += "--silent", "--disable-interactivity" }
        $WinGetOutput = Start-Process "winget" -ArgumentList $WinGetArgs -Wait -PassThru -ErrorAction Stop
        if ($WinGetOutput.ExitCode -ne 0) {
            Write-Error -Message "Failed to upgrade software using WinGet. Exit Code: $($WinGetOutput.ExitCode)"
        }
        else {
            Write-Host "Everything is now completed, you can close this window" -ForegroundColor Green
        }
    }
    catch {
        Write-Error -Message "Failed to execute WinGet: $_"
    }
}
