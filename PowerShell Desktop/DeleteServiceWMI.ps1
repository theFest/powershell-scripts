Function DeleteServiceWMI {
    <#
    .SYNOPSIS
    Windows service removal script.
    
    .DESCRIPTION
    With this funtion you can delete Windows service using WMI method.
    
    .PARAMETER ServiceName
    Mandator - declare name of the service you want to delete.
    .PARAMETER ForceIf
    NotMandatory - as a precaution measure, default is set to -Whatif. Use this switch to force deletion.

    .EXAMPLE
    DeleteServiceWMI -ServiceName W32Time (-ForceIf #-->use to delete)
    
    .NOTES
    v2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,

        [Parameter(Mandatory = $false)]
        [switch]$ForceIf
    )
    BEGIN {
        if (!(Get-Service $ServiceName -ErrorAction SilentlyContinue)) {
            Write-Host "Required service not found!" -ForegroundColor Red
        }
    }
    PROCESS {
        $Service = Get-WmiObject -Class Win32_Service -Filter "Name='$ServiceName'"
        if (!$ForceIf.IsPresent) {
            Write-Host "Use -ForceIf to actually delete!" -ForegroundColor Cyan
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