Function Enable-USBDevices {
    <#
    .SYNOPSIS
    Enables USB devices on the system.

    .DESCRIPTION
    This function allows enabling USB devices on the system. It retrieves a list of USB devices and provides an interactive menu for selecting the device to enable.

    .PARAMETER ShowAllDevices
    Show all USB devices, including those not currently connected.
    .PARAMETER ShowDetails
    Display detailed information about each USB device.
    .PARAMETER SortBy
    Property by which the list of USB devices should be sorted, values are "DeviceID", "Description", "Status", "PNPDeviceID", "Caption", and "SystemName".
    .PARAMETER MaxResults
    Maximum number of USB devices to display in the menu.

    .EXAMPLE
    Enable-USBDevices -ShowDetails
    Enable-USBDevices -ShowDetails -ShowAllDevices

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$ShowAllDevices = $false,

        [Parameter(Mandatory = $false)]
        [switch]$ShowDetails = $false,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DeviceID", "Description", "Status", "PNPDeviceID", "Caption", "SystemName")]
        [string]$SortBy = "Description",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$MaxResults = [int]::MaxValue
    )
    $GetUSBDevices = {
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
        param ($UsbDevices)
        if ($UsbDevices.Count -eq 0) {
            Write-Warning -Message "No USB devices found."
            return $null
        }
        $UsbDevices = $UsbDevices | Sort-Object $SortBy | Select-Object -First $MaxResults
        Write-Host "USB Devices:"
        $Index = 0
        $UsbDevices | ForEach-Object {
            Write-Host "$Index. Device ID: $($_.DeviceID)"
            Write-Host "   Description: $($_.Description)"
            if ($ShowDetails) {
                Write-Host "      Status: $($_.Status)"
                Write-Host "      PNP Device ID: $($_.PNPDeviceID)"
                Write-Host "      Caption: $($_.Caption)"
                Write-Host "      System Name: $($_.SystemName)"
            }
            Write-Host "---------------------------------------"
            $Index++
        }
        $Choice = Read-Host "Enter the number of the USB device to enable (0-$($UsbDevices.Count - 1))"
        if ($Choice -ge 0 -and $Choice -lt $UsbDevices.Count) {
            return $UsbDevices[$Choice].PNPDeviceID
        }
        else {
            Write-Warning -Message "Invalid choice, enter a number between 0 and $($UsbDevices.Count - 1)"
            return $null
        }
    }
    $EnableUSBDevice = {
        param ($DeviceID)
        $UsbDevice = Get-PnpDevice | Where-Object { $_.InstanceId -like "*$($DeviceID)*" }
        if ($UsbDevice) {
            Enable-PnpDevice -InstanceId $DeviceID
            Write-Host "Enabled USB device $($DeviceID)" -ForegroundColor Green
        }
        else {
            Write-Warning -Message "No USB device found with ID $($DeviceID)!"
        }
    }
    $UsbDevices = & $GetUSBDevices
    $SelectedDeviceID = & $ShowUSBDeviceMenu -UsbDevices $UsbDevices
    if ($SelectedDeviceID) {
        & $EnableUSBDevice -DeviceID $SelectedDeviceID
    }
}
