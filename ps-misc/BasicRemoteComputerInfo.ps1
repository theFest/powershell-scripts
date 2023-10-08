Function Get-RemoteComputerInfo {
    <#
    .SYNOPSIS
    Retrieve detailed information about remote computers.

    .DESCRIPTION
    This function retrieves various details about remote computers, including computer name, operating system, manufacturer, model, serial number, last boot time, and optionally includes hardware information, network adapters, installed software, and user accounts.

    .PARAMETER ComputerName
    Mandatory - The names of the remote computers to retrieve information from.
    .PARAMETER Username
    Mandatory - Username to authenticate with the remote computers.
    .PARAMETER Password
    Mandatory - Password to authenticate with the remote computers.
    .PARAMETER IncludeHardwareInfo
    NotMandatory - Include hardware information such as processor, memory, and disks.
    .PARAMETER IncludeDetailedInfo
    NotMandatory - Include detailed information such as network adapters, installed software, and user accounts.

    .EXAMPLE
    Get-RemoteComputerInfo -ComputerName "your_remote_computer" -Username "your_remote_user" -Pass "your_remote_pass" -IncludeHardwareInfo -IncludeDetailedInfo

    .NOTES
    Version: 0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]$Username,

        [Parameter(Position = 2, Mandatory = $true)]
        [string]$Pass,

        [Parameter()]
        [switch]$IncludeHardwareInfo,

        [Parameter()]
        [switch]$IncludeDetailedInfo
    ) 
    try {
        $Results = foreach ($Computer in $ComputerName) {
            $CredParams = New-Object System.Management.Automation.PSCredential($Username, ($Pass | ConvertTo-SecureString -AsPlainText -Force))
            $Session = New-PSSession -ComputerName $Computer -Credential $CredParams -ErrorAction Stop
            $ScriptBlock = {
                $SystemInfo = Get-WmiObject -Class Win32_ComputerSystem
                $OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem
                $Bios = Get-WmiObject -Class Win32_BIOS
                $Report = @{
                    ComputerName    = $SystemInfo.Name
                    OperatingSystem = $OperatingSystem.Caption
                    Manufacturer    = $SystemInfo.Manufacturer
                    Model           = $SystemInfo.Model
                    SerialNumber    = $Bios.SerialNumber
                    LastBootTime    = $OperatingSystem.ConvertToDateTime($OperatingSystem.LastBootUpTime)
                }
                if ($Using:IncludeHardwareInfo) {
                    $Processor = Get-WmiObject -Class Win32_Processor
                    $Memory = Get-WmiObject -Class Win32_PhysicalMemory
                    $Disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
                    $Report.Processor = $Processor.Name
                    $Report.MemoryGB = [math]::Round(($Memory | Measure-Object -Property Capacity -Sum).Sum / 1GB, 2)
                    $Report.Disks = $Disk | Select-Object DeviceID, VolumeName, @{Name = "SizeGB"; Expression = { [math]::Round($_.Size / 1GB, 2) } }
                }
                if ($Using:IncludeDetailedInfo) {
                    $NetworkAdapters = Get-WmiObject -Class Win32_NetworkAdapter -Filter "NetConnectionStatus = 2"
                    $InstalledSoftware = Get-WmiObject -Class Win32_Product
                    $UserAccounts = Get-WmiObject -Class Win32_UserAccount
                    $Report.NetworkAdapters = $NetworkAdapters | Select-Object Name, NetConnectionID, Speed
                    $Report.InstalledSoftware = $InstalledSoftware | Select-Object Name, Version
                    $Report.UserAccounts = $UserAccounts | Select-Object Name, Description
                }
                $Report
            } 
            $ComputerInfo = Invoke-Command -Session $Session -ScriptBlock $ScriptBlock
            Remove-PSSession -Session $Session
            $ComputerInfo
        }
        $Results
    }
    catch {
        Write-Error "Failed to connect to the remote computer: $($_.Exception.Message)"
    }
}
