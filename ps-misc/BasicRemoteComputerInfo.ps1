Function BasicRemoteComputerInfo {
    <#
    .SYNOPSIS
    Basic and detailed information about remote computers.

    .DESCRIPTION
    This function retrieves basic information about remote computers, including computer name, operating system, manufacturer, model, serial number, and last boot time. When the DetailedReport parameter is specified, it also retrieves additional details such as network adapters, installed software, and user accounts.

    .PARAMETER ComputerName
    Mandatory - the names of the remote computers to retrieve information from.
    .PARAMETER Username
    Mandatory - username to authenticate with the remote computers.
    .PARAMETER Password
    Mandatory - password to authenticate with the remote computers.
    .PARAMETER DetailedReport
    NotMandatory - include a detailed report in the output.
    .PARAMETER IncludeHardwareInfo
    NotMandatory - include hardware information such as processor, memory, and disks.

    .EXAMPLE
    BasicRemoteComputerInfo -ComputerName "your_remote_computer" -Username "your_remote_user" -Password "your_remote_pass" -IncludeHardwareInfo -DetailedReport

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName,

        [Parameter(Position = 1, Mandatory = $true)]
        [string]$Username,

        [Parameter(Position = 2, Mandatory = $true)]
        [string]$Pass,

        [Parameter(Position = 3)]
        [switch]$DetailedReport,

        [Parameter(Position = 4)]
        [switch]$IncludeHardwareInfo
    ) 
    try {
        $Results = foreach ($Computer in $ComputerName) {
            $CredParams = New-Object System.Management.Automation.PSCredential($Username, ($Pass | ConvertTo-SecureString -AsPlainText -Force))
            $Session = New-PSSession -ComputerName $Computer -Credential $CredParams -ErrorAction Stop
            $ScriptBlock = {
                $SystemInfo = Get-WmiObject -Class Win32_ComputerSystem
                $OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem
                $Bios = Get-WmiObject -Class Win32_BIOS
                if ($Using:IncludeHardwareInfo) {
                    $Processor = Get-WmiObject -Class Win32_Processor
                    $Memory = Get-WmiObject -Class Win32_PhysicalMemory
                    $Disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
                }
                $Report = @{
                    ComputerName    = $SystemInfo.Name
                    OperatingSystem = $OperatingSystem.Caption
                    Manufacturer    = $SystemInfo.Manufacturer
                    Model           = $SystemInfo.Model
                    SerialNumber    = $Bios.SerialNumber
                    LastBootTime    = $OperatingSystem.LastBootUpTime
                }
                if ($Using:IncludeHardwareInfo) {
                    $Report.Processor = $Processor.Name
                    $Report.Memory = ($Memory | Measure-Object -Property Capacity -Sum).Sum / 1GB
                    $Report.Disks = $Disk | Select-Object DeviceID, VolumeName, @{Name = "Size (GB)"; Expression = { $_.Size / 1GB } }
                }
                if ($Using:DetailedReport) {
                    $NetworkAdapters = Get-WmiObject -Class Win32_NetworkAdapter -Filter "NetConnectionStatus = 2"
                    $InstalledSoftware = Get-WmiObject -Class Win32_Product
                    $UserAccounts = Get-WmiObject -Class Win32_UserAccount

                    $Report.NetworkAdapters = $NetworkAdapters | Select-Object Name, NetConnectionID, Speed
                    $Report.InstalledSoftware = $InstalledSoftware | Select-Object Name, Version
                    $Report.UserAccounts = $UserAccounts | Select-Object Name, Description
                }
                $Report
            }
            Invoke-Command -Session $Session -ScriptBlock $ScriptBlock
            Remove-PSSession -Session $Session
        }
        $Results
    }
    catch {
        Write-Error "Failed to connect to the remote computer: $($_.Exception.Message)"
    }
}
