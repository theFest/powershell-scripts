Function Get-USBDevices {
    <#
    .SYNOPSIS
    Retrieves information about USB devices on a local or remote computer.

    .DESCRIPTION
    This function retrieves information about USB devices connected to the specified computer, supports both local and remote execution, requiring appropriate credentials for remote access.

    .PARAMETER ComputerName
    Name of the target computer, default is the local computer.
    .PARAMETER User
    Specifies the username for remote authentication.
    .PARAMETER Pass
    Specifies the password for remote authentication.

    .EXAMPLE
    Get-USBDevices -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Pass
    )
    BEGIN {
        if ($ComputerName -ne $env:COMPUTERNAME) {
            $Session = $null
            $OriginalTrustedHosts = $null
            $OriginalTrustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value
            $TempTrustedHosts = $OriginalTrustedHosts + ',' + $ComputerName
            Set-Item WSMan:\localhost\Client\TrustedHosts -Value $TempTrustedHosts
        }
    }
    PROCESS {
        try {
            if ($ComputerName -eq $env:COMPUTERNAME) {
                $UsbDevices = Get-WmiObject Win32_PnPEntity | Where-Object { $_.PNPClass -eq 'USB' } | ForEach-Object {
                    $DeviceInfo = $_
                    $UsbInfo = @{
                        DeviceID               = $DeviceInfo.DeviceID
                        Description            = $DeviceInfo.Description
                        Manufacturer           = $DeviceInfo.Manufacturer
                        Status                 = $DeviceInfo.Status
                        Service                = $DeviceInfo.Service
                        ClassGuid              = $DeviceInfo.ClassGuid
                        DeviceName             = $DeviceInfo.DeviceName
                        Caption                = $DeviceInfo.Caption
                        ConfigManagerErrorCode = if ($DeviceInfo.ConfigManagerErrorCode) { $DeviceInfo.ConfigManagerErrorCode } else { 'N/A' }
                        DeviceType             = if ($DeviceInfo.DeviceType) { $DeviceInfo.DeviceType } else { 'N/A' }
                        Availability           = if ($DeviceInfo.Availability) { $DeviceInfo.Availability } else { 'N/A' }
                        InstallDate            = if ($DeviceInfo.InstallDate) { $DeviceInfo.InstallDate } else { 'N/A' }
                        LastErrorCode          = if ($DeviceInfo.LastErrorCode) { $DeviceInfo.LastErrorCode } else { 'N/A' }
                        PNPDeviceID            = $DeviceInfo.PNPDeviceID
                    }
                    if (-not $UsbInfo.DeviceName) {
                        $UsbInfo.DeviceName = (Get-WmiObject Win32_ComputerSystem).Name
                    }
                    $UsbController = Get-WmiObject Win32_USBController | Where-Object { $_.PNPDeviceID -eq $DeviceInfo.PNPDeviceID }
                    if ($UsbController) {
                        $UsbInfo += @{
                            ControllerID           = $UsbController.DeviceID
                            ControllerDescription  = $UsbController.Description
                            ControllerManufacturer = $UsbController.Manufacturer
                            ControllerStatus       = $UsbController.Status
                            ControllerPNPDeviceID  = $UsbController.PNPDeviceID
                        }
                    }
                    $UsbHub = Get-WmiObject Win32_USBHub | Where-Object { $_.PNPDeviceID -eq $DeviceInfo.PNPDeviceID }
                    if ($UsbHub) {
                        $UsbInfo += @{
                            HubID           = $UsbHub.DeviceID
                            HubDescription  = $UsbHub.Description
                            HubManufacturer = $UsbHub.Manufacturer
                            HubStatus       = $UsbHub.Status
                            HubPNPDeviceID  = $UsbHub.PNPDeviceID
                        }
                    }
                    [PSCustomObject]$UsbInfo
                }
            }
            else {
                $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
                $Credential = New-Object -TypeName PSCredential -ArgumentList $User, $SecurePassword
                $SessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
                $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -SessionOption $SessionOption
                $UsbDevices = Invoke-Command -Session $Session -ScriptBlock {
                    Get-WmiObject Win32_PnPEntity | Where-Object { $_.PNPClass -eq 'USB' } | ForEach-Object {
                        $DeviceInfo = $_
                        $UsbInfo = @{
                            DeviceID               = $DeviceInfo.DeviceID
                            Description            = $DeviceInfo.Description
                            Manufacturer           = $DeviceInfo.Manufacturer
                            Status                 = $DeviceInfo.Status
                            Service                = $DeviceInfo.Service
                            ClassGuid              = $DeviceInfo.ClassGuid
                            DeviceName             = $DeviceInfo.DeviceName
                            Caption                = $DeviceInfo.Caption
                            ConfigManagerErrorCode = if ($DeviceInfo.ConfigManagerErrorCode) { $DeviceInfo.ConfigManagerErrorCode } else { 'N/A' }
                            DeviceType             = if ($DeviceInfo.DeviceType) { $DeviceInfo.DeviceType } else { 'N/A' }
                            Availability           = if ($DeviceInfo.Availability) { $DeviceInfo.Availability } else { 'N/A' }
                            InstallDate            = if ($DeviceInfo.InstallDate) { $DeviceInfo.InstallDate } else { 'N/A' }
                            LastErrorCode          = if ($DeviceInfo.LastErrorCode) { $DeviceInfo.LastErrorCode } else { 'N/A' }
                            PNPDeviceID            = $DeviceInfo.PNPDeviceID
                        }
                        if (-not $UsbInfo.DeviceName) {
                            $UsbInfo.DeviceName = (Get-WmiObject Win32_ComputerSystem).Name
                        }
                        $UsbController = Get-WmiObject Win32_USBController | Where-Object { $_.PNPDeviceID -eq $DeviceInfo.PNPDeviceID }
                        if ($UsbController) {
                            $UsbInfo += @{
                                ControllerID           = $UsbController.DeviceID
                                ControllerDescription  = $UsbController.Description
                                ControllerManufacturer = $UsbController.Manufacturer
                                ControllerStatus       = $UsbController.Status
                                ControllerPNPDeviceID  = $UsbController.PNPDeviceID
                            }
                        }
                        $UsbHub = Get-WmiObject Win32_USBHub | Where-Object { $_.PNPDeviceID -eq $DeviceInfo.PNPDeviceID }
                        if ($UsbHub) {
                            $UsbInfo += @{
                                HubID           = $UsbHub.DeviceID
                                HubDescription  = $UsbHub.Description
                                HubManufacturer = $UsbHub.Manufacturer
                                HubStatus       = $UsbHub.Status
                                HubPNPDeviceID  = $UsbHub.PNPDeviceID
                            }
                        }
                        [PSCustomObject]$UsbInfo
                    }
                }
            }
            $UsbDevices
        }
        catch {
            Write-Host "Error retrieving information: $_" -ForegroundColor Red
        }
    }
    END {
        if ($ComputerName -ne $env:COMPUTERNAME) {
            Set-Item WSMan:\localhost\Client\TrustedHosts -Value $OriginalTrustedHosts
            if ($null -ne $Session) {
                Remove-PSSession -Session $Session -Verbose
            }
        }
    }
}
