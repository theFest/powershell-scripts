Function Measure-BandwidthAverage {
    <#
    .SYNOPSIS
    Measures the average bandwidth utilization of network interfaces over a specified duration.
    
    .DESCRIPTION
    This function calculates the percentage of bandwidth utilized by network interfaces over a specified duration, collects data on network traffic, calculates the bandwidth utilization percentage, and provides average statistics.
    
    .PARAMETER DurationMinutes
    Duration, in minutes, for which bandwidth utilization is measured, defaults to 0.1 minutes.
    .PARAMETER InterfaceName
    Name of the network interface for which bandwidth utilization is measured, if not specified, bandwidth utilization for all interfaces is measured.
    .PARAMETER OutputCsvFile
    Path to the CSV file to which the bandwidth measurement data will be exported, defaults to BandwidthAverageMeasure.csv on the user's desktop.
    
    .EXAMPLE
    Measure-BandwidthAverage -DurationMinutes 5 -InterfaceName "Ethernet" -OutputCsvFile "C:\Temp\BandwidthMeasure.csv" -Verbose
    
    .NOTES
    v0.0.9
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Duration in minutes for bandwidth measurement")]
        [Alias("d")]
        [double]$DurationMinutes = 0.1,
    
        [Parameter(Mandatory = $false, HelpMessage = "Name of the network interface for bandwidth measurement")]
        [Alias("i")]
        [string]$InterfaceName = "",
    
        [Parameter(Mandatory = $false, HelpMessage = "Output CSV file path to save the bandwidth data")]
        [Alias("o")]
        [string]$OutputCsvFile = "$env:USERPROFILE\Desktop\BandwidthAverageMeasure.csv"
    )
    $StartTime = Get-Date
    $EndTime = $StartTime.AddMinutes($DurationMinutes)
    $Results = @()
    while ((Get-Date) -lt $EndTime) {
        $ColInterfaces = Get-CimInstance -Class Win32_PerfFormattedData_Tcpip_NetworkInterface | Where-Object { $_.PacketsPersec -gt 0 }
        foreach ($Interface in $ColInterfaces) {
            if (-not [string]::IsNullOrWhiteSpace($InterfaceName) -and $Interface.Name -ne $InterfaceName) {
                continue
            }
            $BitsPerSec = $Interface.BytesTotalPersec * 8
            $TotalBits = $Interface.CurrentBandwidth
            if ($TotalBits -gt 0) {
                $Result = [math]::Round(($BitsPerSec / $TotalBits) * 100, 2)
                $InterfaceInfo = [PSCustomObject]@{
                    DateTime          = Get-Date
                    InterfaceName     = $Interface.Name
                    BandwidthUtilized = $Result
                }
                $Results += $InterfaceInfo
                Write-Host ("{0:s} - Interface: {1} Bandwidth utilized: {2}%" -f $InterfaceInfo.DateTime, $InterfaceInfo.InterfaceName, $InterfaceInfo.BandwidthUtilized) -ForegroundColor DarkCyan
                if (-not [string]::IsNullOrWhiteSpace($OutputCsvFile)) {
                    $InterfaceInfo | Export-Csv -Path $OutputCsvFile -NoTypeInformation -Append
                }
            }
        }
        Start-Sleep -Milliseconds 100
    }
    $Count = $Results.Count
    if ($Count -eq 0) {
        $Message = "No packets were sent/received during the measurement period."
    }
    else {
        $AverageBandwidth = ($Results | Measure-Object -Property BandwidthUtilized -Average).Average
        $Message = "Measurement completed at $(Get-Date).`nMeasurements:`t`t$Count`nAverage Bandwidth utilized:`t$AverageBandwidth %"
        if (-not [string]::IsNullOrWhiteSpace($OutputCsvFile)) {
            $Results | Export-Csv -Path $OutputCsvFile -NoTypeInformation -Append
            $Message += "`nResults appended to CSV file: $OutputCsvFile"
        }
    }
    Write-Host $Message -ForegroundColor Cyan
    if (-not [string]::IsNullOrWhiteSpace($OutputCsvFile)) {
        $Message | Out-String | Add-Content -Path $OutputCsvFile
    }
}
