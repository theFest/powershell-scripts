Function DeleteServicesCIM {
    <#
    .SYNOPSIS
    Windows services removal script.
    
    .DESCRIPTION
    With this funtion you can delete Windows services using CIM method.
    
    .PARAMETER ServiceNames
    Mandatory - declare names of the services you want to delete.
    .PARAMETER ForceIf
    NotMandatory - default is set to -Whatif, to force deletion use this switch.
    
    .EXAMPLE
    DeleteServicesCIM -ServiceNames Spooler, W32Time (-ForceIf #-->use to delete)
    
    .NOTES
    v1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [array]$ServiceNames,

        [Parameter(Mandatory = $false)]
        [switch]$ForceIf
    )
    $ServiceNames | ForEach-Object -Begin {
        Get-Service $ServiceNames -Verbose
    } -Process {
        if ($ForceIf.IsPresent) {
            $Force = $false
        }
        Stop-Service $_ -Verbose -WhatIf:$Force -Force
        Get-CimInstance -ClassName Win32_Service -Filter "Name='$_'" | Remove-CimInstance -Verbose -WhatIf:$Force
    } -End {
        if (!(Get-Service $ServiceNames -ErrorAction SilentlyContinue)) {
            $Output = $ServiceNames | Out-String
            Write-Output "Deleted services:"$Output
        }
    }
}