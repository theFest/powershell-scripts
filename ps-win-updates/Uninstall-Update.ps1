Function Uninstall-Update {
    <#
    .SYNOPSIS
    Uninstalls a specified Windows update.

    .DESCRIPTION
    This function allows you to interactively choose and uninstall a Windows update, provides a list of currently installed updates and prompts you to select the update to uninstall.

    .PARAMETER UpdateTitle
    Specifies the title of the update to be uninstalled. If not provided, the function displays a list of installed updates, and you can choose the update to uninstall interactively.

    .EXAMPLE
    Uninstall-Update

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$UpdateTitle
    )
    BEGIN {
        $UpdateSession = New-Object -ComObject Microsoft.Update.Session
        $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
        $SearchResult = $UpdateSearcher.Search("IsInstalled=1")
        $UpdateTitles = $SearchResult.Updates | ForEach-Object { $_.Title }
        if ($UpdateTitles.Count -eq 0) {
            Write-Host "No updates found" -ForegroundColor DarkGreen
            return
        }
        Write-Host "Choose an update to uninstall:" -ForegroundColor DarkCyan
        for ($i = 0; $i -lt $UpdateTitles.Count; $i++) {
            Write-Host "$($i + 1). $($UpdateTitles[$i])"
        }
        if (-not $UpdateTitle) {
            $Choice = Read-Host "Enter the number of the update to uninstall"
            if ($Choice -ge 1 -and $Choice -le $UpdateTitles.Count) {
                $UpdateTitle = $UpdateTitles[$Choice - 1]
            }
            else {
                Write-Host "Invalid choice. Please enter a valid number!" -ForegroundColor DarkRed
                return
            }
        }
    }
    PROCESS {
        $UpdateToUninstall = $SearchResult.Updates | Where-Object { $_.Title -eq $UpdateTitle }
        if ($null -eq $UpdateToUninstall) {
            Write-Host "Update '$UpdateTitle' not found."
        }
        elseif ($UpdateToUninstall.IsInstalled -and $UpdateToUninstall.EulaAccepted) {
            $UpdateInstaller = $UpdateSession.CreateUpdateInstaller()
            $UpdateInstaller.Updates = New-Object -ComObject Microsoft.Update.UpdateColl
            $UpdateInstaller.Updates.Add($UpdateToUninstall)
            try {
                $UninstallResult = $UpdateInstaller.Uninstall()
                if ($UninstallResult.ResultCode -eq 2) {
                    Write-Host "Update '$UpdateTitle' uninstalled successfully" -ForegroundColor Green
                }
                else {
                    Write-Error -Message "Failed to uninstall update. Result code: $($UninstallResult.ResultCode)"
                }
            }
            catch [System.Runtime.InteropServices.COMException] {
                if ($_.Exception.HResult -eq 0x80240028) {
                    Write-Host "Failed to uninstall update. The update may not be applicable for uninstallation" -ForegroundColor DarkYellow
                }
                else {
                    Write-Error -Message "Failed to uninstall update. Error: $($_.Exception.Message)"
                }
            }
        }
        else {
            Write-Warning -Message "Update '$UpdateTitle' is not installed or EULA not accepted!"
        }
    }
    END {
        if ($UpdateSession) {
            [System.Runtime.InteropServices.Marshal]::ReleaseComObject($UpdateSession) | Out-Null
        }
    }
}
