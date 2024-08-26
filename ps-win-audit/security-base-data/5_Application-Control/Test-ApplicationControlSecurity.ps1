Function Test-ApplicationControlSecurity {
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
    Test-ApplicationControlSecurity
    Test-ApplicationControlSecurity -ComputerName "fwvmhv" -Username "fwv" -Pass "1234"
    
    .NOTES
    Following checks for this audit context(SBD-072_073);
    - Ensure Windows Defender Application Control (WDAC) is available.
    - Ensure Windows Defender Application ID Service is running.
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
