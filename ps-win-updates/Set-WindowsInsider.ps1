Function Set-WindowsInsider {
    <#
    .SYNOPSIS
    Enables or disables the Windows Insider Program and optionally restarts the system.

    .DESCRIPTION
    This function allows you to enable or disable the Windows Insider Program on a Windows system, it can also restart the system if needed.

    .PARAMETER Action
    Specifies whether to enable or disable the Windows Insider Program, valid values are "Enable" or "Disable".
    .PARAMETER Restart
    Indicates whether to restart the system after performing the action, if this switch is present, the system will be restarted.

    .EXAMPLE
    Set-WindowsInsider -Action Enable
    Set-WindowsInsider -Action Disable -Restart

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Enable", "Disable")]
        [string]$Action,

        [Parameter(Mandatory = $false)]
        [switch]$Restart
    )
    BEGIN {
        $RegPath = "HKLM:\SOFTWARE\Microsoft\WindowsSelfHost\Applicability"
        $RegName = "EnablePreviewBuilds"
    }
    PROCESS {
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
    END {
        if ($Restart) {
            Write-Host "Restarting the system..."
            Restart-Computer -Force
        }
    }
}
