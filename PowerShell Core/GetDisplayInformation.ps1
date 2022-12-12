Function GetDisplayInformation {
    <#
    .SYNOPSIS
    This function reads display information. (only screen orientation for now)
    
    .DESCRIPTION
    Reads display information and saves it to .xml file defined in ImagePath parameter.
    
    .PARAMETER ImagePath
    Mandatory - path to your file. (for now onyl local)
    
    .EXAMPLE
    GetDisplayInformation -ImagePath C:\your_path\to_file.xml (any image)
    
    .NOTES
    v0.1
    ** add resolution and screen size in the future.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)] [string]$ImagePath
    )
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SystemInformation]::PrimaryMonitorSize
    $ScreenOrientation = [System.Windows.Forms.SystemInformation]::ScreenOrientation
    if ($ScreenOrientation -eq 'Angle0') {
        $ScreenOrientation = 'Landscape'  
    }
    elseif ($ScreenOrientation -eq 'Angle90') {
        $ScreenOrientation = 'Portrait'
    }
    elseif ($ScreenOrientation -eq 'Angle180') {
        $ScreenOrientation = 'Portrait (flipped)'
    }
    elseif ($ScreenOrientation -eq 'Angle270') {
        $ScreenOrientation = 'Landscape (flipped)'
    }
    else {
        $ScreenOrientation = 'Unknown'
    }
    $XmlWriter = New-Object System.XMl.XmlTextWriter($ImagePath, $Null)
    $xmlWriter.Formatting = 'Indented'
    $xmlWriter.Indentation = 1
    $XmlWriter.IndentChar = "`t"
    $xmlWriter.WriteStartDocument()
    $xmlWriter.WriteProcessingInstruction("xml-stylesheet", "type='text/xsl' href='style.xsl'")
    $xmlWriter.WriteStartElement('Display_info')
    $xmlWriter.WriteElementString('orientation', $ScreenOrientation)
    $xmlWriter.WriteEndElement()
    $xmlWriter.WriteEndDocument()
    $xmlWriter.Flush()
    $xmlWriter.Close() 
}