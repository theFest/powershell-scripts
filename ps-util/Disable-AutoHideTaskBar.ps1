Function Disable-AutoHideTaskBar {
    <#
    .SYNOPSIS
    Disables auto-hide functionality for the Windows TaskBar by modifying registry settings.
    
    .DESCRIPTION
    This function modifies registry settings to disable auto-hide for the Windows TaskBar, it allows customization of registry path, setting index, and value.
    
    .PARAMETER RegistryPath
    The registry path where the settings are located.
    .PARAMETER SettingIndex
    Index of the setting to change in the registry.
    .PARAMETER SettingValue
    Specifies the value to set for the given registry setting.
    .PARAMETER RestartExplorer
    Indicates whether to restart the Windows Explorer process after making changes.
    
    .EXAMPLE
    Disable-AutoHideTaskBar -RestartExplorer -Verbose
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [Alias("Show-TaskBar")]
    [OutputType("None")]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify the registry path")]
        [string]$RegistryPath = 'HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3',
        
        [Parameter(Mandatory = $false, HelpMessage = "Specify the index of the setting to change")]
        [int]$SettingIndex = 8,
        
        [Parameter(Mandatory = $false, HelpMessage = "Specify the value to set")]
        [int]$SettingValue = 2,
        
        [Parameter(Mandatory = $false, HelpMessage = "Specify whether to restart explorer")]
        [switch]$RestartExplorer
    )
    BEGIN {
        Write-Verbose -Message "Starting $($MyInvocation.MyCommand)"
    }
    PROCESS {
        try {
            if (Test-Path -Path $RegistryPath) {
                Write-Verbose -Message "Disabling auto-hide for Windows TaskBar..."
                $RegValues = (Get-ItemProperty -Path $RegistryPath).Settings
                $RegValues[$SettingIndex] = $SettingValue
                Set-ItemProperty -Path $RegistryPath -Name Settings -Value $RegValues -Verbose
                if ($RestartExplorer) {
                    if ($PSCmdlet.ShouldProcess("Explorer", "Restart")) {
                        Stop-Process -Name explorer -Force
                    }
                }
            }
            else {
                Write-Warning -Message "Can't find registry location $RegistryPath!"
            }
        }
        catch {
            Write-Error -Message "An error occurred: $_"
        }
    }
    END {
        Write-Verbose -Message "Ending $($MyInvocation.MyCommand)"
    }
}
