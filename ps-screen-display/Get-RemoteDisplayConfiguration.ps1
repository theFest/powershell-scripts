function Get-RemoteDisplayConfiguration {
    <#
    .SYNOPSIS
    Retrieves the display configuration from a remote computer, including details about video controllers and monitors.

    .DESCRIPTION
    This function connects to a specified remote computer using provided credentials and retrieves information about the video controllers and monitors.
    The retrieved details can include the video processor type, display layout, refresh rate, and monitor specifics if requested. The results can be displayed in a formatted table or as detailed information about each video controller and monitor.

    .EXAMPLE
    Get-RemoteDisplayConfiguration -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -IncludeType -IncludeLayout -IncludeRefreshRate -IncludeMultipleMonitors

    .NOTES
    v0.3.0
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Specify the name or IP address of the remote computer")]
        [Alias("c")]
        [string]$ComputerName,

        [Parameter(Mandatory = $true, HelpMessage = "Username for authentication on the remote computer")]
        [Alias("u")]
        [string]$User,

        [Parameter(Mandatory = $true, HelpMessage = "Password for the remote user account. Will be converted to a secure string")]
        [Alias("p")]
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "Type of the video processor in the output (e.g., GPU name)")]
        [Alias("it")]
        [switch]$IncludeType,

        [Parameter(Mandatory = $false, HelpMessage = "Screen layout or resolution in the output (e.g., 1920x1080)")]
        [Alias("il")]
        [switch]$IncludeLayout,

        [Parameter(Mandatory = $false, HelpMessage = "Refresh rate of the display in the output (e.g., 60Hz)")]
        [Alias("ir")]
        [switch]$IncludeRefreshRate,

        [Parameter(Mandatory = $false, HelpMessage = "Include all available information, such as device type, layout, refresh rate, and monitor details")]
        [Alias("ia")]
        [switch]$IncludeAll,

        [Parameter(Mandatory = $false, HelpMessage = "Include detailed information for multiple monitors connected to the system")]
        [Alias("im")]
        [switch]$IncludeMultipleMonitors
    )
    if ($PSCmdlet.ShouldProcess("Retrieve remote display configuration from $ComputerName")) {
        try {
            $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ($User, $SecurePassword)
            $VideoControllers = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                Get-CimInstance -ClassName CIM_VideoController | 
                Select-Object -Property DeviceID, Name, Manufacturer, DriverVersion, VideoProcessor, VideoModeDescription, CurrentRefreshRate
            }
            $Screens = @()
            foreach ($Controller in $VideoControllers) {
                $ScreenInfo = [PSCustomObject]@{
                    DeviceName    = if ($Controller.DeviceID) { $Controller.DeviceID } else { "N/A" }
                    Manufacturer  = if ($Controller.Manufacturer) { $Controller.Manufacturer } else { "N/A" }
                    Model         = if ($Controller.Name) { $Controller.Name } else { "N/A" }
                    DriverVersion = if ($Controller.DriverVersion) { $Controller.DriverVersion } else { "N/A" }
                    Type          = if ($IncludeType -and $Controller.VideoProcessor) { $Controller.VideoProcessor } else { "N/A" }
                    Layout        = if ($IncludeLayout -and $Controller.VideoModeDescription) { $Controller.VideoModeDescription } else { "N/A" }
                    RefreshRate   = if ($IncludeRefreshRate -and $Controller.CurrentRefreshRate) { $Controller.CurrentRefreshRate } else { "N/A" }
                    Monitors      = @()
                }
                if ($IncludeMultipleMonitors) {
                    try {
                        $MonitorDetails = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                            Get-CimInstance -Class Win32_DesktopMonitor | 
                            Select-Object -Property ScreenWidth, ScreenHeight, BitsPerPixel
                        }
                        foreach ($Monitor in $MonitorDetails) {
                            $MonitorInfo = [PSCustomObject]@{
                                Width      = if ($Monitor.ScreenWidth) { $Monitor.ScreenWidth } else { "Unknown" }
                                Height     = if ($Monitor.ScreenHeight) { $Monitor.ScreenHeight } else { "Unknown" }
                                ColorDepth = if ($Monitor.BitsPerPixel) { $Monitor.BitsPerPixel } else { "Unknown" }
                            }
                            $ScreenInfo.Monitors += $MonitorInfo
                        }
                    }
                    catch {
                        Write-Warning -Message "Failed to retrieve monitor information for DeviceID: $($Controller.DeviceID). Error: $_"
                    }
                }
                $Screens += $ScreenInfo
            }
            if ($IncludeAll) {
                $Screens | Format-Table -AutoSize
            }
            else {
                $Screens | Select-Object -Property DeviceName, Manufacturer, Model, DriverVersion, 
                @{Name = "Type"; Expression = { if ($IncludeType) { $_.Type } else { "N/A" } } },
                @{Name = "Layout"; Expression = { if ($IncludeLayout) { $_.Layout } else { "N/A" } } },
                @{Name = "Refresh Rate"; Expression = { if ($IncludeRefreshRate) { $_.RefreshRate } else { "N/A" } } },
                @{Name = "Monitors"; Expression = { 
                        if ($IncludeMultipleMonitors) { 
                            $_.Monitors | Format-Table -AutoSize | Out-String 
                        }
                        else { "N/A" } 
                    }
                }
            }
        }
        catch {
            Write-Error -Message "Failed to retrieve remote resolution information from $ComputerName. Error: $_"
        }
    }
    else {
        Write-Host "Operation canceled by user!" -ForegroundColor DarkYellow
    }
}
