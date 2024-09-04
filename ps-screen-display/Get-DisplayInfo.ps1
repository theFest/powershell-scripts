function Get-DisplayInfo {
    <#
    .SYNOPSIS
    Retrieves and displays information about connected display devices.

    .DESCRIPTION
    This cmdlet retrieves detailed information about the displays connected to the system. It gathers data from multiple system classes, including Win32_DesktopMonitor, Win32_VideoController, and Win32_DisplayConfiguration.
    The information can include resolution, physical dimensions, refresh rate, and available video modes depending on the parameters used. The results can be optionally exported to a CSV file.

    .EXAMPLE
    Get-DisplayInfo -Detailed -IncludeAllResolutions -IncludePhysicalDimensions -ExportPath "$env:USERPROFILE\Desktop\DisplayInfo.csv" -Verbose

    .NOTES
    v0.2.4
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Displays verbose output with more detailed information")]
        [switch]$Detailed,

        [Parameter(Mandatory = $false, HelpMessage = "Includes all available resolutions for each display in the output")]
        [switch]$IncludeAllResolutions,

        [Parameter(Mandatory = $false, HelpMessage = "Calculates and includes the physical dimensions of the display in inches")]
        [switch]$IncludePhysicalDimensions,

        [Parameter(Mandatory = $false, HelpMessage = "Specifies the file path where the display information should be exported as a CSV file")]
        [string]$ExportPath
    )
    $DisplayInfoList = @()
    Write-Verbose -Message "Getting display information using Win32_DesktopMonitor class..."
    try {
        $DisplayMonitors = Get-CimInstance -ClassName Win32_DesktopMonitor
        foreach ($Display in $DisplayMonitors) {
            $PhysicalWidth = $null
            $PhysicalHeight = $null
            if ($IncludePhysicalDimensions -and $Display.PixelsPerXLogicalInch -ne 0 -and $Display.PixelsPerYLogicalInch -ne 0) {
                $PhysicalWidth = [math]::Round($Display.ScreenWidth / $Display.PixelsPerXLogicalInch, 2)
                $PhysicalHeight = [math]::Round($Display.ScreenHeight / $Display.PixelsPerYLogicalInch, 2)
            }
            $AllResolutions = $null
            if ($IncludeAllResolutions) {
                $AllResolutions = $Display.VideoModeDescription -join "; "
            }
            $DisplayInfo = [pscustomobject]@{
                Name                  = $Display.DeviceID
                Manufacturer          = $Display.Manufacturer
                Type                  = "Desktop Monitor"
                Width                 = $Display.ScreenWidth
                Height                = $Display.ScreenHeight
                PixelsPerXLogicalInch = $Display.PixelsPerXLogicalInch
                PixelsPerYLogicalInch = $Display.PixelsPerYLogicalInch
                RefreshRate           = $Display.RefreshRate
                PhysicalWidth         = $PhysicalWidth
                PhysicalHeight        = $PhysicalHeight
                AllResolutions        = $AllResolutions
            }
            $DisplayInfoList += $DisplayInfo
        }
    }
    catch {
        Write-Error -Message "Failed to retrieve data from Win32_DesktopMonitor: $_"
    }
    Write-Verbose -Message "Getting display information using Win32_VideoController class..."
    try {
        $VideoControllers = Get-CimInstance -ClassName Win32_VideoController
        foreach ($Controller in $VideoControllers) {
            $DisplayInfo = [pscustomobject]@{
                Name                  = $Controller.Caption
                Manufacturer          = $Controller.Manufacturer
                Type                  = "Video Controller"
                Width                 = $Controller.CurrentHorizontalResolution
                Height                = $Controller.CurrentVerticalResolution
                PixelsPerXLogicalInch = $null
                PixelsPerYLogicalInch = $null
                RefreshRate           = $Controller.CurrentRefreshRate
                PhysicalWidth         = $null
                PhysicalHeight        = $null
                AllResolutions        = $null
            }
            $DisplayInfoList += $DisplayInfo
        }
    }
    catch {
        Write-Error -Message "Failed to retrieve data from Win32_VideoController: $_"
    }
    Write-Verbose -Message "Getting display configuration information using Win32_DisplayConfiguration class..."
    try {
        $DisplayConfigurations = Get-WmiObject -Namespace "root\cimv2" -Class Win32_DisplayConfiguration
        foreach ($DisplayConfig in $DisplayConfigurations) {
            $DisplayInfo = [pscustomobject]@{
                Name                  = $DisplayConfig.DeviceName
                Manufacturer          = $null
                Type                  = "Display Configuration"
                Width                 = $DisplayConfig.PelsWidth
                Height                = $DisplayConfig.PelsHeight
                PixelsPerXLogicalInch = $null
                PixelsPerYLogicalInch = $null
                RefreshRate           = $DisplayConfig.DisplayFrequency
                PhysicalWidth         = $null
                PhysicalHeight        = $null
                AllResolutions        = $null
            }
            $DisplayInfoList += $DisplayInfo
        }
    }
    catch {
        Write-Error "Failed to retrieve data from Win32_DisplayConfiguration: $_"
    }
    Write-Verbose -Message "Outputting all display information..."
    $DisplayInfoList | Select-Object Name, Manufacturer, Type, Width, Height, `
        PixelsPerXLogicalInch, PixelsPerYLogicalInch, RefreshRate, PhysicalWidth, PhysicalHeight, AllResolutions |
    Format-Table -AutoSize
    if ($ExportPath) {
        try {
            $DisplayInfoList | Export-Csv -Path $ExportPath -NoTypeInformation
            Write-Host "Display information exported to $ExportPath" -ForegroundColor DarkCyan
        }
        catch {
            Write-Error -Message "Failed to export data to CSV file: $_"
        }
    }
}
