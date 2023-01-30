Function DisableWinErrorReporting {
    <#
    .SYNOPSIS
    Small Function to disable WER
    
    .DESCRIPTION
    Disable Windows Error Reporting via registry
    
    .PARAMETER Restart
    NotMandatory - restart to apply
    
    .EXAMPLE
    DisableWinErrorReporting -Verbose
    DisableWinErrorReporting -Restart -Verbose
    
    .NOTES
    0.1 - 'explorer.exe will be added as replacement for restart'...
    https://winreg-kb.readthedocs.io/en/latest/sources/system-keys/Windows-error-reporting.html
    #>
    [CmdletBinding(DefaultParameterSetName = "Disable WER")]
    param(                
        [Parameter(Mandatory = $false)]
        [string]$Restart
    )
    $WV = (Get-WMIObject -Class Win32_OperatingSystem).Version
    if ($WV -match "6.1") {
        Write-Host "Windows 7 detected, checking for WER reg key..."
        if ((Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\Windows Error Reporting" -Name DontShowUI).DontShowUI -ne '1') {
            Write-Host "Setting DontShowUI to off state" -ForegroundColor Cyan
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\Windows Error Reporting" -Name DontShowUI -Value 1 -Force -Verbose
        }
    }
    elseif ($WV -match "10.*") {
        Write-Host "Disabling WER on Win10..." -ForegroundColor Cyan
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\Windows Error Reporting" -Name Disabled -Value 1 -Force -Verbose
    }
    else {
        Write-Verbose -Message "Other version of Windows detected:$WV, exiting..."
    }
    if ($Restart) {
        Restart-Computer -Verbose
    }
}