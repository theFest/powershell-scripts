Function Get-SystemDrivers {
    <#
    .SYNOPSIS
    Retrieves information about system device drivers.

    .DESCRIPTION
    This function retrieves information about device drivers installed on the system using Get-CimInstance. It provides options to display all drivers or filter them by a specified manufacturer.

    .PARAMETER ShowAll
    NotMandatory - specifies whether to display all device drivers.

    .PARAMETER FilterManufacturer
    NotMandatory - specifies the manufacturer to filter device drivers by.
    
    .EXAMPLE
    Get-SystemDrivers -ShowAll
    Get-SystemDrivers -FilterManufacturer "Intel"
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$ShowAll,

        [Parameter(Mandatory = $false)]
        [string]$FilterManufacturer
    )
    Write-Verbose -Message "Get all device drivers using Get-CimInstance"
    $Drivers = Get-CimInstance -Class Win32_PnPSignedDriver | Select-Object DeviceName, Manufacturer, DriverVersion, Description
    Write-Verbose -Message "Filter drivers by manufacturer if specified"
    if ($FilterManufacturer) {
        $Drivers = $Drivers | Where-Object { $_.Manufacturer -like "*$FilterManufacturer*" }
    }
    if ($ShowAll) {
        $Drivers
    }
    else {
        $Drivers | Select-Object DeviceName, Manufacturer, DriverVersion, Description | Format-Table
    }
}
