#requires -version 5.1
Function Export-IconFromFile {
    <#
    .SYNOPSIS
    Extracts the associated icon from a file and saves it in a specified format and destination.

    .DESCRIPTION
    This function extracts the associated icon from a specified file and saves it in a specified format and destination, supported image formats include ico, bmp, png, jpg, and gif.

    .PARAMETER Path
    Path to the file from which to extract the icon.
    .PARAMETER Destination
    Folder to save the extracted icon.
    .PARAMETER Name
    Specifies an alternate base name for the new image file.
    .PARAMETER Format
    Format for the saved image file, supported formats are ico, bmp, png, jpg, and gif.

    .EXAMPLE
    Export-IconFromFile -Path "$env:windir\regedit.exe" -Destination "$env:USERPROFILE\Desktop" -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Specify the path to the file")]
        [ValidateScript({ 
                Test-Path -Path $_ 
            })]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Specify the folder to save the file")]
        [ValidateScript({ 
                Test-Path -Path $_
            })]
        [string]$Destination,

        [parameter(Mandatory = $false, Position = 2, HelpMessage = "Specify an alternate base name for the new image file. Otherwise, the source name will be used")]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "What format do you want to use? The default is png")]
        [ValidateSet("ico", "bmp", "png", "jpg", "gif")]
        [string]$Format = "png"
    )
    BEGIN {
        Write-Verbose -Message "Starting $($MyInvocation.MyCommand)"
    }
    PROCESS {
        try {
            Add-Type -AssemblyName System.Drawing -ErrorAction Stop
        }
        catch {
            Write-Warning -Message "Failed to import System.Drawing!"
            throw $_
        }
        switch ($Format) {
            "ico" { $ImageFormat = "icon" }
            "bmp" { $ImageFormat = "Bmp" }
            "png" { $ImageFormat = "Png" }
            "jpg" { $ImageFormat = "Jpeg" }
            "gif" { $ImageFormat = "Gif" }
        }
        $File = Get-Item -Path $Path
        Write-Verbose -Message "Processing $($File.FullName)"
        $Destination = Convert-Path -Path $Destination
        if ($Name) {
            $Base = $Name
        }
        else {
            $Base = $File.BaseName
        }
        $Out = Join-Path -Path $Destination -ChildPath "$Base.$Format"
        Write-Verbose -Message "Extracting $ImageFormat image to $Out"
        $Ico = [System.Drawing.Icon]::ExtractAssociatedIcon($File.FullName)
        if ($Ico) {
            if ($PSCmdlet.ShouldProcess($Out, "Extract icon")) {
                $Ico.ToBitmap().Save($Out, $Imageformat)
                Get-Item -Path $Out -Verbose
            }
        }
        else {
            Write-Warning -Message "No associated icon image found in $($File.FullName)"
        }
    }
    END {
        Write-Verbose -Message "Ending $($MyInvocation.MyCommand)"
    }
}
