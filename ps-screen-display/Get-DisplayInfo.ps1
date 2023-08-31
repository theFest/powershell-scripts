Function Get-DisplayInfo {
    <#
    .SYNOPSIS
    Retrieves information about computer display monitors.

    .DESCRIPTION
    This function retrieves various information about computer display monitors, including their names, manufacturer, type, screen dimensions, and more.

    .PARAMETER Detailed
    NotMandatory - specifies whether to include detailed information about the displays, such as refresh rate and pixels per logical inch.
    .PARAMETER IncludeAllResolutions
    NotMandatory - specifies whether to include all available display resolutions.
    .PARAMETER IncludePhysicalDimensions
    NotMandatory - specifies whether to include the physical dimensions of the displays in inches.

    .EXAMPLE
    Get-DisplayInfo -Detailed -IncludeAllResolutions -IncludePhysicalDimensions

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [switch]$Detailed,
        [switch]$IncludeAllResolutions,
        [switch]$IncludePhysicalDimensions
    )
    $Displays = Get-WmiObject -Namespace "root\cimv2" -Class Win32_DesktopMonitor
    foreach ($Display in $Displays) {
        $DisplayInfo = @{
            Name                = $Display.DeviceID
            MonitorManufacturer = $Display.MonitorManufacturerName
            MonitorType         = $Display.MonitorType
            ScreenWidth         = $Display.ScreenWidth
            ScreenHeight        = $Display.ScreenHeight
        }
        if ($Detailed) {
            $DisplayInfo.RefreshRate = $Display.RefreshRate
            $DisplayInfo.PixelsPerXLogicalInch = $Display.PixelsPerXLogicalInch
            $DisplayInfo.PixelsPerYLogicalInch = $Display.PixelsPerYLogicalInch
        }
        if ($IncludeAllResolutions) {
            $DisplayInfo.AllResolutions = $display.DisplayModes | ForEach-Object {
                "{0}x{1}" -f $_.HorizontalResolution, $_.VerticalResolution
            }
        }
        if ($IncludePhysicalDimensions) {
            $DisplayInfo.PhysicalWidth = $Display.ScreenWidth / $Display.PixelsPerXLogicalInch
            $DisplayInfo.PhysicalHeight = $Display.ScreenHeight / $Display.PixelsPerYLogicalInch
        }
        $DisplayObject = New-Object PSObject -Property $DisplayInfo
        Write-Output $DisplayObject
    }
}
