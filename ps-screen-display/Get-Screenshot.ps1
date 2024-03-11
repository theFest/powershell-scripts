Function Get-Screenshot {
    <#
    .SYNOPSIS
    Captures a screenshot of the specified area of the screen.

    .DESCRIPTION
    This function captures a screenshot of the specified area of the screen and saves it to the specified output path. Provides options to customize the screenshot dimensions, image format, quality, delay before capture, and more.

    .PARAMETER BoundsType
    Type of bounds for the screenshot, values are "FullHD", "HD", "4K", or "Custom".
    .PARAMETER OutputPath
    Specifies the path where the screenshot will be saved.
    .PARAMETER ImageFormat
    Format of the output image, values are "Bmp", "Png", "Jpeg", "Gif", or "Tiff".
    .PARAMETER Quality
    Quality of the output image for formats that support it (e.g., Jpeg).
    .PARAMETER CaptureDelay
    Delay in seconds before capturing the screenshot.
    .PARAMETER ShowPreview
    Show a preview of the captured screenshot.
    .PARAMETER AutoClosePreview
    Automatically close the preview window after a specified delay.
    .PARAMETER PreviewCloseDelay
    Delay in seconds before automatically closing the preview window.
    .PARAMETER CustomPosition
    Custom position (top-left corner) for capturing the screenshot.
    .PARAMETER SuppressOutput
    Indicates whether to suppress output messages.
    .PARAMETER AddTimestamp
    Append a timestamp to the filename of the screenshot.

    .EXAMPLE
    Get-Screenshot -BoundsType FullHD -OutputPath "$env:USERPROFILE\Desktop\screenshot" -ImageFormat Jpeg -Quality 90 -ShowPreview -AutoClosePreview

    .NOTES
    This function requires administrative privileges to stop and start Windows Defender Real-time Protection.
    v0.1.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("FullHD", "HD", "4K", "Custom")]
        [Alias("b")]
        [string]$BoundsType = "FullHD",

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("o")]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Bmp", "Png", "Jpeg", "Gif", "Tiff")]
        [Alias("f")]
        [string]$ImageFormat = "Png",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [Alias("q")]
        [int]$Quality = 100,

        [Parameter(Mandatory = $false)]
        [Alias("d")]
        [int]$CaptureDelay = 0,

        [Parameter(Mandatory = $false)]
        [Alias("sp")]
        [switch]$ShowPreview,

        [Parameter(Mandatory = $false)]
        [Alias("ac")]
        [switch]$AutoClosePreview,

        [Parameter(Mandatory = $false)]
        [Alias("p")]
        [int]$PreviewCloseDelay = 3,

        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [Alias("c")]
        [System.Drawing.Point]$CustomPosition,

        [Parameter(Mandatory = $false)]
        [Alias("s")]
        [switch]$SuppressOutput,

        [Parameter(Mandatory = $false)]
        [Alias("t")]
        [switch]$AddTimestamp
    )
    BEGIN {
        Add-Type -AssemblyName System.Drawing
    }
    PROCESS {
        $Bounds = [Drawing.Rectangle]::Empty
        switch ($BoundsType) {
            "FullHD" {
                $Bounds = [Drawing.Rectangle]::FromLTRB(0, 0, 1920, 1080) 
            }
            "HD" {
                $Bounds = [Drawing.Rectangle]::FromLTRB(0, 0, 1280, 720) 
            }
            "4K" {
                $Bounds = [Drawing.Rectangle]::FromLTRB(0, 0, 3840, 2160) 
            }
            "Custom" {
                $CustomDimensions = Read-Host "Enter custom dimensions for screenshot (format: Width Height)"
                $Width, $Height = $CustomDimensions -split ' '
                if (-not [int]::TryParse($Width, [ref]$null) -or -not [int]::TryParse($Height, [ref]$null)) {
                    Write-Error -Message "Invalid custom dimensions provided!"
                    return
                }
                $Bounds = [Drawing.Rectangle]::FromLTRB(0, 0, [int]$Width, [int]$Height)
            }
            default {
                Write-Warning -Message "Invalid BoundsType. Please choose from 'FullHD', 'HD', '4K', or 'Custom'!"
                return
            }
        }
        try {
            if ($CaptureDelay -gt 0) {
                Write-Host "Delaying for $CaptureDelay seconds before capturing screenshot..."
                Start-Sleep -Seconds $CaptureDelay
            }
            $Bitmap = New-Object Drawing.Bitmap $Bounds.Width, $Bounds.Height
            $Graphics = [Drawing.Graphics]::FromImage($Bitmap)
            if ($CustomPosition -ne $null) {
                $Bounds.Location = $CustomPosition
            }    
            $Graphics.CopyFromScreen($Bounds.Location, [Drawing.Point]::Empty, $Bounds.Size)
            if ($AddTimestamp) {
                $Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                $OutputPath = Join-Path -Path $OutputPath -ChildPath "Screenshot_$Timestamp"
            }
            $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Png
            switch ($ImageFormat) {
                "Bmp" { 
                    $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Bmp 
                }
                "Jpeg" {
                    $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Jpeg 
                }
                "Gif" {
                    $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Gif 
                }
                "Tiff" {
                    $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Tiff 
                }
                default {
                    Write-Warning -Message "Invalid ImageFormat. Please choose from 'Bmp', 'Png', 'Jpeg', 'Gif', or 'Tiff'."
                    return
                }
            }
            $OutputPathWithExtension = "$OutputPath.$($ImageFormatEnum.ToString().ToLower())"
            $Bitmap.Save($OutputPathWithExtension, $ImageFormatEnum)
            if (-not $SuppressOutput) {
                Write-Host "Screenshot saved to $OutputPathWithExtension" -ForegroundColor Cyan
            }
            if ($ShowPreview) {
                $PreviewProcess = Start-Process -FilePath $OutputPathWithExtension -PassThru
                if ($AutoClosePreview) {
                    Start-Sleep -Seconds $PreviewCloseDelay
                    $PreviewProcess | ForEach-Object {
                        $PreviewProcessId = $_.Id
                        $AssociatedProgram = Get-Process | Where-Object { $_.MainWindowHandle -eq $_.MainWindowHandle }
                        if ($AssociatedProgram) {
                            Stop-Process -Id $PreviewProcessId -Force
                        }
                    }
                }
            }
        }
        catch {
            Write-Error -Message "Error taking screenshot: $_"
        }
        finally {
            if ($Graphics) { 
                $Graphics.Dispose() 
            }
            if ($Bitmap) { 
                $Bitmap.Dispose() 
            }
        }
    }
    END {
        Write-Verbose -Message "Opening the screenshot directory using the default file explorer..."
        if (Test-Path -Path $OutputPath -PathType Container) {
            Invoke-Item -Path (Get-Item $OutputPath).FullName
        }
    }
}
