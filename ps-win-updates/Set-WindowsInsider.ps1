function Set-WindowsInsider {
    <#
    .SYNOPSIS
    Enables or disables the Windows Insider Program and optionally restarts the system.

    .DESCRIPTION
    This function allows you to enable or disable the Windows Insider Program on a Windows system by modifying the appropriate registry keys. It can also restart the system if needed.

    .EXAMPLE
    Set-WindowsInsider -Action Enable
    Set-WindowsInsider -Action Disable -Restart

    .NOTES
    v0.1.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Specifies whether to enable or disable the Windows Insider Program")]
        [ValidateSet("Enable", "Disable")]
        [string]$Action,

        [Parameter(Mandatory = $false, HelpMessage = "Restart the system after performing the action")]
        [switch]$Restart
    )
    BEGIN {
        $RegPath = "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\Applicability"
        $RegName = "EnablePreviewBuilds"
        $ErrorActionPreference = "Stop"
    }
    PROCESS {
        try {
            switch ($Action) {
                "Enable" {
                    if (-not (Test-Path -Path $RegPath)) {
                        New-Item -Path $RegPath -Force | Out-Null
                    }
                    Set-ItemProperty -Path $RegPath -Name $RegName -Value 1
                    Write-Host "Windows Insider Program enabled" -ForegroundColor Green
                }
                "Disable" {
                    if (Test-Path -Path $RegPath) {
                        Remove-ItemProperty -Path $RegPath -Name $RegName -Force -Verbose
                        Write-Host "Windows Insider Program disabled" -ForegroundColor Green
                    }
                    else {
                        Write-Host "Windows Insider Program is not enabled" -ForegroundColor Yellow
                    }
                }
            }
        }
        catch {
            Write-Error "An error occurred: $_"
        }
    }
    END {
        if ($Restart) {
            Write-Host "Restarting the system..."
            Restart-Computer -Force
        }
    }
}
