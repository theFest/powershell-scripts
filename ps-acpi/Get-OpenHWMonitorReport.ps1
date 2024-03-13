Function Get-OpenHWMonitorReport {
    <#
    .SYNOPSIS
    Retrieves hardware information using Open Hardware Monitor and saves it to a specified file.

    .DESCRIPTION
    This function downloads Open Hardware Monitor, extracts the report, executes it to gather hardware information, and saves the output to a specified file path.

    .PARAMETER OutputFilePath
    Specifies the path where the hardware information report will be saved.
    .PARAMETER Url
    Specifies the URL from which to download the Open Hardware Monitor report, default is the latest version available on GitHub.
    .PARAMETER TempFolder
    Temporary folder where the report will be extracted. Default is the user's TEMP directory.

    .EXAMPLE
    Get-OpenHWMonitorReport -OutputFilePath "$env:USERPROFILE\Desktop\output.txt"

    .NOTES
    v0.2.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Output file path")]
        [Alias("o")]
        [string]$OutputFilePath,

        [Parameter(Mandatory = $false, HelpMessage = "URL to download OpenHardwareMonitorReport")]
        [Alias("u")]
        [string]$Url = "https://github.com/openhardwaremonitor/openhardwaremonitor/files/1130239/OpenHardwareMonitorReport.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the temporary folder to extract the report")]
        [Alias("t")]
        [string]$TempFolder = "$env:TEMP\OpenHardwareMonitorReport"
    )
    try {
        Remove-Item -Path $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
        Invoke-WebRequest -Uri $Url -OutFile "$env:TEMP\OpenHardwareMonitorReport.zip"
        Expand-Archive -Path "$env:TEMP\OpenHardwareMonitorReport.zip" -DestinationPath $TempFolder -Force
        $CmdOutput = cmd /c "cd /d $TempFolder && OpenHardwareMonitorReport.exe"
        $ReportPath = Join-Path -Path $TempFolder -ChildPath "output.txt"
        $CmdOutput | Out-File -FilePath $ReportPath -Force
        if (Test-Path -Path $ReportPath -PathType Leaf) {
            Move-Item -Path $ReportPath -Destination $OutputFilePath -Force
            Write-Output "Hardware information has been successfully saved to $OutputFilePath"
        }
        else {
            throw "Failed to generate output file!"
        }
    }
    catch {
        Write-Error -Message "Failed to fetch hardware information: $_"
    }
    finally {
        Write-Verbose -Message "Removing temp folder and finishing..."
        Remove-Item -Path $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
}
