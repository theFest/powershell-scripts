Function Update-WindowsSystem {
    <#
    .SYNOPSIS
    Updates the Windows system by installing available drivers and updates using Windows Update Module.

    .DESCRIPTION
    This function updates the Windows system by installing available drivers and updates, excluding Silverlight. First ensures that the required PowerShell Windows Update Module is installed and imports it, then it proceeds to install all available drivers and updates, except Silverlight. 
    It uses/requires the PSWindowsUpdate module from the PowerShell Gallery. Installs the NuGet Package Provider if not already installed and sets the PSGallery repository to Trusted, then installs or imports the PSWindowsUpdate module as needed. If you need native PS method, use another function within this repository folder. 

    .PARAMETER PSWindowsUpdateVersion
    Specifies the version of the PowerShell Windows Update Module to use. Default value is "2.2.1.4".

    .EXAMPLE
    Update-WindowsSystem -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(ConfirmImpact = "Low")]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Version of PowerShell Windows Update Module")]
        [ValidateNotNullOrEmpty()]
        [string]$PSWindowsUpdateVersion = "2.2.1.4"
    )
    BEGIN {
        $StartTime = Get-Date
        try {
            if ($env:PROCESSOR_ARCHITEW6432 -ne "ARM64") {
                if (Test-Path -Path ('{0}\SysNative\WindowsPowerShell\v1.0\powershell.exe' -f $env:WINDIR) -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) {
                    Write-Verbose -Message "Executing 64-bit PowerShell..."
                    & "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy bypass -NoProfile -File $PSCommandPath
                    exit $LastExitCode
                }
            }
            if (-not (Get-PackageProvider -Name "NuGet" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue)) {
                Write-Verbose -Message "Installing NuGet Package Provider..."
                Install-PackageProvider -Name "NuGet" -RequiredVersion "2.8.5.201" -Scope AllUsers -Force -ErrorAction SilentlyContinue -Verbose
            }
            if (Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue | Where-Object -FilterScript { $PSItem.InstallationPolicy -ne "Trusted" }) {
                Write-Verbose -Message "Setting PSGallery repository to Trusted..."
                Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -Verbose
            }
            if (-not (Get-Module -Name "PSWindowsUpdate" -ListAvailable -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Sort-Object -Descending -Property Version `
                    | Select-Object -First 1 | Where-Object -FilterScript { $PSItem.Version -cge $PSWindowsUpdateVersion })) {
                Write-Verbose -Message "Installing PSWindowsUpdate module..."
                Install-Module -Name "PSWindowsUpdate" -MinimumVersion $PSWindowsUpdateVersion -Repository PSGallery -AllowClobber -Force -Verbose
            }
            Write-Verbose -Message "Importing PSWindowsUpdate module..."
            Import-Module -Name "PSWindowsUpdate" -MinimumVersion $PSWindowsUpdateVersion -DisableNameChecking -NoClobber -Force -Verbose
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
            IgnoreUserInput = $true
            AcceptAll       = $true
            IgnoreReboot    = $true
            ForceInstall    = $true
            ComputerName    = $env:COMPUTERNAME
            Confirm         = $false
        }
        $UpdateExceptSilverlightParams = $DriverUpdateParams + @{
            NotKBArticleID = "KB4481252"
            ForceDownload  = $true
        }
        try {
            Write-Host "Install all available drivers..." -ForegroundColor Cyan
            Get-WindowsUpdate @DriverUpdateParams -Verbose
        }
        catch {
            Write-Verbose -Message "Error while installing all available drivers!"
            Write-Error -Message $_.Exception.Message
        }
        try {
            Write-Host "Install all available updates, except SilverLight..." -ForegroundColor Cyan
            Get-WindowsUpdate @UpdateExceptSilverlightParams -Verbose
        }
        catch {
            Write-Verbose -Message "Error while installing all available updates!"
            Write-Error -Message $_.Exception.Message
        }
    }
    END {
        $NeedReboot = (Get-WURebootStatus -ComputerName $env:COMPUTERNAME -Verbose).RebootRequired
        if ($NeedReboot) {
            Write-Verbose -Message "If needed, set return code 3010('exit 3010') - as long as this happens during device ESP, the computer will automatically reboot at the end of device ESP"
            $RebootChoice = Read-Host -Prompt "Reboot required! Do you want to reboot now? (Y/N)"
            if ($RebootChoice -eq 'Y' -or $RebootChoice -eq 'y') {
                Write-Host "Rebooting now..." -ForegroundColor DarkCyan
                Restart-Computer -Force
            }
            else {
                Write-Host "Reboot postponed, exiting script..." -ForegroundColor Gray
                exit 0
            }
        }
        else {
            Write-Host "No reboot required, operations completed...exiting!" -ForegroundColor DarkGreen
            exit 0
        }
        $EndTime = Get-Date
        $ElapsedTime = New-TimeSpan -Start $StartTime -End $EndTime
        Write-Verbose -Message "Time taken: $($ElapsedTime.TotalSeconds) seconds"
    }
}
