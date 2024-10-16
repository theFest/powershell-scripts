function Uninstall-Update {
    <#
    .SYNOPSIS
    Uninstalls a specified Windows update locally or on a remote computer.

    .DESCRIPTION
    This function allows you to interactively choose and uninstall one or more Windows updates based on their title and KB number. It supports both local and remote uninstallation and provides detailed feedback for each operation, including reboot requirements.

    .EXAMPLE
    Uninstall-Update -Verbose
    Uninstall-Update -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.3.2
    #>
    [CmdletBinding(ConfirmImpact = "High")]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specifies the title or KB number of the update to uninstall")]
        [string]$UpdateTitle,

        [Parameter(Mandatory = $false, HelpMessage = "Name of the remote computer to uninstall updates from, defaults to the local computer")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Username for remote authentication")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for remote authentication")]
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "Allows selecting and uninstalling multiple updates")]
        [switch]$MultipleUpdates
    )
    BEGIN {
        Write-Host "Starting update uninstallation on $ComputerName..." -ForegroundColor Cyan
        if ($Pass) {
            $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
        }
        $Session = $null
        if ($ComputerName -ne $env:COMPUTERNAME) {
            try {
                $RemoteCredential = New-Object PSCredential ($User, $SecurePassword)
                $Session = New-PSSession -ComputerName $ComputerName -Credential $RemoteCredential
                Write-Host "Established session with $ComputerName." -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to establish a session with $ComputerName. Error: $_"
                return
            }
        }
        $ScriptBlock = {
            $updates = dism /online /get-packages | Select-String -Pattern "Package Identity" | Where-Object { $_ -match "KB" }
            $updates -replace ".*: ", "" | ForEach-Object {
                [PSCustomObject]@{
                    PackageIdentity = $_
                    KB              = ($_ -split " ")[0] -replace "KB", ""
                }
            }
        }
        if ($Session) {
            $InstalledUpdates = Invoke-Command -Session $Session -ScriptBlock $ScriptBlock
        }
        else {
            $InstalledUpdates = & $ScriptBlock
        }
        if ($InstalledUpdates.Count -eq 0) {
            Write-Host "No installed updates found on $ComputerName." -ForegroundColor DarkGreen
            return
        }
    }
    PROCESS {
        if (-not $UpdateTitle) {
            Write-Host "Available updates on $ComputerName :" -ForegroundColor DarkCyan
            for ($i = 0; $i -lt $InstalledUpdates.Count; $i++) {
                Write-Host "$($i + 1). $($InstalledUpdates[$i].PackageIdentity) (KB$($InstalledUpdates[$i].KB))"
            }
            if ($MultipleUpdates) {
                $Choices = Read-Host "Enter the numbers of updates to uninstall (comma-separated)"
                $UpdateIndexes = $Choices.Split(',') | ForEach-Object { $_.Trim() - 1 }
                $UpdateTitlesToUninstall = $UpdateIndexes | ForEach-Object { $InstalledUpdates[$_].PackageIdentity }
            }
            else {
                $Choice = Read-Host "Enter the number of the update to uninstall"
                if ($Choice -ge 1 -and $Choice -le $InstalledUpdates.Count) {
                    $UpdateTitle = $InstalledUpdates[$Choice - 1].PackageIdentity
                    $UpdateTitlesToUninstall = @($InstalledUpdates[$Choice - 1].PackageIdentity)
                }
                else {
                    Write-Host "Invalid choice. Exiting..." -ForegroundColor DarkRed
                    return
                }
            }
        }
        else {
            $UpdateTitlesToUninstall = $InstalledUpdates | Where-Object { $_.PackageIdentity -like "*$UpdateTitle*" -or $_.KB -eq $UpdateTitle } | ForEach-Object { $_.PackageIdentity }
            if ($UpdateTitlesToUninstall.Count -eq 0) {
                Write-Host "Update '$UpdateTitle' not found on $ComputerName."
                return
            }
        }
        foreach ($Update in $UpdateTitlesToUninstall) {
            $UninstallBlock = {
                param ($UpdateIdentity)
                $result = dism /online /remove-package /PackageName:$UpdateIdentity
                return $result
            }
            try {
                if ($Session) {
                    $UninstallResult = Invoke-Command -Session $Session -ScriptBlock $UninstallBlock -ArgumentList $Update
                }
                else {
                    $UninstallResult = & $UninstallBlock $Update
                }
                if ($UninstallResult -match "Successfully") {
                    Write-Host "Update '$Update' uninstalled successfully from $ComputerName." -ForegroundColor Green
                }
                else {
                    Write-Error "Failed to uninstall '$Update' from $ComputerName. Result: $UninstallResult"
                }
            }
            catch {
                Write-Error "Error uninstalling update '$Update'. Error: $($_.Exception.Message)"
            }
        }
    }
    END {
        if ($Session) {
            Remove-PSSession -Session $Session -Verbose
        }
        Write-Host "Update uninstallation completed on $ComputerName." -ForegroundColor Cyan
    }
}
