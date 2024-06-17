function Disable-WER {
    <#
    .SYNOPSIS
    Configures Windows Error Reporting settings on local or remote computers.

    .DESCRIPTION
    This function allows you to manage Windows Error Reporting settings on Windows computers. It can disable the WER service and adjust registry settings related to error reporting. Optionally, it can restart the computer after applying changes.

    .EXAMPLE
    Disable-WER -Verbose
    Disable-WER -ComputerName "fwvmhv" -User "fwv" -Pass "1234"

    .NOTES
    v0.7.6
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, HelpMessage = "Remote computer name, default is the local computer")]
        [Alias("c")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Username for remote authentication")]
        [Alias("u")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for remote authentication")]
        [Alias("p")]
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "Restarts the computer after applying changes")]
        [Alias("r")]
        [switch]$Restart
    )
    try {
        $Credential = $null
        if ($User -and $Pass) {
            $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecurePassword
        }
        $script:DisableWindowsErrorReporting = {
            param()
            $ErrorActionPreference = 'Stop'
            if ((Get-Service -Name WerSvc).StartType -ne "Disabled") {
                Write-Verbose -Message "Stopping and disabling WER service..."
                Stop-Service -Name WerSvc -Force -Verbose
                Set-Service -Name WerSvc -StartupType Disabled -Verbose
            }
        }
        if ($ComputerName -eq $env:COMPUTERNAME -or !$User -or !$Pass) {
            $Session = $null
            $OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem
        }
        else {
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
            $OperatingSystem = Invoke-Command -Session $Session -ScriptBlock {
                param()
                Get-WmiObject -Class Win32_OperatingSystem
            } -ArgumentList $null -ErrorAction Stop
        }
        $OsVersion = $OperatingSystem.Version
        $WerKeyPath = "HKCU:\Software\Microsoft\Windows\Windows Error Reporting"
        switch -Wildcard ($OsVersion) {
            "6.1*" {
                Write-Verbose -Message "Windows 7 detected, checking for WER registry key..."
                if ($ComputerName -eq $env:COMPUTERNAME -or !$User -or !$Pass) {
                    $DontShowUIValue = (Get-ItemProperty -Path $WerKeyPath -Name DontShowUI -ErrorAction SilentlyContinue).DontShowUI
                }
                else {
                    $DontShowUIValue = Invoke-Command -Session $Session -ScriptBlock {
                        param($Path)
                        (Get-ItemProperty -Path $Path -Name DontShowUI -ErrorAction SilentlyContinue).DontShowUI
                    } -ArgumentList $WerKeyPath
                }
                if ($DontShowUIValue -ne '1') {
                    Write-Verbose -Message "Setting DontShowUI to '1'"
                    if ($ComputerName -eq $env:COMPUTERNAME -or !$User -or !$Pass) {
                        Set-ItemProperty -Path $WerKeyPath -Name DontShowUI -Value 1 -Force
                    }
                    else {
                        Invoke-Command -Session $Session -ScriptBlock {
                            param($Path)
                            Set-ItemProperty -Path $Path -Name DontShowUI -Value 1 -Force
                        } -ArgumentList $WerKeyPath
                    }
                }
            }
            "10.*" {
                Write-Verbose -Message "Disabling Windows Error Reporting on Windows 10..."
                if ($ComputerName -eq $env:COMPUTERNAME -or !$User -or !$Pass) {
                    Invoke-Command -ScriptBlock $script:DisableWindowsErrorReporting
                    Set-ItemProperty -Path $WerKeyPath -Name Disabled -Value 1 -Force
                }
                else {
                    Invoke-Command -Session $Session -ScriptBlock $script:DisableWindowsErrorReporting
                    Invoke-Command -Session $Session -ScriptBlock {
                        param($Path)
                        Set-ItemProperty -Path $Path -Name Disabled -Value 1 -Force
                    } -ArgumentList $WerKeyPath
                }
            }
            default {
                Write-Warning -Message "Unsupported Windows version detected: $OsVersion. Exiting!"
                return
            }
        }
        if ($Restart) {
            if ($ComputerName -eq $env:COMPUTERNAME -or !$User -or !$Pass) {
                Restart-Computer -ComputerName $ComputerName -Force -Verbose
            }
            else {
                Restart-Computer -ComputerName $ComputerName -Credential $Credential -Force -Verbose
            }
        }
    }
    catch {
        Write-Error -Message "Failed to retrieve operating system information from $ComputerName. $_"
    }
    finally {
        if ($Session) {
            Remove-PSSession -Session $Session -Verbose
        }
    }
}
