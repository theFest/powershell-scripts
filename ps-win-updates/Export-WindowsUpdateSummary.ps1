Function Export-WindowsUpdateSummary {
    <#
    .SYNOPSIS
    Exports a summary of Windows Update installations to the console and optionally to a file.

    .DESCRIPTION
    This function retrieves and displays a summary of Windows Update installations. The summary includes information about the installation results.

    .PARAMETER OutputPath
    Path for the output file. If not provided, the default path is set to the user's desktop with the filename "windows_update.log."

    .EXAMPLE
    Export-WindowsUpdateSummary

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "$env:USERPROFILE\Desktop\windows_update.log"
    )
    BEGIN {
        $InstallSummary = Get-WindowsUpdateLog | Select-String "Installation Result"
    }
    PROCESS {
        if ($InstallSummary) {
            $OutputData = "Windows Update Installation Summary:`r`n"
            $OutputData += $InstallSummary | ForEach-Object {
                "  $_"
            }
            Write-Output -InputObject $OutputData
            $OutputData | Out-File -FilePath $OutputPath -Force
        }
        else {
            Write-Warning -Message "No installation summary found in the Windows Update log!"
        }
    }
    END {
        Clear-Host
        Write-Host "Summary saved to: $OutputPath" -ForegroundColor Cyan
    }
}
