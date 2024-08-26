Function Test-PlatformSecurity {
    <#
    .SYNOPSIS
    Checks the system configuration as part of Windows Audit. Base System Security > Platform Security.

    .DESCRIPTION
    This function checks various aspects of the system configuration, including UEFI mode, SecureBoot, TPM presence, readiness, enabled status, activation, ownership, and TPM version. It supports both local and remote systems.

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
    Test-PlatformSecurity
    Test-PlatformSecurity -ComputerName "RemoteComputer" -Username "Admin" -Pass "Password123" -OutputFile "$env:USERPROFILE\Desktop\Output.txt" -AddToTrustedHosts -RemoveFromTrustedHosts

    .NOTES
    Following checks for this audit context(SBD-001_008);
    - Ensure the system is booting in 'UEFI' mode.
    - Ensure the system is using SecureBoot.
    - Ensure the TPM Chip is 'present'.
    - Ensure the TPM Chip is 'ready'.
    - Ensure the TPM Chip is 'enabled'.
    - Ensure the TPM Chip is 'activated'.
    - Ensure the TPM Chip is 'owned'.
    - Ensure the TPM Chip is implementing specification version 2.0 or higher.
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
        Write-Verbose -Message "Checking if the computer is remote and credentials are provided"
        $IsRemote = ($ComputerName -ne $env:COMPUTERNAME) -and ($Username -and $Pass)
        if ($IsRemote) {
            Write-Verbose -Message "Pinging the remote computer to check connectivity"
            $PingResult = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
            if (-not $PingResult) {
                Write-Warning -Message "Unable to reach $ComputerName. Please check the connection or computer name."
                return
            }
        }
        if ($IsRemote -and $AddToTrustedHosts) {
            Write-Verbose -Message "Checking if the computer is in the TrustedHosts list"
            $TrustedHosts = Get-Item WSMan:\localhost\Client\TrustedHosts
            $IsTrusted = $TrustedHosts -match $ComputerName
            if (-not $IsTrusted) {
                Write-Host "Adding $ComputerName to TrustedHosts temporarily." -ForegroundColor Gray
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$($TrustedHosts), $ComputerName" -Force
            }
        }
        Write-Verbose -Message "Get boot configuration information"
        $ScriptBlock = {
            param (
                [string]$ComputerName,
                [string]$Username,
                [string]$Pass,
                [string]$OutputFile
            )
            $BootConfig = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem"
            $ResultMessages = @()
            if ($BootConfig.BootupState -eq 0) {
                $ResultMessages += "Booting in 'UEFI' mode"
            }
            else {
                $ResultMessages += "Not booting in 'UEFI' mode. Current boot mode: $($BootConfig.BootupState)"
            }
            $SecureBootStatus = $BootConfig.SecureBoot
            if ($SecureBootStatus) {
                $ResultMessages += "SecureBoot is enabled"
            }
            else {
                $ResultMessages += "SecureBoot is not enabled"
            }
            $TPMPresent = $BootConfig.TpmPresent
            $TPMReady = $BootConfig.TpmReady
            $TPMEnabled = $BootConfig.TpmEnabled
            $TPMActivated = $BootConfig.TpmActivated
            $TPMOwned = $BootConfig.TpmOwned
            if ($TPMPresent -and $TPMReady -and $TPMEnabled -and $TPMActivated -and $TPMOwned) {
                $ResultMessages += "TPM is present, ready, enabled, activated, and owned"
            }
            else {
                $ResultMessages += "TPM is not configured as expected"
            }
            $TPMVersion = $BootConfig.TpmSpecificationVersion
            if ($TPMVersion -ge '2.0') {
                $ResultMessages += "TPM version is 2.0 or higher"
            }
            else {
                $ResultMessages += "TPM version is lower than 2.0"
            }
            $ResultMessages
        }
        if ($ComputerName -eq $env:COMPUTERNAME) {
            $Result = & $ScriptBlock -ComputerName $ComputerName -OutputFile $OutputFile
        }
        else {
            $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePassword
            $Result = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock $ScriptBlock -ArgumentList $ComputerName, $Username, $Pass, $OutputFile
        }
        foreach ($Message in $Result) {
            if ($OutputFile) {
                Write-Output $Message | Out-File -FilePath $OutputFile -Append
            }
            else {
                Write-Host $Message -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Warning -Message "An error occurred: $_"
    }
    finally {
        if ($IsRemote -and $RemoveFromTrustedHosts -and -not $IsTrusted) {
            try {
                Write-Host "Removing $ComputerName from TrustedHosts." -ForegroundColor Gray
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value ($TrustedHosts -replace ", $ComputerName", "") -Force
            }
            catch {
                Write-Warning -Message "Failed to remove $ComputerName from TrustedHosts: $_"
            }
        }
    }
}
