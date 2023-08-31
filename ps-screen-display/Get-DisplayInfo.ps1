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
    .PARAMETER ExportPath
    NotMandatory - specifies the path to export the display information to a CSV file.

    .EXAMPLE
    Get-DisplayInfo -Detailed -IncludeAllResolutions -IncludePhysicalDimensions -ExportPath "$env:USERPROFILE\Desktop\DisplayInfo.csv"

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Detailed,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllResolutions,

        [Parameter(Mandatory = $false)]
        [switch]$IncludePhysicalDimensions,

        [Parameter(Mandatory = $false)]
        [string]$ExportPath
    )
    $Displays = Get-WmiObject -Namespace "root\cimv2" -Class Win32_DesktopMonitor
    $DisplayInfoList = @()
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
        $DisplayInfoList += $DisplayObject
    }
    Write-Output -InputObject $DisplayInfoList
    if ($ExportPath) {
        $DisplayInfoList | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "Display information exported to $ExportPath" -ForegroundColor Cyan
    }
}
