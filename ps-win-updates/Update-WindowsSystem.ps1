function Update-WindowsSystem {
    <#
    .SYNOPSIS
    Updates the Windows system by installing drivers and updates using Windows Update Module.

    .DESCRIPTION
    This function installs Windows drivers and updates using the PSWindowsUpdate module, with parameters to skip drivers, force updates, suppress user interaction, and reboot automatically if needed.

    .EXAMPLE
    Update-WindowsSystem -Verbose

    .NOTES
    v0.1.2
    #>
    [CmdletBinding(ConfirmImpact = "Low")]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Version of PowerShell Windows Update Module")]
        [ValidateNotNullOrEmpty()]
        [string]$PSWindowsUpdateVersion = "2.2.1.5",

        [Parameter(Mandatory = $false, HelpMessage = "Skip driver updates during the update process")]
        [switch]$SkipDrivers,

        [Parameter(Mandatory = $false, HelpMessage = "Force system reboot after updates without user confirmation")]
        [switch]$ForceReboot,

        [Parameter(Mandatory = $false, HelpMessage = "Run the update process without any user interaction or prompts")]
        [switch]$Silent,

        [Parameter(Mandatory = $false, HelpMessage = "Skip all non-driver updates")]
        [switch]$SkipUpdates,

        [Parameter(Mandatory = $false, HelpMessage = "Automatically accept all EULAs during the update process")]
        [switch]$AcceptEULA,

        [Parameter(Mandatory = $false, HelpMessage = "Force the installation of all updates, ignoring download status")]
        [switch]$ForceUpdates
    )
    BEGIN {
        $StartTime = Get-Date
        try {
            if ($env:PROCESSOR_ARCHITEW6432 -ne "ARM64") {
                if (Test-Path -Path ("$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe") -ErrorAction SilentlyContinue) {
                    Write-Verbose -Message "Executing 64-bit PowerShell..."
                    & "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -NoProfile -File $PSCommandPath
                    exit $LastExitCode
                }
            }
            if (-not (Get-PackageProvider -Name "NuGet" -ErrorAction SilentlyContinue)) {
                Write-Verbose -Message "Installing NuGet Package Provider..."
                Install-PackageProvider -Name "NuGet" -RequiredVersion "2.8.5.201" -Scope AllUsers -Force -Verbose
            }
            if ((Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue).InstallationPolicy -ne "Trusted") {
                Write-Verbose -Message "Setting PSGallery repository to Trusted..."
                Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -Verbose
            }
            if (-not (Get-Module -Name "PSWindowsUpdate" -ListAvailable | Sort-Object -Property Version -Descending | Where-Object { $_.Version -ge $PSWindowsUpdateVersion })) {
                Write-Verbose -Message "Installing PSWindowsUpdate module..."
                Install-Module -Name "PSWindowsUpdate" -MinimumVersion $PSWindowsUpdateVersion -Repository PSGallery -AllowClobber -Force -Verbose
            }
            Write-Verbose -Message "Importing PSWindowsUpdate module..."
            Import-Module -Name "PSWindowsUpdate" -MinimumVersion $PSWindowsUpdateVersion -DisableNameChecking -Force -Verbose
        }
        catch {
            Write-Error -Message "An unknown error occurred in the BEGIN block: $_"
        }
    }
    PROCESS {
        $DriverUpdateParams = @{
            Install         = $true
            MicrosoftUpdate = $true
            UpdateType      = "Driver"
            IgnoreUserInput = $Silent
            AcceptAll       = $AcceptEULA
            IgnoreReboot    = $true
            ForceInstall    = $ForceUpdates
            ComputerName    = $env:COMPUTERNAME
            Confirm         = $false
        }
        $UpdateParams = @{
            Install         = $true
            MicrosoftUpdate = $true
            IgnoreUserInput = $Silent
            AcceptAll       = $AcceptEULA
            IgnoreReboot    = $true
            ForceInstall    = $ForceUpdates
            ComputerName    = $env:COMPUTERNAME
            Confirm         = $false
        }
        if (-not $SkipDrivers) {
            try {
                Write-Host "Installing all available drivers..." -ForegroundColor Cyan
                Get-WindowsUpdate @DriverUpdateParams -Verbose
            }
            catch {
                Write-Error "Error while installing drivers: $_"
            }
        }
        if (-not $SkipUpdates) {
            try {
                Write-Host "Installing all available updates..." -ForegroundColor Cyan
                Get-WindowsUpdate @UpdateParams -Verbose
            }
            catch {
                Write-Error -Message "Error while installing updates: $_"
            }
        }
    }
    END {
        try {
            $NeedReboot = (Get-WURebootStatus -ComputerName $env:COMPUTERNAME -Verbose).RebootRequired
            if ($NeedReboot) {
                if ($ForceReboot -or $Silent) {
                    Write-Host "Rebooting now..." -ForegroundColor DarkCyan
                    Restart-Computer -Force
                }
                else {
                    $RebootChoice = Read-Host -Prompt "Reboot required! Do you want to reboot now? (Y/N)"
                    if ($RebootChoice -match "^[Yy]$") {
                        Write-Host "Rebooting now..." -ForegroundColor DarkCyan
                        Restart-Computer -Force
                    }
                    else {
                        Write-Host "Reboot postponed, exiting script..." -ForegroundColor Gray
                        exit 0
                    }
                }
            }
            else {
                Write-Host "No reboot required, operations completed successfully." -ForegroundColor DarkGreen
            }
        }
        catch {
            Write-Error -Message "Error during reboot status check: $_"
        }
        $EndTime = Get-Date
        $ElapsedTime = New-TimeSpan -Start $StartTime -End $EndTime
        Write-Verbose -Message "Total time taken: $($ElapsedTime.TotalSeconds) seconds"
    }
}
