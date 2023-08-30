Function Get-Screenshot {
    <#
    .SYNOPSIS
    Takes a screenshot with customizable options.
    
    .DESCRIPTION
    This function captures a screenshot of the specified area on the screen with various options such as bounds type, output path, image format, quality, and preview behavior.
    
    .PARAMETER BoundsType
    NotMandatory - type of screen area to capture. Options include 'FullHD', 'HD', '4K', or 'Custom'.
    .PARAMETER OutputPath
    Mandatory - the path where the screenshot image will be saved.
    .PARAMETER ImageFormat
    NotMandatory - format of the screenshot image. Options include 'Bmp', 'Png', 'Jpeg', 'Gif', or 'Tiff'.
    .PARAMETER Quality
    NotMandatory - image quality for formats that support it (0-100).
    .PARAMETER CaptureDelay
    NotMandatory - adds a delay before capturing the screenshot (in seconds).
    .PARAMETER ShowPreview
    NotMandatory - switch to display the screenshot image in a preview window.
    .PARAMETER AutoClosePreview
    NotMandatory - switch to automatically close the preview window after a delay.
    .PARAMETER PreviewCloseDelay
    NotMandatory - delay before automatically closing the preview window.
    .PARAMETER CustomPosition
    NotMandatory - specifies a custom position (point) for the screenshot.
    
    .EXAMPLE
    Get-Screenshot -BoundsType FullHD -OutputPath "$env:USERPROFILE\Desktop\screenshot" -ImageFormat Jpeg -Quality 90 -ShowPreview -AutoClosePreview
    
    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("FullHD", "HD", "4K", "Custom")]
        [string]$BoundsType = "FullHD",

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Bmp", "Png", "Jpeg", "Gif", "Tiff")]
        [string]$ImageFormat = "Png",

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 100)]
        [int]$Quality = 100,

        [Parameter(Mandatory = $false)]
        [int]$CaptureDelay = 0,

        [Parameter(Mandatory = $false)]
        [Switch]$ShowPreview,

        [Parameter(Mandatory = $false)]
        [Switch]$AutoClosePreview,

        [Parameter(Mandatory = $false)]
        [int]$PreviewCloseDelay = 3,

        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [System.Drawing.Point]$CustomPosition
    )
    BEGIN {
        Add-Type -AssemblyName System.Drawing
    }
    PROCESS {
        $Bounds = [Drawing.Rectangle]::Empty
        switch ($BoundsType) {
            "FullHD" { $Bounds = [Drawing.Rectangle]::FromLTRB(0, 0, 1920, 1080) }
            "HD" { $Bounds = [Drawing.Rectangle]::FromLTRB(0, 0, 1280, 720) }
            "4K" { $Bounds = [Drawing.Rectangle]::FromLTRB(0, 0, 3840, 2160) }
            "Custom" {
                $CustomDimensions = Read-Host "Enter custom dimensions for screenshot (format: Width Height)"
                $Width, $Height = $CustomDimensions -split ' '
                if (-not [int]::TryParse($Width, [ref]$null) -or -not [int]::TryParse($Height, [ref]$null)) {
                    Write-Error -Message "Invalid custom dimensions provided."
                    return
                }
                $Bounds = [Drawing.Rectangle]::FromLTRB(0, 0, [int]$Width, [int]$Height)
            }
            default {
                Write-Warning -Message "Invalid BoundsType. Please choose from 'FullHD', 'HD', '4K', or 'Custom'."
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
            $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Png
            switch ($ImageFormat) {
                "Bmp" { $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Bmp }
                "Jpeg" { $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Jpeg }
                "Gif" { $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Gif }
                "Tiff" { $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Tiff }
                Default {
                    Write-Warning -Message "Invalid ImageFormat. Please choose from 'Bmp', 'Png', 'Jpeg', 'Gif', or 'Tiff'."
                    return
                }
            }
            $OutputPathWithExtension = "$OutputPath.$($ImageFormatEnum.ToString().ToLower())"
            $Bitmap.Save($OutputPathWithExtension, $ImageFormatEnum)
            Write-Host "Screenshot saved to $OutputPathWithExtension" -ForegroundColor Cyan
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
