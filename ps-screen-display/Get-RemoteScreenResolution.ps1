Function Get-RemoteScreenResolution {
    <#
    .SYNOPSIS
    Retrieves information about the screen resolution of a remote computer.

    .DESCRIPTION
    This function connects to a remote computer and retrieves information about its screen resolution, including details about video controllers and monitors.

    .PARAMETER ComputerName
    Specifies the name of the remote computer.
    .PARAMETER Username
    Specifies the username used to authenticate to the remote computer.
    .PARAMETER Pass
    Specifies the password for the specified username.
    .PARAMETER IncludeType
    Include the type of video processor in the output.
    .PARAMETER IncludeLayout
    Include the layout information of the video mode in the output.
    .PARAMETER IncludeRefreshRate
    Include the current refresh rate in the output.
    .PARAMETER IncludeAll
    Include all available information, including details about multiple monitors.
    .PARAMETER IncludeMultipleMonitors
    Include information about multiple monitors if available.

    .EXAMPLE
    Get-RemoteScreenResolution -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Username,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Pass,

        [Parameter(Mandatory = $false, Position = 3)]
        [switch]$IncludeType,

        [Parameter(Mandatory = $false, Position = 4)]
        [switch]$IncludeLayout,

        [Parameter(Mandatory = $false, Position = 5)]
        [switch]$IncludeRefreshRate,

        [Parameter(Mandatory = $false, Position = 6)]
        [switch]$IncludeAll,

        [Parameter(Mandatory = $false, Position = 7)]
        [switch]$IncludeMultipleMonitors
    )
    try {
        $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
        $VideoControllers = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
            param()
            Get-CimInstance -ClassName CIM_VideoController | Select-Object -Property DeviceID, Name, Manufacturer, DriverVersion, VideoProcessor, VideoModeDescription, CurrentRefreshRate
        }
        $Screens = foreach ($Controller in $VideoControllers) {
            $ScreenInfo = [PSCustomObject]@{
                DeviceName    = $Controller.DeviceID
                Manufacturer  = $Controller.Manufacturer
                Model         = $Controller.Name
                DriverVersion = $Controller.DriverVersion
                Type          = $Controller.VideoProcessor
                Layout        = $Controller.VideoModeDescription
                RefreshRate   = $Controller.CurrentRefreshRate
            }
            if ($IncludeMultipleMonitors) {
                $Monitors = Get-MonitorInfo -ComputerName $ComputerName -Credential $Credential -DeviceID $Controller.DeviceID
                foreach ($Monitor in $Monitors) {
                    $MonitorInfo = [PSCustomObject]@{
                        Width      = $Monitor.Width
                        Height     = $Monitor.Height
                        ColorDepth = $Monitor.ColorDepth
                    }
                    $ScreenInfo.Monitors += $MonitorInfo
                }
            }
            $ScreenInfo
        }
        if ($IncludeAll) {
            $Screens
        }
        else {
            $Screens | Select-Object -Property DeviceName, Manufacturer, Model, DriverVersion, Type, Layout, RefreshRate, @{Name = "Monitors"; Expression = { $_.Monitors | Format-Table -AutoSize | Out-String } }
        }
    }
    catch {
        Write-Error -Message "Failed to retrieve remote resolution information. $_"
    }
}
