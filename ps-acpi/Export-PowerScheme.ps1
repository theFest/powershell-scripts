Function Export-PowerScheme {
    <#
    .SYNOPSIS
    Exports a selected Power Scheme to a specified file path.

    .DESCRIPTION
    This function exports a selected Power Scheme to a specified file path using the powercfg utility.

    .PARAMETER OutputPath
    Specifies the path where the Power Scheme will be exported. This parameter is mandatory.

    .EXAMPLE
    Export-PowerScheme -OutputPath "$env:USERPROFILE\Desktop\PowerScheme.pow"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    BEGIN {
        Write-Host "Getting Power Schemes..." -ForegroundColor Cyan
        $PowerSchemes = Get-CimInstance -Namespace root/cimv2/power -ClassName Win32_PowerPlan
        if ($null -eq $PowerSchemes) {
            Write-Warning -Message "No power schemes found!"
            return
        }
    }
    PROCESS {
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
        $SelectedNumber = Read-Host "Enter the number of the Power Scheme you want to export"
        $SelectedPowerScheme = $NumberedSchemes | Where-Object { $_.Number -eq $SelectedNumber }
        if (-not $SelectedPowerScheme) {
            Write-Host "Invalid selection. Export operation canceled!" -ForegroundColor DarkYellow
            return
        }
        try {
            Write-Host "Exporting Power Scheme..." -ForegroundColor DarkCyan
            $ArgumentList = @("/c", "powercfg /export ""$OutputPath"" $($SelectedPowerScheme.Guid)")
            Start-Process -FilePath "cmd.exe" -ArgumentList $argumentList -Wait -PassThru
            if (Test-Path -Path $OutputPath) {
                Write-Host "Power scheme exported successfully to $OutputPath" -ForegroundColor Green
            }
            else {
                throw "Power scheme export failed. File not found!"
            }
        }
        catch {
            Write-Error -Message "Error exporting power scheme: $_"
        }
    }
    END {
        Write-Host "Export-PowerScheme completed" -ForegroundColor Cyan
    }
}
