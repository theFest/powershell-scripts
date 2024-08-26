Function Test-PowerShellSecurity {
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
    Test-PowerShellSecurity
    Test-PowerShellSecurity -ComputerName "fwvmhv" -Username "fwv" -Pass "1234"
    
    .NOTES
    Following checks for this audit context(SBD-023_034);
    - Ensure PowerShell Version is set to version 5 or higher.
    - Ensure PowerShell Version 2 is uninstalled.
    - Ensure PowerShell is set to configured to use Constrained Language.
    - Ensure Execution policy is set to set to AllSigned / RemoteSigned.
    - Ensure PowerShell Commandline Audting is set to 'Enabled'.
    - Ensure PowerShell Module Logging is set to 'Enabled'.
    - Ensure PowerShell ScriptBlockLogging is set to 'Enabled'.
    - Ensure PowerShell ScriptBlockInvocationLogging is set to 'Enabled'.
    - Ensure PowerShell Transcripting is set to 'Enabled'.
    - Ensure PowerShell InvocationHeader is set to 'Enabled'.
    - Ensure PowerShell ProtectedEventLogging is set to set to 'Enabled'.
    - Ensure .NET Framework version supports PowerShell Version 2 is uninstalled.
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
        Write-Verbose -Message "Ensure PowerShell Version is set to version 5 or higher"
        $PsVersion = $PSVersionTable.PSVersion.Major
        if ($PsVersion -ge 5) {
            Write-Host "PowerShell Version is set to $PsVersion : Compliant (True)"
        }
        else {
            Write-Host "PowerShell Version is not set to version 5 or higher: Not Compliant (False)"
        }
        Write-Verbose -Message "Ensure PowerShell Version 2 is uninstalled"
        $Psv2Installed = Get-HotFix -Id KB968930 -ErrorAction SilentlyContinue
        if (-not $Psv2Installed) {
            Write-Host "PowerShell Version 2 is not installed: Compliant (True)"
        }
        else {
            Write-Host "PowerShell Version 2 is installed: Not Compliant (False)"
        }
        Write-Verbose -Message "Ensure PowerShell is configured to use Constrained Language"
        $LanguageMode = $ExecutionContext.SessionState.LanguageMode
        if ($LanguageMode -eq 'ConstrainedLanguage') {
            Write-Host "PowerShell is configured to use Constrained Language: Compliant (True)"
        }
        else {
            Write-Host "PowerShell is not configured to use Constrained Language: Not Compliant (False)"
        }
        Write-Verbose -Message "Ensure Execution policy is set to AllSigned / RemoteSigned"
        $ExecutionPolicy = Get-ExecutionPolicy
        $CompliantExecutionPolicy = ($ExecutionPolicy -eq 'AllSigned' -or $ExecutionPolicy -eq 'RemoteSigned')
        if ($CompliantExecutionPolicy) {
            Write-Host "Execution policy is set to AllSigned or RemoteSigned: Compliant (True)"
        }
        else {
            Write-Host "Execution policy is not set to AllSigned or RemoteSigned: Not Compliant (False)"
        }
        Write-Verbose -Message "Ensure PowerShell Auditing settings"
        $AuditingSettings = Get-WinEvent -LogName Security -MaxEvents 1 | Where-Object { $_.Id -eq 4104 }
        $CompliantAuditing = ($AuditingSettings -and $AuditingSettings.Properties[7].Value -eq 'Enabled')
        if ($CompliantAuditing) {
            Write-Host "PowerShell Auditing is set to 'Enabled': Compliant (True)"
        }
        else {
            Write-Host "PowerShell Auditing is not set to 'Enabled': Not Compliant (False)"
        }
        Write-Verbose -Message "Ensure PowerShell Module Logging is set to 'Enabled'"
        $ModuleLogging = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging' -ErrorAction SilentlyContinue
        $CompliantModuleLogging = ($ModuleLogging -and $ModuleLogging.EnableModuleLogging -eq 1)
        if ($CompliantModuleLogging) {
            Write-Host "PowerShell Module Logging is set to 'Enabled': Compliant (True)"
        }
        else {
            Write-Host "PowerShell Module Logging is not set to 'Enabled': Not Compliant (False)"
        }
        Write-Verbose -Message "Ensure PowerShell ScriptBlockLogging is set to 'Enabled'"
        $ScriptBlockLogging = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -ErrorAction SilentlyContinue
        $CompliantScriptBlockLogging = ($ScriptBlockLogging -and $ScriptBlockLogging.EnableScriptBlockLogging -eq 1)
        if ($CompliantScriptBlockLogging) {
            Write-Host "PowerShell ScriptBlockLogging is set to 'Enabled': Compliant (True)"
        }
        else {
            Write-Host "PowerShell ScriptBlockLogging is not set to 'Enabled': Not Compliant (False)"
        }
        Write-Verbose -Message "Ensure PowerShell ScriptBlockInvocationLogging is set to 'Enabled'"
        $ScriptBlockInvocationLogging = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockInvocationLogging' -ErrorAction SilentlyContinue
        $CompliantScriptBlockInvocationLogging = ($ScriptBlockInvocationLogging -and $ScriptBlockInvocationLogging.EnableScriptBlockInvocationLogging -eq 1)
        if ($CompliantScriptBlockInvocationLogging) {
            Write-Host "PowerShell ScriptBlockInvocationLogging is set to 'Enabled': Compliant (True)"
        }
        else {
            Write-Host "PowerShell ScriptBlockInvocationLogging is not set to 'Enabled': Not Compliant (False)"
        }
        Write-Verbose -Message "Ensure PowerShell Transcripting is set to 'Enabled'"
        $Transcripting = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' -ErrorAction SilentlyContinue
        $CompliantTranscripting = ($Transcripting -and $Transcripting.EnableTranscripting -eq 1)
        if ($CompliantTranscripting) {
            Write-Host "PowerShell Transcripting is set to 'Enabled': Compliant (True)"
        }
        else {
            Write-Host "PowerShell Transcripting is not set to 'Enabled': Not Compliant (False)"
        }
        Write-Verbose -Message "Ensure PowerShell InvocationHeader is set to 'Enabled'"
        $InvocationHeader = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -ErrorAction SilentlyContinue
        $CompliantInvocationHeader = ($InvocationHeader -and $InvocationHeader.EnableInvocationHeader -eq 1)
        if ($CompliantInvocationHeader) {
            Write-Host "PowerShell InvocationHeader is set to 'Enabled': Compliant (True)"
        }
        else {
            Write-Host "PowerShell InvocationHeader is not set to 'Enabled': Not Compliant (False)"
        }
        Write-Verbose -Message "Ensure PowerShell ProtectedEventLogging is set to 'Enabled'"
        $ProtectedEventLogging = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ProtectedEventLogging' -ErrorAction SilentlyContinue
        $CompliantProtectedEventLogging = ($ProtectedEventLogging -and $ProtectedEventLogging.Enabled -eq 1)
        if ($CompliantProtectedEventLogging) {
            Write-Host "PowerShell ProtectedEventLogging is set to 'Enabled': Compliant (True)"
        }
        else {
            Write-Host "PowerShell ProtectedEventLogging is not set to 'Enabled': Not Compliant (False)"
        }
        Write-Verbose -Message "Ensure .NET Framework version supports PowerShell Version 2 is uninstalled"
        $NetFrameworkVersion = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -Name Release -ErrorAction SilentlyContinue
        if ($NetFrameworkVersion -and $NetFrameworkVersion.Release -ge 394806) {
            Write-Host ".NET Framework version supports PowerShell Version 2 is uninstalled: Compliant (True)"
        }
        else {
            Write-Host ".NET Framework version supports PowerShell Version 2 is installed: Not Compliant (False)"
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
