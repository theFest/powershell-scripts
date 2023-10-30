Function Set-WindowsErrorReporting {
    <#
    .SYNOPSIS
    Disables Windows Error Reporting (WER) via registry settings.
    
    .DESCRIPTION
    This function disables Windows Error Reporting by modifying the registry settings. It can be used on Windows 7 and Windows 10.

    .PARAMETER Restart
    If specified, it will restart the computer to apply the changes.

    .EXAMPLE
    Set-WindowsErrorReporting -Restart -Verbose

    .NOTES
    Version: 0.1.1
    #>
    [CmdletBinding(DefaultParameterSetName = "DisableWER")]
    param(                
        [Parameter(Mandatory = $false)]
        [switch]$Restart
    )
    $OperatingSystem = (Get-WmiObject -Class Win32_OperatingSystem)
    $OsVersion = $OperatingSystem.Version
    if ($OsVersion -match "6.1") {
        Write-Host "Windows 7 detected, checking for WER registry key..."
        $WerKeyPath = "HKCU:\Software\Microsoft\Windows\Windows Error Reporting"
        $DontShowUIValue = (Get-ItemProperty -Path $WerKeyPath -Name DontShowUI).DontShowUI
        if ($DontShowUIValue -ne '1') {
            Write-Host "Setting DontShowUI to '1'" -ForegroundColor Cyan
            Set-ItemProperty -Path $WerKeyPath -Name DontShowUI -Value 1 -Force -Verbose
        }
    }
    elseif ($OsVersion -match "10.*") {
        Write-Host "Disabling Windows Error Reporting on Windows 10..." -ForegroundColor Cyan
        $WerKeyPath = "HKCU:\Software\Microsoft\Windows\Windows Error Reporting"
        Set-ItemProperty -Path $WerKeyPath -Name Disabled -Value 1 -Force -Verbose
    }
    else {
        Write-Verbose -Message "Unsupported Windows version detected: $OsVersion. Exiting..."
    }
    if ($Restart) {
        Restart-Computer -Verbose
    }
}
