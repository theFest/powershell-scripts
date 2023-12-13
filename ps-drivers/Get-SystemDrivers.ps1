Function Get-SystemDrivers {
    <#
    .SYNOPSIS
    Retrieves information about system device drivers.

    .DESCRIPTION
    This function retrieves information about device drivers installed on the system using Get-CimInstance. It provides options to display all drivers or filter them by a specified manufacturer.

    .PARAMETER ShowAll
    NotMandatory - whether to display all device drivers.
    .PARAMETER FilterManufacturer
    NotMandatory - specifies the manufacturer to filter device drivers by.
    .PARAMETER SortBy
    NotMandatory - the property to sort the drivers by.
    .PARAMETER ExportToCSV
    NotMandatory - a path to export the driver information as a CSV file.
    
    .EXAMPLE
    Get-SystemDrivers -ShowAll
    Get-SystemDrivers -FilterManufacturer "Intel" -ExportToCSV "$env:USERPROFILE\Desktop\DriversInfo.csv"
    
    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$ShowAll,

        [Parameter(Mandatory = $false)]
        [string]$FilterManufacturer,

        [Parameter(Mandatory = $false)]
        [string]$SortBy,

        [Parameter(Mandatory = $false)]
        [string]$ExportToCSV
    )
    $Drivers = Get-CimInstance -Class Win32_PnPSignedDriver | Select-Object DeviceName, Manufacturer, DriverVersion, Description
    if ($FilterManufacturer) {
        Write-Verbose -Message "Filtering drivers by manufacturer if specified"
        $Drivers = $Drivers | Where-Object { $_.Manufacturer -like "*$FilterManufacturer*" }
    }
    if ($SortBy) {
        Write-Verbose -Message "Sorting drivers by $SortBy"
        $Drivers = $Drivers | Sort-Object -Property $SortBy
    }
    if ($ShowAll) {
        $Drivers
    }
    else {
        $Drivers | Select-Object DeviceName, Manufacturer, DriverVersion, Description | Format-Table
    }
    if ($ExportToCSV) {
        Write-Verbose -Message "Exporting driver information to $ExportToCSV"
        $Drivers | Export-Csv -Path $ExportToCSV -NoTypeInformation
    }
}
