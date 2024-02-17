Function Remove-PowerScheme {
    <#
    .SYNOPSIS
    This cmdlet removes a specified power scheme or allows you to choose from available power schemes and then removes the selected one.

    .DESCRIPTION
    This function removes a power scheme either by directly specifying the SchemeGuid or by interactively choosing from the available power schemes. If the `-ListAvailable` switch is used, it lists the available power schemes, and you can select the one you want to remove. If the `-SchemeGuid` parameter is provided, it directly removes the power scheme with the specified GUID.

    .PARAMETER ListAvailable
    If this switch is used, the cmdlet lists the available power schemes, and the user can interactively select one for removal.

    .PARAMETER SchemeGuid
    Specifies the GUID of the power scheme to be removed. If this parameter is provided, the cmdlet directly removes the power scheme with the specified GUID.

    .EXAMPLE
    Remove-PowerScheme -ListAvailable
    Remove-PowerScheme -SchemeGuid "41046e40-791b-412c-ad5e-e30076c5edbb"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$ListAvailable,

        [Parameter(Mandatory = $false)]
        [string]$SchemeGuid
    )
    BEGIN {
        Write-Host "Removing Power Scheme..." -ForegroundColor Cyan
        if ($ListAvailable) {
            Write-Host "Getting Power Schemes..." -ForegroundColor Cyan
            $PowerSchemes = Get-CimInstance -Namespace root/cimv2/power -ClassName Win32_PowerPlan
            if ($null -eq $PowerSchemes) {
                Write-Warning -Message "No power schemes found!"
                return
            }
            Write-Host "Available Power Schemes:" -ForegroundColor Cyan
            $NumberedSchemes = $null
            $NumberedSchemes = $PowerSchemes | ForEach-Object -Process {
                [PSCustomObject]@{
                    Number      = $script:i++
                    Guid        = $_.InstanceID -replace '.*\{(.+?)\}.*', '$1'
                    SchemeName  = $_.ElementName
                    Description = $_.Description
                    IsActive    = $_.IsActive
                }
            }
            $NumberedSchemes | Format-Table -AutoSize
            $SelectedNumber = Read-Host "Enter the number of the Power Scheme you want to remove"
            $SelectedPowerScheme = $NumberedSchemes | Where-Object { $_.Number -eq $SelectedNumber }
            if (-not $SelectedPowerScheme) {
                Write-Host "Invalid selection. Removal operation canceled!"
                return
            }
            $SchemeGuid = $SelectedPowerScheme.Guid
        }
    }
    PROCESS {
        try {
            $ArgumentList = @("/c", "powercfg /delete $SchemeGuid")
            Start-Process -FilePath "cmd.exe" -ArgumentList $ArgumentList -Wait -PassThru
            Write-Host "PROCESS: Power scheme with GUID $SchemeGuid deleted successfully" -ForegroundColor Green
        }
        catch {
            Write-Error -Message "Error deleting power scheme: $_"
        }
    }
    END {
        Write-Host "Completed" -ForegroundColor Cyan
    }
}
