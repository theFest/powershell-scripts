Function Get-OHMinfo {
    <#
    .SYNOPSIS
    Fetches hardware information and saves it to a specified file.

    .DESCRIPTION
    This function downloads the OpenHardwareMonitor tool, extracts its report, and saves hardware information to a specified file.

    .PARAMETER OutputFilePath
    Mandatory - specifies the path where the hardware information report will be saved.

    .EXAMPLE
    Get-OHMinfo -OutputFilePath "$env:USERPROFILE\Desktop\output.txt"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputFilePath
    )
    $Url = "https://github.com/openhardwaremonitor/openhardwaremonitor/files/1130239/OpenHardwareMonitorReport.zip"
    $TempFolder = "$env:TEMP\OpenHardwareMonitorReport"
    $ReportPath = Join-Path -Path $TempFolder -ChildPath "output.txt"
    try {
        Remove-Item -Path $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
        Invoke-WebRequest -Uri $Url -OutFile "$env:TEMP\OpenHardwareMonitorReport.zip"
        Expand-Archive -Path "$env:TEMP\OpenHardwareMonitorReport.zip" -DestinationPath $TempFolder -Force
        $CmdOutput = cmd /c "cd /d $TempFolder && OpenHardwareMonitorReport.exe"
        $CmdOutput | Out-File -FilePath $ReportPath -Force
        if (Test-Path -Path $ReportPath -PathType Leaf) {
            Move-Item -Path $ReportPath -Destination $OutputFilePath -Force
            Write-Output "Hardware information has been successfully saved to $OutputFilePath"
        }
        else {
            throw "Failed to generate output.txt"
        }
    }
    catch {
        Write-Error -Message "Failed to fetch hardware information: $_"
    }
    finally {
        Remove-Item -Path $TempFolder -Recurse -Force -ErrorAction SilentlyContinue
    }
}
