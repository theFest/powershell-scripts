function New-Screenshot {
    <#
    .SYNOPSIS
    Captures a screenshot with customizable options such as resolution, format, and more, while managing Windows Defender real-time protection.

    .DESCRIPTION
    This function allows the user to capture a screenshot with a variety of options for resolution, image format, and quality.
    It supports delays, previews, and automatic closure of the preview window. It also manages Windows Defender real-time protection by temporarily disabling and re-enabling it during the screenshot capture process. 

    .EXAMPLE
    New-Screenshot -BoundsType FullHD -OutputPath "$env:USERPROFILE\Desktop\screenshot" -ImageFormat Jpeg -Quality 90 -ShowPreview -AutoClosePreview

    .NOTES
    v0.3.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Screen resolution for the screenshot, options are 'FullHD', 'HD', '4K', or 'Custom'")]
        [ValidateSet("FullHD", "HD", "4K", "Custom")]
        [Alias("b")]
        [string]$BoundsType = "FullHD",
    
        [Parameter(Mandatory = $true, HelpMessage = "Full path where the screenshot will be saved")]
        [ValidateNotNullOrEmpty()]
        [Alias("o")]
        [string]$OutputPath,
    
        [Parameter(Mandatory = $false, HelpMessage = "Image format for the screenshot, options are 'Bmp', 'Png', 'Jpeg', 'Gif', or 'Tiff'")]
        [ValidateSet("Bmp", "Png", "Jpeg", "Gif", "Tiff")]
        [Alias("f")]
        [string]$ImageFormat = "Png",
    
        [Parameter(Mandatory = $false, HelpMessage = "Sets the quality of the image (for formats like JPEG), value should be between 1 and 100")]
        [ValidateRange(1, 100)]
        [Alias("q")]
        [int]$Quality = 100,
    
        [Parameter(Mandatory = $false, HelpMessage = "Specifies the delay in seconds before capturing the screenshot")]
        [Alias("d")]
        [int]$CaptureDelay = 0,
    
        [Parameter(Mandatory = $false, HelpMessage = "If specified, the screenshot will be displayed in a preview window after it is saved")]
        [Alias("sp")]
        [switch]$ShowPreview,
    
        [Parameter(Mandatory = $false, HelpMessage = "If set, the preview window will automatically close after the specified delay")]
        [Alias("ac")]
        [switch]$AutoClosePreview,
    
        [Parameter(Mandatory = $false, HelpMessage = "Number of seconds to wait before closing the preview window when AutoClosePreview is enabled.")]
        [Alias("p")]
        [int]$PreviewCloseDelay = 3,
    
        [Parameter(Mandatory = $false, HelpMessage = "Allows specifying a custom starting position (X,Y) for the screen capture area")]
        [ValidateNotNull()]
        [Alias("c")]
        [System.Drawing.Point]$CustomPosition,
    
        [Parameter(Mandatory = $false, HelpMessage = "If set, suppresses output messages from being displayed")]
        [Alias("s")]
        [switch]$SuppressOutput,
    
        [Parameter(Mandatory = $false, HelpMessage = "If specified, a timestamp will be appended to the file name to ensure unique naming")]
        [Alias("t")]
        [switch]$AddTimestamp
    )
    BEGIN {
        if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Error -Message "This script requires administrative privileges! Please run it as Administrator."
            return
        }
    }
    PROCESS {
        try {
            Write-Verbose -Message "Disabling Windows Defender's real-time protection..."
            Set-MpPreference -DisableRealtimeMonitoring $true
            Write-Host "Real-time protection disabled successfully."
            Add-Type -AssemblyName System.Drawing
            $Bounds = [Drawing.Rectangle]::Empty
            switch ($BoundsType) {
                "FullHD" { $Bounds = [Drawing.Rectangle]::FromLTRB(0, 0, 1920, 1080) }
                "HD" { $Bounds = [Drawing.Rectangle]::FromLTRB(0, 0, 1280, 720) }
                "4K" { $Bounds = [Drawing.Rectangle]::FromLTRB(0, 0, 3840, 2160) }
                "Custom" {
                    $CustomDimensions = Read-Host "Enter custom dimensions for screenshot (format: Width Height)"
                    $Width, $Height = $CustomDimensions -split ' '
                    if (-not [int]::TryParse($Width, [ref]$null) -or -not [int]::TryParse($Height, [ref]$null)) {
                        Write-Error "Invalid custom dimensions provided!"
                        return
                    }
                    $Bounds = [Drawing.Rectangle]::FromLTRB(0, 0, [int]$Width, [int]$Height)
                }
            }
            if ($CustomPosition -ne $null) {
                $Bounds.Location = $CustomPosition
            }
            if ($CaptureDelay -gt 0) {
                Write-Host "Delaying for $CaptureDelay seconds before capturing the screenshot..."
                Start-Sleep -Seconds $CaptureDelay
            }
            $Bitmap = New-Object Drawing.Bitmap $Bounds.Width, $Bounds.Height
            $Graphics = [Drawing.Graphics]::FromImage($Bitmap)
            $Graphics.CopyFromScreen($Bounds.Location, [Drawing.Point]::Empty, $Bounds.Size)
            if ($AddTimestamp) {
                $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                $OutputPath = Join-Path -Path (Split-Path -Parent $OutputPath) -ChildPath ("Screenshot_$Timestamp" + [System.IO.Path]::GetExtension($OutputPath))
            }
            $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Png
            switch ($ImageFormat) {
                "Bmp" { $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Bmp }
                "Jpeg" { $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Jpeg }
                "Gif" { $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Gif }
                "Tiff" { $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Tiff }
            }
            $OutputPathWithExtension = "$OutputPath.$($ImageFormat.ToLower())"
            $Bitmap.Save($OutputPathWithExtension, $ImageFormatEnum)
            if (-not $SuppressOutput) {
                Write-Host "Screenshot saved to $OutputPathWithExtension" -ForegroundColor Cyan
            }
            if ($ShowPreview) {
                $PreviewProcess = Start-Process -FilePath $OutputPathWithExtension -PassThru
                if ($AutoClosePreview) {
                    Start-Sleep -Seconds $PreviewCloseDelay
                    Stop-Process -Id $PreviewProcess.Id -Force
                }
            }
        }
        catch {
            Write-Error -Message "An error occurred: $_"
        }
        finally {
            Write-Verbose -Message "Re-enabling Windows Defender real-time protection..."
            try {
                Set-MpPreference -DisableRealtimeMonitoring $false
                Write-Host "Real-time protection re-enabled successfully."
            }
            catch {
                Write-Error "Error re-enabling real-time protection: $_"
            }
        }
    }
    END {
        if ($Graphics) { $Graphics.Dispose() }
        if ($Bitmap) { $Bitmap.Dispose() }
    }
}
