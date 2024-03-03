Function Reset-WindowsUpdateComponents {
    <#
    .SYNOPSIS
    Resets Windows Update components with optional actions.

    .DESCRIPTION
    This function resets Windows Update components with the ability to stop services, remove SoftwareDistribution folder, remove INetCache, start services, or a combination of these actions.
    
    .PARAMETER StopServices
    Stop the Windows Update related services.
    .PARAMETER RemoveSoftwareDistribution
    Remove the SoftwareDistribution folder.
    .PARAMETER RemoveInetCache
    Remove the INetCache folder.
    .PARAMETER StartServices
    Start the Windows Update related services.

    .EXAMPLE
    Reset-WindowsUpdateComponents -StopServices -RemoveSoftwareDistribution -RemoveInetCache -StartServices

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$StopServices,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveSoftwareDistribution,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveInetCache,

        [Parameter(Mandatory = $false)]
        [switch]$StartServices
    )
    if ($StopServices) {
        Stop-Service -Name wuauserv, cryptSvc, bits, msiserver
    }
    if ($RemoveSoftwareDistribution) {
        Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\*" -Force -Recurse -Verbose
    }
    if ($RemoveInetCache) {
        Remove-Item -Path "$env:SystemRoot\System32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache\*" -Force -Recurse -Verbose
    }
    if ($StartServices) {
        Start-Service -Name wuauserv, cryptSvc, bits, msiserver
    }
    if ($StopServices -or $RemoveSoftwareDistribution -or $RemoveInetCache -or $StartServices) {
        Write-Host "Windows Update components reset" -ForegroundColor DarkGreen
    }
}
