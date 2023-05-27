Function BasicSystemInfoForm {
    <#
    .SYNOPSIS
    Gui Forms System Info tool.
    
    .DESCRIPTION
    n/a atm

    .PARAMETER InfoType
    Parameter - 
    .PARAMETER FormWidth
    Parameter - 
    .PARAMETER FormHeight
    Parameter - 
    
    .EXAMPLE
    BasicSystemInfoForm -Verbose
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("ComputerName", "Processor", "OperatingSystem", "RAM", "IPAddresses", "DiskSpace", "Motherboard", "BIOS", `
                "NetworkAdapters", "GraphicsCard", "CurrentUser", "SystemUptime", "InstalledSoftware", "SystemServices", "SystemProcesses", "SystemUsers", `
                "SystemGroups", "PowerStatus", "EnvironmentVariables", "InstalledUpdates", "Printers", "ScreenResolution", "AudioDevices", "USBDevices", "SystemEvents")]
        [string]$InfoType = "ComputerName",

        [Parameter(Mandatory = $false)]
        [ValidateRange(100, 2000)]
        [int]$FormWidth = 1920,

        [Parameter(Mandatory = $false)]
        [ValidateRange(100, 2000)]
        [int]$FormHeight = 1080
    )
    $Form = New-Object System.Windows.Forms.Form
    $Form.Text = "System Information"
    $Form.Width = $FormWidth
    $Form.Height = $FormHeight
    $Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $Form.StartPosition = "CenterScreen"
    $Label = New-Object System.Windows.Forms.Label
    $Label.Text = "Select information to display:"
    $Label.AutoSize = $true
    $Label.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $Label.Location = New-Object System.Drawing.Point(10, 10)
    $Form.Controls.Add($Label)
    $ComboBox = New-Object System.Windows.Forms.ComboBox
    $ComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
    $ComboBox.Items.AddRange(@("Computer Name", "Processor", "Operating System", "RAM", "IP Addresses", "Disk Space", "Motherboard", "BIOS", `
                "Network Adapters", "Graphics Card", "Current User", "System Uptime", "Installed Software", "System Services", "System Processes", "System Users", `
                "System Groups", "Power Status", "Environment Variables", "Installed Updates", "Printers", "Screen Resolution", "Audio Devices", "System Events"))
    $ComboBox.SelectedItem = $InfoType
    $ComboBox.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $ComboBox.Size = New-Object System.Drawing.Size(300, 140)
    $ComboBox.Location = New-Object System.Drawing.Point(250, 10)
    $Form.Controls.Add($ComboBox)
    $ButtonDisplay = New-Object System.Windows.Forms.Button
    $ButtonDisplay.Text = "Display"
    $ButtonDisplay.AutoSize = $true
    $ButtonDisplay.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $ButtonDisplay.BackColor = [System.Drawing.Color]::FromArgb(52, 152, 219)
    $ButtonDisplay.ForeColor = [System.Drawing.Color]::White
    $ButtonDisplay.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ButtonDisplay.Size = New-Object System.Drawing.Size(120, 40)
    $ButtonDisplay.Location = New-Object System.Drawing.Point(1750, 25)
    $ButtonDisplay.Add_Click({
            $Info = ""
            switch ($ComboBox.SelectedItem) {
                "Computer Name" { 
                    try {
                        $Info = Get-WmiObject -Class Win32_ComputerSystem | Select-Object -ExpandProperty Name
                        if ($Info) {
                            Write-Verbose -Message "Computer Name: $Info"
                        }
                        else {
                            Write-Verbose -Message "Computer name not found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving computer name."
                    }
                }
                "Processor" { 
                    try {
                        $Processor = Get-WmiObject -Class Win32_Processor | Select-Object -ExpandProperty Name
                        if ($Processor) {
                            Write-Verbose -Message "+-----------------+"
                            Write-Verbose -Message "|    Processor    |"
                            Write-Verbose -Message "+-----------------+"
                            Write-Verbose -Message "| Name: $Processor |"
                            Write-Verbose -Message "+-----------------+"
                        }
                        else {
                            Write-Verbose -Message "+-----------------+"
                            Write-Verbose -Message "|    Processor    |"
                            Write-Verbose -Message "+-----------------+"
                            Write-Verbose -Message "| No information  |"
                            Write-Verbose -Message "+-----------------+"
                        }
                        $OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem | Select-Object -ExpandProperty Caption
                        if ($OperatingSystem) {
                            Write-Verbose -Message "+-----------------------+"
                            Write-Verbose -Message "|   Operating System    |"
                            Write-Verbose -Message "+-----------------------+"
                            Write-Verbose -Message "| Caption: $OperatingSystem |"
                            Write-Verbose -Message "+-----------------------+"
                        }
                        else {
                            Write-Verbose -Message "+-----------------------+"
                            Write-Verbose -Message "|   Operating System    |"
                            Write-Verbose -Message "+-----------------------+"
                            Write-Verbose -Message "| No information        |"
                            Write-Verbose -Message "+-----------------------+"
                        }
                    }
                    catch {
                        Write-Error -Message "Error occurred while retrieving system information."
                    }
                    finally {
                        $Info = $Processor, $OperatingSystem
                    }
                }
                "Operating System" { 
                    try {
                        $OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem
                        if ($OperatingSystem) {
                            $OSCaption = $OperatingSystem.Caption
                            $OSVersion = $OperatingSystem.Version
                            $OSArchitecture = $OperatingSystem.OSArchitecture
                            $OSInstallDate = $OperatingSystem.InstallDate
                            $OSSerialNumber = $OperatingSystem.SerialNumber
                            Write-Verbose -Message "Operating System Information:"
                            Write-Verbose -Message "+-------------------------------------------+"
                            Write-Verbose -Message "| Caption      : $OSCaption"
                            Write-Verbose -Message "| Version      : $OSVersion"
                            Write-Verbose -Message "| Architecture : $OSArchitecture"
                            Write-Verbose -Message "| Install Date : $OSInstallDate"
                            Write-Verbose -Message "| Serial Number: $OSSerialNumber"
                            Write-Verbose -Message "+-------------------------------------------+"
                        }
                        else {
                            Write-Verbose -Message "Operating System Information:"
                            Write-Verbose -Message "+----------------------------------------------+"
                            Write-Verbose -Message "| No operating system information found |"
                            Write-Verbose -Message "+----------------------------------------------+"
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving operating system information."
                    }
                    finally {
                        $Info = $OperatingSystem, $OSCaption, $OSArchitecture, $OSInstallDate, $OSSerialNumber
                    }
                }
                "RAM" {
                    try {
                        $Info = (Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory
                        $RAM_MB = "{0:N2}" -f ($Info / 1MB)
                        $RAM_GB = "{0:N2}" -f ($Info / 1GB)
                        Write-Verbose -Message "RAM:"
                        if ($RAM_GB -ge 1) {
                            Write-Verbose -Message "  $RAM_GB GB"
                        }
                        elseif ($RAM_MB -ge 1) {
                            Write-Verbose -Message "  $RAM_MB MB"
                        }
                        else {
                            Write-Verbose -Message "  $Info bytes"
                        }
                    }
                    catch {
                        Write-Verbose -Message "Failed to retrieve RAM information: $_"
                    }
                    finally {
                        $Info = $RAM_MB, $RAM_GB
                    }
                }
                "IP Addresses" {
                    try {
                        $NetworkAdapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
                        $Info = $NetworkAdapters | Where-Object { $null -ne $_.IPAddress } | Select-Object -ExpandProperty IPAddress
                        if ($Info) {
                            Write-Verbose -Message "IP Addresses:"
                            foreach ($IP in $Info) {
                                Write-Verbose -Message "  $IP"
                            }
                        }
                        else {
                            Write-Verbose -Message "No IP addresses found."
                        }
                        $DefaultGateway = $NetworkAdapters | Where-Object { $null -ne $_.DefaultIPGateway } | Select-Object -ExpandProperty DefaultIPGateway
                        if ($DefaultGateway) {
                            Write-Verbose -Message "Default Gateway:"
                            foreach ($Gateway in $DefaultGateway) {
                                Write-Verbose -Message "  $Gateway"
                            }
                        }
                        else {
                            Write-Verbose -Message "No default gateway found."
                        }
                        $DNS = $NetworkAdapters | Where-Object { $null -ne $_.DNSDomainSuffixSearchOrder } | Select-Object -ExpandProperty DNSDomainSuffixSearchOrder
                        if ($DNS) {
                            Write-Verbose -Message "DNS Servers:"
                            foreach ($Server in $DNS) {
                                Write-Verbose -Message "  $Server"
                            }
                        }
                        else {
                            Write-Verbose -Message "No DNS servers found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving network information."
                    }
                }
                "Disk Space" { 
                    try {
                        $Info = Get-WmiObject -Class Win32_LogicalDisk | Select-Object -Property DeviceID, FreeSpace, Size
                        if ($Info) {
                            Write-Verbose -Message "Disk Space:"
                            foreach ($Disk in $Info) {
                                $DeviceID = $Disk.DeviceID
                                $FreeSpace = [math]::Round($Disk.FreeSpace / 1GB, 2)
                                $TotalSize = [math]::Round($Disk.Size / 1GB, 2)
                                Write-Verbose -Message "  Drive: $DeviceID"
                                Write-Verbose -Message "    Free Space: $FreeSpace GB"
                                Write-Verbose -Message "    Total Size: $TotalSize GB"
                            }
                        }
                        else {
                            Write-Verbose -Message "No disk information found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving disk space information."
                    }
                }
                "Motherboard" {
                    try {
                        $Info = Get-WmiObject -Class Win32_BaseBoard | Select-Object -ExpandProperty Manufacturer
                        if ($Info) {
                            Write-Verbose -Message "Motherboard Information:"
                            Write-Verbose -Message "+-------------------------+"
                            Write-Verbose -Message "| Manufacturer: $Info |"
                            Write-Verbose -Message "+-------------------------+"
                        }
                        else {
                            Write-Verbose -Message "Motherboard Information:"
                            Write-Verbose -Message "+-------------------------------+"
                            Write-Verbose -Message "| No motherboard information found |"
                            Write-Verbose -Message "+-------------------------------+"
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving motherboard information."
                    }
                }
                "BIOS" { 
                    try {
                        $Info = Get-WmiObject -Class Win32_BIOS
                        if ($Info) {
                            $BIOSInfo = [PSCustomObject]@{
                                SerialNumber = $Info.SerialNumber
                                Manufacturer = $Info.Manufacturer
                                Version      = $Info.SMBIOSBIOSVersion
                                ReleaseDate  = $Info.ReleaseDate
                            }
                            $BIOSInfo
                        }
                        else {
                            Write-Verbose -Message "No BIOS information found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving BIOS information."
                    }
                }
                "Network Adapters" {
                    try {
                        $NetworkAdapters = Get-WmiObject -Class Win32_NetworkAdapter
                        if ($NetworkAdapters) {
                            $Info = $NetworkAdapters | Where-Object { $null -ne $_.Name } | Select-Object -ExpandProperty Name
                            if ($Info) {
                                Write-Verbose -Message "Network Adapters:"
                                Write-Verbose -Message "+----------------------+"
                                foreach ($AdapterName in $Info) {
                                    Write-Verbose -Message "| $AdapterName"
                                }
                                Write-Verbose -Message "+----------------------+"
                            }
                            else {
                                Write-Verbose -Message "No network adapter names found."
                            }
                        }
                        else {
                            Write-Verbose -Message "No network adapters found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving network adapter information."
                    }
                }
                "Graphics Card" { 
                    try {
                        $GraphicsCards = Get-WmiObject -Class Win32_VideoController
                        if ($GraphicsCards) {
                            Write-Verbose -Message "Graphics Cards Information:"
                            Write-Verbose -Message "+--------------------------------------------------+"
                            Write-Verbose -Message "| Name                 | Adapter RAM | Driver Version |"
                            Write-Verbose -Message "+--------------------------------------------------+"
                            foreach ($GraphicsCard in $GraphicsCards) {
                                $Name = $GraphicsCard.Name
                                $AdapterRAM = "{0:N2} MB" -f ($GraphicsCard.AdapterRAM / 1MB)
                                $DriverVersion = $GraphicsCard.DriverVersion
                                Write-Verbose -Message "| $Name | $AdapterRAM | $DriverVersion |"
                            }
                            Write-Verbose -Message "+--------------------------------------------------+"
                        }
                        else {
                            Write-Verbose -Message "No graphics cards found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving graphics card information."
                    }
                    finally {
                        $Info = $Name, $AdapterRAM, $DriverVersion
                    }
                }
                "Current User" { 
                    try {
                        $WindowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
                        if ($WindowsIdentity) {
                            $UserName = $WindowsIdentity.Name
                            $Domain = $WindowsIdentity.User.Value.Split('\')[0]
                            $SID = $WindowsIdentity.User.Value
                            $UserGroups = $WindowsIdentity.Groups | ForEach-Object {
                                $_.Translate([System.Security.Principal.NTAccount]).Value
                            }
                            Write-Verbose -Message "Current User Information:"
                            Write-Verbose -Message "+-------------------------------------+"
                            Write-Verbose -Message "| User Name : $UserName"
                            Write-Verbose -Message "| Domain    : $Domain"
                            Write-Verbose -Message "| SID       : $SID"
                            Write-Verbose -Message "| User Groups:"
                            $UserGroups | ForEach-Object {
                                Write-Verbose -Message "|   $_"
                            }
                            Write-Verbose -Message "+-------------------------------------+"
                        }
                        else {
                            Write-Verbose -Message "No current user information found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving current user information."
                    }
                    finally {
                        $Info = $UserName, $Domain, $SID, $UserGroups
                    }
                }
                "System Uptime" { 
                    try {
                        $OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem
                        if ($OperatingSystem) {
                            $LastBootUpTime = $OperatingSystem.LastBootUpTime
                            $Uptime = (Get-Date) - [System.Management.ManagementDateTimeConverter]::ToDateTime($LastBootUpTime)
                            Write-Verbose -Message "System Uptime:"
                            Write-Verbose -Message "+-----------------------+"
                            Write-Verbose -Message "| Last Boot Up Time: $LastBootUpTime"
                            Write-Verbose -Message "| Uptime           : $Uptime"
                            Write-Verbose -Message "+-----------------------+"
                        }
                        else {
                            Write-Verbose -Message "No system uptime information found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving system uptime information."
                    }
                    finally {
                        $Info = $Uptime
                    }
                }
                "Installed Software" {
                    $Job = Start-Job -ScriptBlock {
                        Get-WmiObject -Class Win32_Product | Select-Object -Property Name, Version, InstallDate
                    }
                    while ($Job.State -eq 'Running') {
                        # Wait for the job to complete
                        Start-Sleep -Milliseconds 500
                    }
                    if ($Job.State -eq 'Completed') {
                        $Info = Receive-Job -Job $Job
                        $Info | Format-Table -AutoSize -Wrap
                    }
                    else {
                        Write-Verbose -Message "Error occurred while retrieving installed software information."
                    }
                    Remove-Job -Job $Job
                }
                "System Services" {
                    try {
                        $ServicesJob = Start-Job -ScriptBlock { Get-Service }
                        $Info = Wait-Job $ServicesJob | Receive-Job
                        if ($Info) {
                            $maxNameLength = ($Info | Measure-Object -Property Name -Maximum).Maximum.Length
                            Write-Verbose -Message "System Services:"
                            Write-Verbose -Message "+-------------------------------------------------------+"
                            Write-Verbose -Message "| Name" -NoNewline
                            Write-Verbose -Message (" " * ($maxNameLength - 4)) -NoNewline
                            Write-Verbose -Message " | Status     | Start Type |"
                            Write-Verbose -Message "+-------------------------------------------------------+"
                            foreach ($Service in $Info) {
                                $Name = $Service.Name.PadRight($maxNameLength)
                                $Status = $Service.Status
                                $StartType = $Service.StartType
                                Write-Verbose -Message "| $Name | $Status | $StartType |"
                            }
                            Write-Verbose -Message "+-------------------------------------------------------+"
                        }
                        else {
                            Write-Verbose -Message "No system services found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving system services information."
                    }
                    finally {
                        if ($ServicesJob.State -eq 'Running') {
                            Remove-Job $ServicesJob -Force
                        }
                    }
                }
                "System Processes" { 
                    try {
                        $Processes = Get-Process
                        if ($Processes) {
                            $Info = $Processes | Select-Object Name, CPU, Memory, StartTime, Responding, MainWindowTitle | Sort-Object CPU -Descending
                            Write-Verbose -Message "System Processes:"
                            Write-Verbose -Message "+---------------------------------------------------------------------------------------------------------------------------+"
                            $Info | Format-Table -AutoSize | Out-String | Write-Verbose -Message
                            Write-Verbose -Message "+---------------------------------------------------------------------------------------------------------------------------+"
                        }
                        else {
                            Write-Verbose -Message "No system processes found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving system processes information."
                    }
                }
                "System Users" {
                    try {
                        $Info = Get-WmiObject -Class Win32_UserAccount
                        if ($Info) {
                            Write-Verbose -Message "System Users:"
                            Write-Verbose -Message "+--------------------------------+----------+"
                            Write-Verbose -Message "| Name" -NoNewline
                            Write-Verbose -Message (" " * (18 - 4)) -NoNewline
                            Write-Verbose -Message " | Disabled |"
                            Write-Verbose -Message "+--------------------------------+----------+"
                            foreach ($User in $Info) {
                                $Name = $User.Name
                                $Disabled = $User.Disabled
                                Write-Verbose -Message "| $Name" -NoNewline
                                Write-Verbose -Message (" " * (18 - $Name.Length)) -NoNewline
                                Write-Verbose -Message " | $Disabled |"
                            }
                            Write-Verbose -Message "+--------------------------------+----------+"
                        }
                        else {
                            Write-Verbose -Message "No system users found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving system users information."
                    }
                }
                "System Groups" {
                    try {
                        $Info = Get-WmiObject -Class Win32_Group
                        if ($Info) {
                            Write-Verbose -Message "System Groups:"
                            Write-Verbose -Message "+---------------------+"
                            Write-Verbose -Message "| Name                |"
                            Write-Verbose -Message "+---------------------+"
                            foreach ($Group in $Info) {
                                $Name = $Group.Name
                                Write-Verbose -Message "| $Name |"
                            }
                            Write-Verbose -Message "+---------------------+"
                        }
                        else {
                            Write-Verbose -Message "No system groups found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving system groups information."
                    }
                }
                "Power Status" {
                    try {
                        $Battery = Get-WmiObject -Class Win32_Battery -ErrorAction Stop
                        if ($Battery) {
                            $BatteryStatus = switch ($Battery.BatteryStatus) {
                                1 { "Discharging" }
                                2 { "AC Power Connected" }
                                3 { "Fully Charged" }
                                4 { "Low" }
                                5 { "Critical" }
                                default { "Unknown" }
                            }
                            $BatteryPercentage = $Battery.EstimatedChargeRemaining
                            $BatteryHealth = switch ($Battery.HealthStatus) {
                                1 { "Unknown" }
                                2 { "Healthy" }
                                3 { "Serviceable" }
                                4 { "Warning" }
                                5 { "Critical" }
                                6 { "Replace Soon" }
                                7 { "Replace Now" }
                                8 { "Battery Presence Unknown" }
                                default { "Unknown" }
                            }
                            Write-Verbose -Message "Battery Power Status: $BatteryStatus"
                            Write-Verbose -Message "Battery Percentage: $BatteryPercentage%"
                            Write-Verbose -Message "Battery Health: $BatteryHealth"
                        }
                        else {
                            Write-Verbose -Message "Battery information: not available"
                        }
                        $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem -ErrorAction Stop
                        if ($ComputerSystem) {
                            $PowerSupplyStatus = switch ($ComputerSystem.PowerSupplyState) {
                                1 { "Power Supply is Off" }
                                2 { "Power Supply is On" }
                                3 { "Power Supply is Present" }
                                default { "Unknown" }
                            }
                            $TotalPhysicalMemory = [math]::Round($ComputerSystem.TotalPhysicalMemory / 1GB, 2)
                            $Manufacturer = $ComputerSystem.Manufacturer
                            $Model = $ComputerSystem.Model
                            Write-Verbose -Message "Power Supply Status: $PowerSupplyStatus"
                            Write-Verbose -Message "Total Physical Memory: $TotalPhysicalMemory GB"
                            Write-Verbose -Message "Manufacturer: $Manufacturer"
                            Write-Verbose -Message "Model: $Model"
                        }
                        else {
                            Write-Verbose -Message "Unable to retrieve power supply status information."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving power status information: $($_.Exception.Message)"
                    }
                    finally {
                        $Info = $Battery, $BatteryHealth, $BatteryStatus, $BatteryPercentage, $PowerSupplyStatus, $TotalPhysicalMemory, $Manufacturer, $Model | Format-Table -AutoSize
                    }
                }
                "Environment Variables" {
                    try {
                        $EnvVariables = Get-ChildItem -Path Env:
                        if ($EnvVariables) {
                            Write-Verbose -Message "Environment Variables:"
                            Write-Verbose -Message "+-----------------------+---------------------------------------------+"
                            Write-Verbose -Message "| Name                  | Value                                       |"
                            Write-Verbose -Message "+-----------------------+---------------------------------------------+"
                            foreach ($Variable in $EnvVariables) {
                                $Name = $Variable.Name
                                $Value = $Variable.Value
                                Write-Verbose -Message "| $Name | $Value |"
                            }
                            Write-Verbose -Message "+-----------------------+---------------------------------------------+"
                        }
                        else {
                            Write-Verbose -Message "No environment variables found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving environment variables information."
                    }
                }
                "Installed Updates" {
                    try {
                        $Updates = Get-WmiObject -Class Win32_QuickFixEngineering
                        if ($Updates) {
                            Write-Verbose -Message "Installed Updates:"
                            Write-Verbose -Message "+------------------+---------------------+"
                            Write-Verbose -Message "| HotFixID         | InstalledOn         |"
                            Write-Verbose -Message "+------------------+---------------------+"
                            foreach ($Update in $Updates) {
                                $HotFixID = $Update.HotFixID
                                $InstalledOn = $Update.InstalledOn
                                Write-Verbose -Message "| $HotFixID | $InstalledOn |"
                            }
                            Write-Verbose -Message "+------------------+---------------------+"
                        }
                        else {
                            Write-Verbose -Message "No installed updates found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving installed updates information."
                    }
                }
                "Printers" {
                    try {
                        $Printers = Get-WmiObject -Class Win32_Printer |
                        Select-Object -Property Name, DriverName, PortName
                        if ($Printers) {
                            $output = $Printers | Format-Table -AutoSize -Property Name, DriverName, PortName -Wrap
                            $output | Out-String
                        }
                        else {
                            Write-Verbose -Message "No printers found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving printer information."
                    }
                    
                }
                "Screen Resolution" { 
                    try {
                        $Info = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Size
                        if ($Info) {
                            $Width = $ScreenResolution.Width
                            $Height = $ScreenResolution.Height
                            Write-Verbose -Message "Screen Resolution: $Width x $Height"
                        }
                        else {
                            Write-Verbose -Message "Unable to retrieve screen resolution information."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving screen resolution information."
                    }
                }
                "Audio Devices" {
                    try {
                        $Info = Get-WmiObject -Class Win32_SoundDevice
                        if ($Info) {
                            Write-Verbose -Message "Audio Devices:"
                            Write-Verbose -Message "+-------------------------------+-----------------------------------+"
                            Write-Verbose -Message "| Name                          | Manufacturer                      |"
                            Write-Verbose -Message "+-------------------------------+-----------------------------------+"
                            foreach ($Device in $Info) {
                                $Name = $Device.Name
                                $Manufacturer = $Device.Manufacturer
                                Write-Verbose -Message "| $Name | $Manufacturer |"
                            }
                            Write-Verbose -Message "+-------------------------------+-----------------------------------+"
                        }
                        else {
                            Write-Verbose -Message "No audio devices found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving audio devices information."
                    }
                }
                "System Events" {
                    $Info = Get-EventLog -LogName System -Newest 10 | Select-Object -Property TimeGenerated, Source, EventID, Message
                    try {
                        $SystemEvents = Get-EventLog -LogName System -Newest 10 | Select-Object -Property TimeGenerated, Source, EventID, Message
                        if ($SystemEvents) {
                            Write-Verbose -Message "System Events:"
                            Write-Verbose -Message "+-----------------+----------------------+----------+"
                            Write-Verbose -Message "| Time Generated  | Source               | Event ID |"
                            Write-Verbose -Message "+-----------------+----------------------+----------+"
                            foreach ($Event in $SystemEvents) {
                                $TimeGenerated = $Event.TimeGenerated
                                $Source = $Event.Source
                                $EventID = $Event.EventID
                                Write-Verbose -Message "| $TimeGenerated | $Source | $EventID |"
                            }
                            Write-Verbose -Message "+-----------------+----------------------+----------+"
                        }
                        else {
                            Write-Verbose -Message "No system events found."
                        }
                    }
                    catch {
                        Write-Verbose -Message "Error occurred while retrieving system events."
                    }
                }
            }
            $FormattedInfo = $Info | Format-Table | Out-String
            if ($FormattedInfo.Trim() -eq "") {
                $FormattedInfo = "No information available for the selected category."
            }
            $LabelOutput.Text = $FormattedInfo
        })
    $Form.Controls.Add($ButtonDisplay)
    $ButtonClose = New-Object System.Windows.Forms.Button
    $ButtonClose.Text = "Close"
    $ButtonClose.AutoSize = $true
    $ButtonClose.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $ButtonClose.BackColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
    $ButtonClose.ForeColor = [System.Drawing.Color]::White
    $ButtonClose.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $ButtonClose.Size = New-Object System.Drawing.Size(120, 40)
    $ButtonClose.Location = New-Object System.Drawing.Point(1760, 980)
    $ButtonClose.Add_Click({ $Form.Close() })
    $Form.Controls.Add($ButtonClose)
    $LabelOutput = New-Object System.Windows.Forms.Label
    $LabelOutput.AutoSize = $false
    $LabelOutput.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $LabelOutput.BackColor = [System.Drawing.Color]::White
    $LabelOutput.Font = New-Object System.Drawing.Font("Segoe UI", 20)
    $LabelOutput.TextAlign = [System.Drawing.ContentAlignment]::TopLeft
    $LabelOutput.Location = New-Object System.Drawing.Point(10, 90)
    $LabelOutput.Size = New-Object System.Drawing.Size(($FormWidth - 40), ($FormHeight - 200))
    $Form.Controls.Add($LabelOutput)
    $StatusBar = New-Object System.Windows.Forms.StatusBar
    $StatusBar.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $StatusBar.ShowPanels = $true
    $StatusBar.Panels.Add((New-Object System.Windows.Forms.StatusBarPanel))
    $StatusBar.Panels[0].AutoSize = "Spring"
    $StatusBar.Panels[0].Text = "Select an information category and click Display."
    $Form.Controls.Add($StatusBar)
    $Form.Add_Shown({ $ComboBox.Focus() })
    $Form.ShowDialog()
}

BasicSystemInfoForm -Verbose
