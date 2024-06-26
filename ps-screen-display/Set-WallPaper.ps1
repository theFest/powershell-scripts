function Set-WallPaper {
    <#
    .SYNOPSIS
    Sets the desktop wallpaper with the specified image and style.

    .DESCRIPTION
    This function sets the desktop wallpaper to a specified image file and applies a display style such as Fill, Fit, Stretch, Tile, Center, or Span. It modifies the necessary registry entries and uses the SystemParametersInfo Win32 API function to apply the changes.

    .EXAMPLE
    Set-WallPaper -Image "C:\Windows\Web\Wallpaper\Theme1\img1.jpg" -Style Stretch

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Path to the image file")]
        [ValidateNotNullOrEmpty()]
        [string]$Image,

        [Parameter(Mandatory = $false, HelpMessage = "Style for wallpaper display")]
        [ValidateSet("Fill", "Fit", "Stretch", "Tile", "Center", "Span")]
        [string]$Style = "Fill"
    )
    $WallpaperStyle = Switch ($Style) {
        "Fill" { "10" }
        "Fit" { "6" }
        "Stretch" { "2" }
        "Tile" { "0" }
        "Center" { "0" }
        "Span" { "22" }
        default { "10" }
    }
    try {
        if ($Style -eq "Tile") {
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value $WallpaperStyle -Force
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value "1" -Force
        }
        else {
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name WallpaperStyle -Value $WallpaperStyle -Force
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name TileWallpaper -Value "0" -Force
        }
    }
    catch {
        Write-Error -Message "Failed to set registry properties: $_"
        return
    }
    $CSharpCode = @"
    using System; 
    using System.Runtime.InteropServices;
    
    public class Params {
        [DllImport("User32.dll", CharSet = CharSet.Unicode)]
        public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
    }
"@
    Add-Type -TypeDefinition $CSharpCode
    $SPI_SETDESKWALLPAPER = 0x0014
    $UpdateIniFile = 0x01
    $SendChangeEvent = 0x02
    $FWinIni = $UpdateIniFile -bor $SendChangeEvent
    try {
        $Ret = [Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $FWinIni)
        if ($Ret -eq 0) {
            Write-Error "Failed to set wallpaper. Error code: $Ret"
        }
    }
    catch {
        Write-Error -Message "Exception occurred while setting wallpaper: $_"
    }
}
