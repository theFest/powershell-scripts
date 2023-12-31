Function Export-XMLDisplayInfo {
    <#
    .SYNOPSIS
    Exports detailed display information including monitors and graphics adapters to an XML file.

    .DESCRIPTION
    This function retrieves detailed information about monitors and graphics adapters, including their names, IDs, resolution, DPI, refresh rate, and more, and exports this information to an XML file.

    .PARAMETER OutputPath
    Mandatory - specifies the path where the output XML file will be saved.

    .EXAMPLE
    Export-XMLDisplayInfo -OutputPath "C:\Temp\display_info.xml"

    .NOTES
    v0.1.2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    BEGIN {
        Add-Type -TypeDefinition @"
            using System;
            using System.Management;
            public class MonitorInfo {
                public string Name { get; set; }
                public string DeviceID { get; set; }
                public string AdapterName { get; set; }
                public string AdapterType { get; set; }
                public uint ScreenCount { get; set; }
            }
"@
    }
    PROCESS {
        try {
            $XmlW = New-Object System.Xml.XmlTextWriter($OutputPath, $Null)
            $XmlW.Formatting = "Indented"
            $XmlW.Indentation = 1
            $XmlW.IndentChar = "`t"
            $XmlW.WriteStartDocument()
            $XmlW.WriteProcessingInstruction("xml-stylesheet", "type='text/xsl' href='style.xsl'")
            $XmlW.WriteStartElement('Display_info')
            $Monitors = [System.Windows.Forms.Screen]::AllScreens
            foreach ($Monitor in $Monitors) {
                $MonitorInfo = New-Object PSObject -Property @{
                    'Name'              = $Monitor.DeviceName
                    'Primary'           = $Monitor.Primary
                    'Bounds'            = $Monitor.Bounds
                    'WorkingArea'       = $Monitor.WorkingArea
                    'Resolution_width'  = $Monitor.Bounds.Width
                    'Resolution_height' = $Monitor.Bounds.Height
                    'DPI'               = $Monitor.Bounds.Height / $Monitor.WorkingArea.Height
                    'BitsPerPixel'      = $Monitor.BitsPerPixel
                    'RefreshRate'       = $Monitor.RefreshRate
                    'IsPrimary'         = $Monitor.Primary
                    'DeviceID'          = $Monitor.DeviceName
                    'IsEnabled'         = $Monitor.Primary -or $Monitor.DeviceName -ne "DISPLAYDEVICE"
                    'ColorDepth'        = $Monitor.BitsPerPixel / 8
                    'ConnectionStatus'  = $Monitor.DeviceName -in [System.Windows.Forms.Screen]::AllScreens.DeviceName
                    'PhysicalSize_Inch' = [Math]::Round([Math]::Sqrt(($Monitor.Bounds.Width * $Monitor.Bounds.Width) + ($Monitor.Bounds.Height * $Monitor.Bounds.Height)) / $Monitor.Bounds.DensityX, 2)
                    'Manufacturer'      = $Adapter.Manufacturer
                    'Availability'      = $Monitor.DeviceName -in [System.Windows.Forms.Screen]::AllScreens.DeviceName
                    'SerialNumber'      = (Get-WmiObject -Namespace "root\CIMV2" -Class Win32_DesktopMonitor | Where-Object { $_.DeviceID -eq $Monitor.DeviceName }).SerialNumber
                    'Orientation'       = if ($Monitor.Bounds.Width -gt $Monitor.Bounds.Height) { 'Landscape' } else { 'Portrait' }
                }
                $DisplayModes = $Monitor.DisplayModes
                if ($null -ne $DisplayModes) {
                    $DisplayModesInfo = $DisplayModes | ForEach-Object {
                        "$($_.Width)x$($_.Height)@ $($_.RefreshRate)Hz"
                    }
                    $MonitorInfo.Add("DisplayModes", $DisplayModesInfo -join ', ')
                }
                $XmlW.WriteStartElement('Monitor')
                foreach ($Prop in $MonitorInfo.psobject.properties) {
                    $XmlW.WriteElementString($Prop.Name, $Prop.Value)
                }
                $XmlW.WriteEndElement()
            }
            $GraphicsAdapters = Get-WmiObject -Namespace "root\CIMV2" -Class Win32_VideoController
            foreach ($Adapter in $GraphicsAdapters) {
                $AdapterInfo = New-Object PSObject -Property @{
                    'AdapterName'   = $Adapter.Name
                    'AdapterType'   = $Adapter.VideoProcessor
                    'DeviceID'      = $Adapter.DeviceID
                    'DriverVersion' = $Adapter.DriverVersion
                }
                $XmlW.WriteStartElement('GraphicsAdapter')
                foreach ($Prop in $AdapterInfo.psobject.properties) {
                    $XmlW.WriteElementString($Prop.Name, $Prop.Value)
                }
                $AdapterMonitors = Get-WmiObject -Namespace "root\CIMV2" -Class Win32_DesktopMonitor | Where-Object { $_.PNPDeviceID -like "*$($adapter.DeviceID)*" }
                foreach ($Monitor in $AdapterMonitors) {
                    $MonitorInfo = New-Object PSObject -Property @{
                        'Name'        = $Monitor.Caption
                        'DeviceID'    = $Monitor.DeviceID
                        'AdapterName' = $adapter.Name
                        'AdapterType' = $adapter.VideoProcessor
                        'ScreenCount' = $AdapterMonitors.Count
                    }
                    $DisplayModes = $Monitor.DisplayModes
                    if ($null -ne $DisplayModes) {
                        $DisplayModesInfo = $DisplayModes | ForEach-Object {
                            "$($_.Width)x$($_.Height)@ $($_.RefreshRate)Hz"
                        }
                        $MonitorInfo.Add("DisplayModes", $DisplayModesInfo -join ', ')
                    }
                    $XmlW.WriteStartElement('Monitor')
                    foreach ($Prop in $MonitorInfo.psobject.properties) {
                        $XmlW.WriteElementString($Prop.Name, $Prop.Value)
                    }
                    $XmlW.WriteEndElement()
                }
                $XmlW.WriteEndElement()
            }
            $XmlW.WriteEndElement()
            $XmlW.WriteEndDocument()
            $XmlW.Flush()
            $XmlW.Close()
        }
        catch {
            Write-Error "Error occurred: $_"
        }
    }
    END {
        if ($null -ne $XmlW) {
            $XmlW.Dispose()
        }
    }
}
