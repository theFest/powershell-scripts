Function Update-WindowsDefenderDefinitions {
    <#
    .SYNOPSIS
    Updates Windows Defender definitions and shows additional information.

    .DESCRIPTION
    This function updates Windows Defender definitions using the specified update source. It checks the status of Windows Defender service and then initiates the update process. After the update, it displays the status of various Windows Defender properties.

    .PARAMETER UpdateSource
    Specifies the update source for Windows Defender definitions, values are MicrosoftUpdateServer, InternalDefinitionUpdateServer, FileShares and MMPC. Default value is set to MicrosoftUpdateServer.

    .EXAMPLE
    Update-WindowsDefenderDefinitions -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("MicrosoftUpdateServer", "InternalDefinitionUpdateServer", "FileShares", "MMPC")]
        [string]$UpdateSource = "MicrosoftUpdateServer"
    )
    try {
        $DefenderService = Get-Service -Name WinDefend
        if ($DefenderService.Status -eq "Running") {
            Write-Verbose -Message "Defender definition update has started, please wait..."
            Update-MpSignature -UpdateSource $UpdateSource -ErrorAction Stop -Verbose
            $DefinitionUpdateStatus = (Get-MpComputerStatus)
            if (($DefinitionUpdateStatus).DefenderSignaturesOutOfDate -eq $false) {
                Write-Host "Windows Defender definitions updated successfully" -ForegroundColor Green
                Write-Host "NIS signature last updated: $($DefinitionUpdateStatus.AntispywareSignatureLastUpdated)" -ForegroundColor DarkGreen
                Write-Host "Antivirus signature last updated: $($DefinitionUpdateStatus.AntivirusSignatureLastUpdated)" -ForegroundColor DarkGreen
                Write-Host "Antispyware signature last updated: $($DefinitionUpdateStatus.AntispywareSignatureLastUpdated)" -ForegroundColor DarkGreen
            }
            else {
                Write-Error -Message "Failed to update Windows Defender definitions!"
            }
        }
        else {
            Write-Warning -Message "Windows Defender is not enabled. Cannot update definitions!"
        }
    }
    catch {
        Write-Error -Message "Error occurred while updating Windows Defender definitions: $_!"
    }
    finally {
        $PropertiesToDisplay = @(
            "AMServiceEnabled",
            "AntispywareEnabled",
            "AntivirusEnabled",
            "BehaviorMonitorEnabled",
            "IoavProtectionEnabled",
            "IsTamperProtected",
            "NISEnabled",
            "TDTStatus"
            "OnAccessProtectionEnabled",
            "RealTimeProtectionEnabled"
        )
        foreach ($Property in $PropertiesToDisplay) {
            Write-Host "${Property}: $($DefinitionUpdateStatus.$Property)" -ForegroundColor DarkCyan
        }
    }
    Write-Verbose -Message "Defender definition update operations completed"
}
