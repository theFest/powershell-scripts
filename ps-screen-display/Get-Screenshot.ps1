Function Get-Screenshot {
    <#
    .SYNOPSIS
    Captures a screenshot of the specified screen area.
    
    .DESCRIPTION
    This function captures a screenshot of the specified screen area and saves it to the specified output path.
    Provides options for selecting the screen area, choosing the image format, adjusting image quality, and displaying a preview of the captured screenshot.
    
    .PARAMETER BoundsType
    NotMandatory - type of screen area to capture. Valid values are "FullHD", "HD", "4K", and "Custom". Default is "FullHD".
    .PARAMETER OutputPath
    Mandatory - specifies the path where the screenshot image will be saved.
    .PARAMETER ImageFormat
    NotMandatory - format of the screenshot image. Valid values are "Bmp", "Png", "Jpeg", "Gif", and "Tiff". Default is "Png".
    .PARAMETER Quality
    NotMandatory - the image quality when using lossy image formats. The value should be between 1 and 100. Default is 100.
    .PARAMETER ShowPreview
    NotMandatory - if specified, displays a preview of the captured screenshot after saving.
    
    .EXAMPLE
    Get-Screenshot -BoundsType FullHD -OutputPath "$env:USERPROFILE\Desktop\ss" -ImageFormat Tiff -ShowPreview
    
    .NOTES
    v0.0.1
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
        [switch]$ShowPreview
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
                $Width, $Height = $CustomDimensions -split 'x'
                $Bounds = [Drawing.Rectangle]::FromLTRB(0, 0, [int]$Width, [int]$Height)
            }
        }
        try {
            $Bitmap = New-Object Drawing.Bitmap $Bounds.Width, $Bounds.Height
            $Graphics = [Drawing.Graphics]::FromImage($Bitmap)
            $Graphics.CopyFromScreen($Bounds.Location, [Drawing.Point]::Empty, $Bounds.Size)
            $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Png
            switch ($ImageFormat) {
                "Bmp" { $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Bmp }
                "Jpeg" { $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Jpeg }
                "Gif" { $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Gif }
                "Tiff" { $ImageFormatEnum = [System.Drawing.Imaging.ImageFormat]::Tiff }
            }
            $OutputPathWithExtension = "$OutputPath.$($ImageFormatEnum.ToString().ToLower())"
            $Bitmap.Save($OutputPathWithExtension, $ImageFormatEnum)
            Write-Host "Screenshot saved to $OutputPathWithExtension"
            if ($ShowPreview) {
                $Bitmap.Dispose()
                Invoke-Item -Path $OutputPathWithExtension
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
        Write-Verbose -Message "Look at path for a screenshot..."
    }
}
