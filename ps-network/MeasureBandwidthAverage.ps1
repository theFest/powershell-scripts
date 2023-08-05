Function MeasureBandwidthAverage {
    <#
    .SYNOPSIS
    Function that measures the average bandwidth utilization of a network interface over a specified duration and saves the results in a CSV file.
    
    .DESCRIPTION
    This function calculates the average bandwidth utilization of a network interface over a specified duration. It uses the Win32_PerfFormattedData_Tcpip_NetworkInterface WMI class to obtain network interface information.
    The function takes three optional parameters: DurationMinutes, InterfaceName, and OutputCsvFile. If InterfaceName is provided, it measures the bandwidth utilization of the specified network interface; otherwise, it measures the utilization of all active interfaces.
    Results are displayed on the console and saved to a CSV file if the OutputCsvFile parameter is specified.
    
    .PARAMETER DurationMinutes
    NotMandatory - specifies the duration in minutes for bandwidth measurement. Default value is 0.1 minutes.
    .PARAMETER InterfaceName
    NotMandatory - name of the network interface for bandwidth measurement. If not provided, the function measures the utilization of all active interfaces. 
    .PARAMETER OutputCsvFile
    NotMandatory -  output CSV file path to save the bandwidth data. If not provided, the results are not saved to a CSV file. The default path is the desktop of the current user, with the filename "BandwidthAverageMeasure.csv". 
    
    .EXAMPLE
    MeasureBandwidthAverage -Verbose
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Duration in minutes for bandwidth measurement")]
        [double]$DurationMinutes = 0.1,

        [Parameter(Mandatory = $false, HelpMessage = "Name of the network interface for bandwidth measurement")]
        [string]$InterfaceName = "",

        [Parameter(Mandatory = $false, HelpMessage = "Output CSV file path to save the bandwidth data")]
        [string]$OutputCsvFile = "$env:USERPROFILE\Desktop\BandwidthAverageMeasure.csv"
    )
    $StartTime = Get-Date
    $EndTime = $StartTime.AddMinutes($DurationMinutes)
    $TimeSpan = New-TimeSpan $StartTime $EndTime
    $Count = 0
    $TotalBandwidth = 0
    $Results = @()
    while ($TimeSpan -gt 0) {
        $ColInterfaces = Get-CimInstance -Class Win32_PerfFormattedData_Tcpip_NetworkInterface | Where-Object { $_.PacketsPersec -gt 0 }
        foreach ($Interface in $ColInterfaces) {
            if (-not [string]::IsNullOrWhiteSpace($InterfaceName) -and $Interface.Name -ne $InterfaceName) {
                continue
            }
            $BitsPerSec = $Interface.BytesTotalPersec * 8
            $TotalBits = $Interface.CurrentBandwidth
            if ($TotalBits -gt 0) {
                $Result = (($BitsPerSec / $TotalBits) * 100)
                $InterfaceInfo = [PSCustomObject]@{
                    DateTime          = Get-Date
                    InterfaceName     = $Interface.Name
                    BandwidthUtilized = $Result.ToString('N2')
                }
                $Results += $TnterfaceInfo
                Write-Host ("{0:s} - Interface: {1} Bandwidth utilized: {2}%" -f $InterfaceInfo.DateTime, $InterfaceInfo.InterfaceName, $InterfaceInfo.BandwidthUtilized)
                $TotalBandwidth += $Result
                $Count++
                if (-not [string]::IsNullOrWhiteSpace($OutputCsvFile)) {
                    $InterfaceInfo | Export-Csv -Path $OutputCsvFile -NoTypeInformation -Append
                }
            }
        }
        Start-Sleep -Milliseconds 100
        $TimeSpan = New-TimeSpan $(Get-Date) $EndTime
    }
    if ($Count -eq 0) {
        $Message = "No packets were sent/received during the measurement period."
    }
    else {
        $AverageBandwidth = $TotalBandwidth / $Count
        $Value = "{0:N2}" -f $AverageBandwidth
        $Message = "Measurement completed at $(Get-Date).`nMeasurements:`t`t$Count`nAverage Bandwidth utilized:`t$Value %"
        if (-not [string]::IsNullOrWhiteSpace($OutputCsvFile)) {
            $Results | Export-Csv -Path $OutputCsvFile -NoTypeInformation -Append
            $Message += "`nResults appended to CSV file: $OutputCsvFile"
        }
    }
    Write-Host $Message
    if (-not [string]::IsNullOrWhiteSpace($OutputCsvFile)) {
        $Message | Out-String | Add-Content -Path $OutputCsvFile
    }
}
