Function Get-DisplayInfo {
    <#
    .SYNOPSIS
    Retrieves information about computer display monitors using multiple methods.

    .DESCRIPTION
    This function retrieves various information about computer display monitors, including their names, manufacturer, type, screen dimensions, and more, using multiple methods.

    .PARAMETER Detailed
    NotMandatory - Specifies whether to include detailed information about the displays, such as refresh rate and pixels per logical inch.
    .PARAMETER IncludeAllResolutions
    NotMandatory - Specifies whether to include all available display resolutions.
    .PARAMETER IncludePhysicalDimensions
    NotMandatory - Specifies whether to include the physical dimensions of the displays in inches.
    .PARAMETER ExportPath
    NotMandatory - Specifies the path to export the display information to a CSV file.

    .EXAMPLE
    Get-DisplayInfo -Detailed -IncludeAllResolutions -IncludePhysicalDimensions -ExportPath "$env:USERPROFILE\Desktop\DisplayInfo.csv" -Verbose

    .NOTES
    v0.0.4
    #>
    [CmdletBinding()]
    param (
        [switch]$Detailed,
        [switch]$IncludeAllResolutions,
        [switch]$IncludePhysicalDimensions,
        [string]$ExportPath
    )
    $DisplayInfoList = @()
    Write-Verbose -Message "Getting display information using Win32_DesktopMonitor class, with first approach..."
    $DisplayMonitors = Get-CimInstance -ClassName Win32_DesktopMonitor
    foreach ($Display in $DisplayMonitors) {
        $DisplayInfo = @{
            Name                  = $Display.DeviceID
            MonitorManufacturer   = $Display.Manufacturer
            MonitorType           = $Display.PNPDeviceID
            ScreenWidth           = $Display.ScreenWidth
            ScreenHeight          = $Display.ScreenHeight
            PixelsPerXLogicalInch = $Display.PixelsPerXLogicalInch
            PixelsPerYLogicalInch = $Display.PixelsPerYLogicalInch
            RefreshRate           = $Display.RefreshRate
            PhysicalWidth         = [math]::Round($Display.ScreenWidth / $Display.PixelsPerXLogicalInch, 2)
            PhysicalHeight        = [math]::Round($Display.ScreenHeight / $Display.PixelsPerYLogicalInch, 2)
            AllResolutions        = $Display.VideoModeDescription -join "; "
        }
        $DisplayObject = New-Object PSObject -Property $DisplayInfo
        $DisplayInfoList += $DisplayObject
    }
    Write-Verbose -Message "Getting display information using Win32_VideoController class, second method..."
    $VideoControllers = Get-CimInstance -ClassName Win32_VideoController
    foreach ($Controller in $VideoControllers) {
        $DisplayInfo = @{
            Name           = $Controller.Caption
            Manufacturer   = $Controller.Manufacturer
            VideoMode      = $Controller.CurrentHorizontalResolution
            RefreshRate    = $Controller.CurrentRefreshRate
            VideoProcessor = $Controller.VideoProcessor
            MaxRefreshRate = $Controller.MaxRefreshRate
        }
        $DisplayObject = New-Object PSObject -Property $DisplayInfo
        $DisplayInfoList += $DisplayObject
    }
    Write-Verbose -Message "Getting display information using Win32_DisplayConfiguration class, third method..."
    $DisplayConfigurations = Get-WmiObject -Namespace "root\cimv2" -Class Win32_DisplayConfiguration
    foreach ($DisplayConfig in $DisplayConfigurations) {
        $DisplayInfo = @{
            DeviceName       = $DisplayConfig.DeviceName
            BitsPerPel       = $DisplayConfig.BitsPerPel
            PelsWidth        = $DisplayConfig.PelsWidth
            PelsHeight       = $DisplayConfig.PelsHeight
            DisplayFrequency = $DisplayConfig.DisplayFrequency
        }
        $DisplayObject = New-Object PSObject -Property $DisplayInfo
        $DisplayInfoList += $DisplayObject
    }
    Write-Verbose -Message "Outputting all display information..."
    $DisplayInfoList | Format-Table -AutoSize Name, MonitorManufacturer, MonitorType, ScreenWidth, ScreenHeight, `
        PixelsPerXLogicalInch, PixelsPerYLogicalInch, RefreshRate, PhysicalWidth, PhysicalHeight, AllResolutions
    if ($ExportPath) {
        $DisplayInfoList | Export-Csv -Path $ExportPath -NoTypeInformation
        Write-Host "Display information exported to $ExportPath" -ForegroundColor DarkCyan
    }
}
