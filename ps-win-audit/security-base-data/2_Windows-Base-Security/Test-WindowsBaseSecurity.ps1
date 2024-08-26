Function Test-WindowsBaseSecurity {
    <#
    .SYNOPSIS
    Short description
    
    .DESCRIPTION
    Long description
    
    .PARAMETER ComputerName
    NotMandatory - the name of the computer to check. If no value is provided, the local computer is checked by default.
    .PARAMETER Username
    NotMandatory - username required for remote computer access. If the operation is local, this parameter can be omitted.
    .PARAMETER Pass
    NotMandatory - password required for the provided username in a remote system. If the operation is local, this parameter can be omitted.
    .PARAMETER OutputFile
    NotMandatory - the file path where the result will be written. If provided, the result will be appended to this file.
    .PARAMETER AddToTrustedHosts
    NotMandatory - if set to $true, adds the remote computer to TrustedHosts temporarily.
    .PARAMETER RemoveFromTrustedHosts
    NotMandatory - if set to $true, removes the remote computer from TrustedHosts after completion.
    
    .EXAMPLE
    Test-WindowsBaseSecurity
    Test-WindowsBaseSecurity -ComputerName "fwvmhv" -Username "fwv" -Pass "1234"
    
    .NOTES
    Following checks for this audit context(SBD-009_022);
    - Get License status.
    - Get amount of active local users on system.
    - Get amount of users and groups in administrators group on system. (0 - 2: True; 3 - 5: Warning; 6 or higher: False)
    - Ensure the status of the Bitlocker service is 'Running'.
    - Ensure that Bitlocker is activated on all volumes.
    - Ensure the status of the Windows Defender service is 'Running'.
    - Ensure Windows Defender Application Guard is enabled.
    - Ensure the Windows Firewall is enabled on all profiles.
    - Check if the last successful search for updates was in the past 24 hours.
    - Check if the last successful installation of updates was in the past 5 days.
    - Ensure Virtualization Based Security is enabled and running.
    - Ensure Hypervisor-protected Code Integrity (HVCI) is running.
    - Ensure Credential Guard is running.
    - Ensure Attack Surface Reduction (ASR) rules are enabled.
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,
        
        [Parameter(Mandatory = $false)]
        [string]$Username = $null,
        
        [Parameter(Mandatory = $false)]
        [string]$Pass = $null,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFile = $null,

        [Parameter(Mandatory = $false)]
        [switch]$AddToTrustedHosts,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveFromTrustedHosts
    )
    try {
        $IsRemote = ($ComputerName -ne $env:COMPUTERNAME) -and ($Username -and $Pass)
        if ($IsRemote) {
            $PingResult = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
            if (-not $PingResult) {
                Write-Warning -Message "Unable to reach $ComputerName. Please check the connection or computer name."
                return
            }
        }
        ## Windows Base Security - SBD-009
        $CheckLicenseStatus = {
            enum LicenseStatus {
                Unlicensed = 0
                Licensed = 1
                Out_Of_Box_Grace_Period = 2
                Out_Of_Tolerance_Grace_Period = 3
                Non_Genuine_Grace_Period = 4
                Notification = 5
                Extended_Grace = 6
            }
            $ActivationStatus = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "Name like 'Windows%'" | Where-Object { $_.PartialProductKey } | Select-Object PSComputerName, @{N = 'LicenseStatus'; E = { [LicenseStatus]$_.LicenseStatus } }
            $WindowsVersion = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object Caption, Version
            $Report = [PSCustomObject]@{
                LicenseStatus = $ActivationStatus.LicenseStatus
                Version       = $WindowsVersion.Caption
                Build         = $WindowsVersion.Version
            }
            $IsLicensed = ($ActivationStatus.LicenseStatus -eq [LicenseStatus]::Licensed)
            $ComplianceReport = [PSCustomObject]@{
                LicenseStatus = $ActivationStatus.LicenseStatus
                Version       = $Report.Version
                Build         = $Report.Build
                IsLicensed    = $IsLicensed
            }
            if ($IsLicensed) {
                Write-Host "Result > Compliant: True"
            }
            else {
                Write-Host "Result > Not Compliant: False"
            }
            return $ComplianceReport
        }
        Invoke-Command -ScriptBlock $CheckLicenseStatus
        ## Windows Base Security - SBD-010 / ## SBD-011
        $AdministratorsGroup = Get-LocalGroupMember -Group "Administrators"
        $Users = $AdministratorsGroup | Where-Object { $_.ObjectClass -eq 'User' }
        $Groups = $AdministratorsGroup | Where-Object { $_.ObjectClass -eq 'Group' }
        Write-Host "Number of Users in Administrators group: $($Users.Count)"
        Write-Host "Number of Groups in Administrators group: $($Groups.Count)"
        Write-Host "------ Users under Administrators group ------"
        foreach ($User in $Users) {
            Write-Host "$($User.Name) is a User in Administrators group"
        }
        Write-Host "------ Groups under Administrators group ------"
        foreach ($Group in $Groups) {
            Write-Host "$($Group.Name) is a Group in Administrators group"
        }
        $TotalMembers = $Users.Count + $Groups.Count
        Write-Host "Total Members in Administrators group: $TotalMembers"
        if ($TotalMembers -ge 0 -and $TotalMembers -le 2) {
            Write-Host "Result: True"
        }
        elseif ($TotalMembers -ge 3 -and $TotalMembers -le 5) {
            Write-Host "Result: Warning"
        }
        else {
            Write-Host "Result: False"
        }
        ## Windows Base Security - SBD-012 / ## SBD-013
        $BitlockerService = Get-Service -Name 'BDESVC'
        $BitlockerStatus = $BitlockerService.Status
        if ($BitlockerStatus -eq 'Running') {
            Write-Host "BitLocker service is running."
        }
        else {
            Write-Host "BitLocker service is not running. Please start the service and run the script again."
            return
        }
        $Volumes = Get-BitLockerVolume
        $BitlockerActivated = $true
        foreach ($Volume in $Volumes) {
            if ($Volume.ProtectionStatus -ne 'On') {
                $BitlockerActivated = $false
                Write-Host "BitLocker is not activated on $($Volume.MountPoint)."
            }
        }
        if ($BitlockerActivated) {
            Write-Host "BitLocker is activated on all volumes."
        }
        else {
            Write-Host "BitLocker is not activated on all volumes."
        }
        ## Windows Base Security - SBD-014 / SBD-015
        $DefenderService = Get-Service -Name 'WinDefend'
        $DefenderStatus = $DefenderService.Status
        if ($DefenderStatus -eq 'Running') {
            Write-Host "Windows Defender service is running."
            $DefenderServiceRunning = $true
        }
        else {
            Write-Host "Windows Defender service is not running. Starting the service..."
            Start-Service -Name 'WinDefend'
            Write-Host "Windows Defender service has been started."
            $DefenderServiceRunning = $false
        }
        $ApplicationGuardStatus = Get-WindowsCapability -Online | Where-Object { $_.Name -like '*Windows-Defender-ApplicationGuard*' }
        if ($null -ne $ApplicationGuardStatus) {
            Write-Host "Windows Defender Application Guard is enabled."
            $ApplicationGuardEnabled = $true
        }
        else {
            Write-Host "Windows Defender Application Guard is not enabled."
            $ApplicationGuardEnabled = $false
        }
        if ($DefenderServiceRunning -and $ApplicationGuardEnabled) {
            Write-Host "Result: True"
        }
        else {
            Write-Host "Result: False"
        }
        ## Windows Base Security - SBD-016
        $FirewallStatus = Get-NetFirewallProfile | Select-Object Name, Enabled
        $AllProfilesEnabled = $true
        foreach ($Profile in $FirewallStatus) {
            if ($Profile.Enabled -ne 'True') {
                $AllProfilesEnabled = $false
                Write-Host "Windows Firewall is not enabled on $($Profile.Name) profile."
            }
        }
        if ($AllProfilesEnabled) {
            Write-Host "Windows Firewall is enabled on all profiles."
            Write-Host "Result: True"
        }
        else {
            Write-Host "Windows Firewall is not enabled on all profiles."
            Write-Host "Result: False"
        }
        ## Windows Base Security - SBD-017 / SBD-018
        $SearchEvent = Get-WindowsUpdateLog | Where-Object { $_.EventId -eq 19 } | Select-Object -First 1
        $LastSearch = $SearchEvent.Date
        $SearchDifference = New-TimeSpan -Start $LastSearch -End (Get-Date)
        $InstallEvent = Get-WindowsUpdateLog | Where-Object { $_.EventId -eq 20 } | Select-Object -First 1
        $LastInstall = $InstallEvent.Date
        if ($null -ne $LastInstall) {
            $InstallDifference = New-TimeSpan -Start $LastInstall -End (Get-Date)
            $CompliantInstall = $InstallDifference.TotalDays -lt 5
        }
        else {
            $CompliantInstall = $false
        }
        $CompliantSearch = $SearchDifference.TotalHours -lt 24
        if ($CompliantSearch) {
            Write-Host "Last successful search for updates within the past 24 hours: Compliant (True)"
        }
        else {
            Write-Host "Last successful search for updates was more than 24 hours ago: Not Compliant (False)"
        }
        if ($CompliantInstall) {
            Write-Host "Last successful installation of updates within the past 5 days: Compliant (True)"
        }
        else {
            Write-Host "Last successful installation of updates was more than 5 days ago or no installation event found: Not Compliant (False)"
        }
        ## Windows Base Security - SBD-019
        $VbsStatus = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard
        if ($VbsStatus.SecurityServicesRunning -and $VbsStatus.SecurityServicesConfigured) {
            Write-Host "Virtualization Based Security (VBS) is enabled and running: Compliant (True)"
        }
        else {
            Write-Host "Virtualization Based Security (VBS) is not fully enabled or running: Not Compliant (False)"
        }        
        ## Windows Base Security - SBD-020
        try {
            $HvciStatus = Get-CimInstance -Namespace root\Microsoft\Windows\CI -ClassName MSFT_MicrosoftCodeIntegrity_SIPolicy -ErrorAction Stop
            if ($HvciStatus.Enabled) {
                Write-Host "Hypervisor-protected Code Integrity (HVCI) is running: Compliant (True)"
            }
            else {
                Write-Host "Hypervisor-protected Code Integrity (HVCI) is not running: Not Compliant (False)"
            }
        }
        catch {
            Write-Host "Error: Unable to retrieve HVCI status. HVCI might not be supported or accessible on this system."
        }        
        ## Windows Base Security - SBD-021
        $CgStatus = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard
        if ($CgStatus.CredentialGuardEnabled) {
            Write-Host "Credential Guard is running: Compliant (True)"
        }
        else {
            Write-Host "Credential Guard is not running: Not Compliant (False)"
        }        
        ## Windows Base Security - SBD-022
        $AsrRules = Get-MpPreference
        if ($AsrRules.ASR_Enabled) {
            Write-Host "Attack Surface Reduction (ASR) rules are enabled: Compliant (True)"
        }
        else {
            Write-Host "Attack Surface Reduction (ASR) rules are not enabled: Not Compliant (False)"
        }
    }
    catch {
        Write-Warning -Message "An error occurred: $_"
    }
    finally {
        if ($isRemote -and $RemoveFromTrustedHosts) {
            try {
                $TrustedHosts = Get-Item WSMan:\localhost\Client\TrustedHosts
                $IsTrusted = $TrustedHosts -match $ComputerName
                if ($IsTrusted) {
                    Write-Host "Removing $ComputerName from TrustedHosts." -ForegroundColor Gray
                    Set-Item WSMan:\localhost\Client\TrustedHosts -Value ($TrustedHosts -replace ", $ComputerName", "") -Force
                }
            }
            catch {
                Write-Warning -Message "Failed to remove $ComputerName from TrustedHosts: $_"
            }
        }
    }
}
