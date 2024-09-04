function Export-XMLDisplayInfo {
    <#
    .SYNOPSIS
    Exports information about display monitors and graphics adapters to an XML file.

    .DESCRIPTION
    This function retrieves detailed information about display monitors connected to the system and the graphics adapters used. It supports exporting this information to an XML file.
    If multiple monitors are detected, the user is prompted to select which monitor's information to export. The XML file includes details such as monitor name, resolution, DPI, and information about graphics adapters.

    .EXAMPLE
    Export-XMLDisplayInfo -OutputPath "$env:USERPROFILE\Desktop\display_info.xml"

    .NOTES
    v0.3.9
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Full path to the XML file where the display and graphics adapter information will be saved")]
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
        $XmlWriter = $null
        try {
            $XmlWriter = New-Object System.Xml.XmlTextWriter($OutputPath, $Null)
            $XmlWriter.Formatting = "Indented"
            $XmlWriter.Indentation = 1
            $XmlWriter.IndentChar = "`t"
            $XmlWriter.WriteStartDocument()
            $XmlWriter.WriteProcessingInstruction("xml-stylesheet", "type='text/xsl' href='style.xsl'")
            $XmlWriter.WriteStartElement('DisplayInfo')
            $Monitors = [System.Windows.Forms.Screen]::AllScreens
            if ($Monitors.Count -gt 1) {
                Write-Host "Multiple monitors detected. Please select a monitor by entering the corresponding number:"
                for ($i = 0; $i -lt $Monitors.Count; $i++) {
                    Write-Host "$($i + 1): $($Monitors[$i].DeviceName)"
                }
                $Selection = Read-Host "Enter the number of the monitor to export (1-$($Monitors.Count))"
                if ($Selection -lt 1 -or $Selection -gt $Monitors.Count) {
                    Write-Error "Invalid selection. Please enter a number between 1 and $($Monitors.Count)."
                    return
                }
                $Monitors = $Monitors[$Selection - 1]
            }
            foreach ($Monitor in $Monitors) {
                $MonitorInfo = New-Object PSObject -Property @{
                    'Name'               = $Monitor.DeviceName
                    'Primary'            = $Monitor.Primary
                    'Bounds'             = $Monitor.Bounds
                    'WorkingArea'        = $Monitor.WorkingArea
                    'ResolutionWidth'    = $Monitor.Bounds.Width
                    'ResolutionHeight'   = $Monitor.Bounds.Height
                    'DPI'                = [Math]::Round($Monitor.Bounds.Height / $Monitor.WorkingArea.Height, 2)
                    'BitsPerPixel'       = 24 # Default value as System.Windows.Forms.Screen does not provide this info
                    'RefreshRate'        = 60 # Default value as System.Windows.Forms.Screen does not provide this info
                    'IsPrimary'          = $Monitor.Primary
                    'DeviceID'           = $Monitor.DeviceName
                    'ColorDepth'         = 24 / 8 # Default value as System.Windows.Forms.Screen does not provide this info
                    'PhysicalSizeInInch' = [Math]::Round([Math]::Sqrt(($Monitor.Bounds.Width * $Monitor.Bounds.Width) + ($Monitor.Bounds.Height * $Monitor.Bounds.Height)) / 96, 2) # Default DPI value of 96
                    'Orientation'        = if ($Monitor.Bounds.Width -gt $Monitor.Bounds.Height) { 'Landscape' } else { 'Portrait' }
                }
                $XmlWriter.WriteStartElement('Monitor')
                foreach ($Prop in $MonitorInfo.psobject.Properties) {
                    $XmlWriter.WriteElementString($Prop.Name, $Prop.Value)
                }
                $XmlWriter.WriteEndElement()
            }
            $GraphicsAdapters = Get-WmiObject -Namespace "root\CIMV2" -Class Win32_VideoController
            foreach ($Adapter in $GraphicsAdapters) {
                $AdapterInfo = New-Object PSObject -Property @{
                    'AdapterName'   = $Adapter.Name
                    'AdapterType'   = $Adapter.VideoProcessor
                    'DeviceID'      = $Adapter.DeviceID
                    'DriverVersion' = $Adapter.DriverVersion
                }
                $XmlWriter.WriteStartElement('GraphicsAdapter')
                foreach ($Prop in $AdapterInfo.PSObject.Properties) {
                    $XmlWriter.WriteElementString($Prop.Name, $Prop.Value)
                }
                $AdapterMonitors = Get-WmiObject -Namespace "root\CIMV2" -Class Win32_DesktopMonitor | Where-Object { $_.PNPDeviceID -like "*$($Adapter.DeviceID)*" }
                foreach ($Monitor in $AdapterMonitors) {
                    $MonitorInfo = New-Object PSObject -Property @{
                        'Name'        = $Monitor.Caption
                        'DeviceID'    = $Monitor.DeviceID
                        'AdapterName' = $Adapter.Name
                        'AdapterType' = $Adapter.VideoProcessor
                        'ScreenCount' = $AdapterMonitors.Count
                    }
                    $XmlWriter.WriteStartElement('Monitor')
                    foreach ($Prop in $MonitorInfo.psobject.Properties) {
                        $XmlWriter.WriteElementString($Prop.Name, $Prop.Value)
                    }
                    $XmlWriter.WriteEndElement()
                }
                $XmlWriter.WriteEndElement()
            }
            $XmlWriter.WriteEndElement()
            $XmlWriter.WriteEndDocument()
            $XmlWriter.Flush()
        }
        catch {
            Write-Error "Error occurred: $_"
        }
        finally {
            if ($null -ne $XmlWriter) {
                $XmlWriter.Dispose()
            }
        }
    }
}
