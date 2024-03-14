Function Disable-USBDevices {
    <#
    .SYNOPSIS
    Disables USB devices on the system.

    .DESCRIPTION
    This function allows disabling USB devices on the system. It retrieves a list of USB devices and provides an interactive menu for selecting the device to disable.

    .PARAMETER ShowAllDevices
    Show all USB devices, including those not currently connected.
    .PARAMETER ShowDetails
    Display detailed information about each USB device.
    .PARAMETER SortBy
    Property by which the list of USB devices should be sorted, values are "DeviceID", "Description", "Status", "Manufacturer", "PNPDeviceID", and "State".
    .PARAMETER MaxResults
    Maximum number of USB devices to display in the menu.

    .EXAMPLE
    Disable-USBDevices -ShowDetails
    Disable-USBDevices -ShowDetails -ShowAllDevices

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$ShowAllDevices,

        [Parameter(Mandatory = $false)]
        [switch]$ShowDetails,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DeviceID", "Description", "Status", "Manufacturer", "PNPDeviceID", "State")]
        [string]$SortBy = "Description",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$MaxResults = [int]::MaxValue
    )
    $GetUSBDevices = {
        param ($ShowAllDevices)
        if ($ShowAllDevices) {
            Get-CimInstance -ClassName Win32_USBControllerDevice | ForEach-Object {
                Get-CimInstance -ClassName Win32_PnPEntity -Filter "DeviceID='$($_.Dependent.DeviceID.Replace('\', '\\'))'"
            }
        }
        else {
            Get-CimInstance -ClassName Win32_DiskDrive | Where-Object { $_.InterfaceType -eq 'USB' }
        }
    }
    $ShowUSBDeviceMenu = {
        param ($UsbDevices, $SortBy, $MaxResults, $ShowDetails)
        if ($UsbDevices.Count -eq 0) {
            Write-Warning -Message "No USB storage devices found!"
            return $null
        }
        $UsbDevices = $UsbDevices | Sort-Object $SortBy | Select-Object -First $MaxResults
        Write-Host "USB Devices:"
        $index = 1
        $UsbDevices | ForEach-Object {
            Write-Host "$index. Device ID: $($_.DeviceID)"
            Write-Host "   Description: $($_.Description)"
            Write-Host "   State: $($_.State)"
            if ($ShowDetails) {
                Write-Host "      Status: $($_.Status)"
                Write-Host "      Manufacturer: $($_.Manufacturer)"
                Write-Host "      PNP Device ID: $($_.PNPDeviceID)"
            }
            Write-Host "---------------------------------------"
            $index++
        }
        $choice = Read-Host "Enter the number of the USB device to disable (1-$($UsbDevices.Count))"
        return $UsbDevices[$choice - 1].PNPDeviceID
    }
    $DisableUSBDevice = {
        param ($DeviceID)
        $UsbHub = Get-PnpDevice | Where-Object { $_.InstanceId -like "*$($DeviceID)*" }
        if ($UsbHub) {
            if ($UsbHub.Status -eq "OK") {
                Disable-PnpDevice -InstanceId $DeviceID
                Write-Host "Disabled USB device $($DeviceID)" -ForegroundColor DarkGray
            }
            else {
                Write-Warning -Message "USB device $($DeviceID) is already disabled or cannot be disabled!"
            }
        }
        else {
            Write-Warning -Message "No USB device found with ID $($DeviceID)!"
        }
    }
    $UsbDevices = & $GetUSBDevices -ShowAllDevices:$ShowAllDevices
    $SelectedDeviceID = & $ShowUSBDeviceMenu -UsbDevices $UsbDevices -SortBy $SortBy -MaxResults $MaxResults -ShowDetails $ShowDetails
    if ($SelectedDeviceID) {
        & $DisableUSBDevice -DeviceID $SelectedDeviceID
    }
}
