Function Get-DisplayInfo {
    <#
    .SYNOPSIS
    This function reads display information.
    
    .DESCRIPTION
    Reads display information and saves it to .xml file defined in ImagePath parameter.
    
    .PARAMETER ImagePath
    Mandatory - path to your file.
    
    .EXAMPLE
    Get-DisplayInfo -ImagePath C:\your_path\to_file.xml
    
    .NOTES
    v0.1.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath
    )
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize
    $ScreenOrientation = [System.Windows.Forms.SystemInformation]::ScreenOrientation
    if ($ScreenOrientation -eq "Angle0") {
        $ScreenOrientation = "Landscape"  
    }
    elseif ($ScreenOrientation -eq "Angle90") {
        $ScreenOrientation = "Portrait"
    }
    elseif ($ScreenOrientation -eq "Angle180") {
        $ScreenOrientation = "Portrait (flipped)"
    }
    elseif ($ScreenOrientation -eq "Angle270") {
        $ScreenOrientation = "Landscape (flipped)"
    }
    else {
        $ScreenOrientation = "Unknown"
    }
    $XmlW = New-Object System.XMl.XmlTextWriter($ImagePath, $Null)
    $XmlW.Formatting = "Indented"
    $XmlW.Indentation = 1
    $XmlW.IndentChar = "`t"
    $XmlW.WriteStartDocument()
    $XmlW.WriteProcessingInstruction("xml-stylesheet", "type='text/xsl' href='style.xsl'")
    $XmlW.WriteStartElement('Display_info')
    $XmlW.WriteElementString('orientation', $ScreenOrientation)
    $XmlW.WriteEndElement()
    $XmlW.WriteEndDocument()
    $XmlW.Flush()
    $XmlW.Close() 
}