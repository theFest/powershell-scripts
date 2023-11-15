Function Remove-WindowsServiceCIM {
    <#
    .SYNOPSIS
    Windows services removal script.

    .DESCRIPTION
    This function deletes Windows services using the CIM method.

    .PARAMETER ServiceNames
    Mandatory - Declare names of the services you want to delete.
    .PARAMETER ForceIf
    Not Mandatory - Default is set to -WhatIf, to force deletion use this switch.

    .EXAMPLE
    Remove-WindowsServiceCIM -ServiceNames Spooler, W32Time -ForceIf # To delete services without confirmation.

    .NOTES
    v0.1.3
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string[]]$ServiceNames,

        [Parameter(Mandatory = $false)]
        [switch]$ForceIf
    )
    BEGIN {
        Write-Verbose -Message "Removing Windows services..."
    }
    PROCESS {
        foreach ($ServiceName in $ServiceNames) {
            $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($Service) {
                Write-Verbose -Message "Stopping service: $ServiceName"
                Stop-Service -Name $ServiceName -Force -WhatIf:$ForceIf.IsPresent
                $CimService = Get-CimInstance -ClassName Win32_Service -Filter "Name='$ServiceName'" -ErrorAction SilentlyContinue
                if ($CimService) {
                    Write-Verbose -Message "Removing CIM instance for service: $ServiceName"
                    $CimService | Remove-CimInstance -WhatIf:$ForceIf.IsPresent
                }
                else {
                    Write-Warning -Message "CIM instance not found for service: $ServiceName"
                }
            }
            else {
                Write-Warning -Message "Service not found: $ServiceName"
            }
        }
    }
    END {
        $DeletedServices = Get-Service -Name $ServiceNames -ErrorAction SilentlyContinue
        if (-not $DeletedServices) {
            $output = $ServiceNames -join ', '
            Write-Output "Deleted services: $output"
        }
    }
}
