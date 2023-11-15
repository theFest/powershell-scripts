Function Remove-WindowsServiceWMI {
    <#
    .SYNOPSIS
    Removes Windows service using WMI method.

    .DESCRIPTION
    This function allows you to delete a Windows service using the WMI method.

    .PARAMETER ServiceName
    Mandatory - Declare the name of the service you want to delete.
    .PARAMETER Force
    Not Mandatory - As a precaution measure, the default is set to -WhatIf. Use this switch to force deletion.

    .EXAMPLE
    Remove-WindowsServiceWMI -ServiceName W32Time -Force

    .NOTES
    v0.1.2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    BEGIN {
        if (!(Get-Service $ServiceName -ErrorAction SilentlyContinue)) {
            Write-Host "Required service not found!" -ForegroundColor Red
            return
        }
    }
    PROCESS {
        $Service = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'"
        if (-not $Force.IsPresent) {
            Write-Host "Use -Force to actually delete!" -ForegroundColor Cyan
        }
        else {
            $Service.StopService() | Out-Null
            Start-Sleep -Seconds 1
            $Service.Delete() | Out-Null
            $Service.Dispose() | Out-Null
        }
    }
    END {
        if (!(Get-Service $ServiceName -ErrorAction SilentlyContinue)) {
            Write-Output "Deleted service: $ServiceName"
        }
    }
}
