function Install-UpdatesViaURLs {
    <#
    .SYNOPSIS
    Installs updates from specified URLs, in this example from Windows Update Catalog.

    .DESCRIPTION
    This function installs updates from a list of URLs, downloads the updates, checks if they're already installed, and installs them if needed. It also provides installation progress information.

    .EXAMPLE
    Install-UpdatesViaURLs -UpdateUrls "https://example.com/update1.msu", "https://example.com/update2.exe" -DownloadPath "C:\Temp" -Quiet -NoRestart -Verbose

    .NOTES
    - Change UpdateUrls as needed
    v0.4.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Array of URLs pointing to the updates that need to be installed")]
        [Alias("u")]
        [string[]]$UpdateUrls = @(
            "https://catalog.s.download.windowsupdate.com/your_update_link-1.msu",
            "https://catalog.s.download.windowsupdate.com/your_update_link-2.exe",
            "https://catalog.s.download.windowsupdate.com/your_update_link-3.msu",
            "https://catalog.s.download.windowsupdate.com/your_update_link-4.exe"
        ),

        [Parameter(Mandatory = $false, HelpMessage = "Path where the updates will be downloaded, defaults to the system's temporary directory")]
        [Alias("d")]
        [string]$DownloadPath = $env:TEMP,

        [Parameter(Mandatory = $false, HelpMessage = "Installation should be done quietly without displaying prompts or messages")]
        [Alias("qt")]
        [switch]$Quiet,

        [Parameter(Mandatory = $false, HelpMessage = "System restart should be suppressed after installing the updates")]
        [Alias("nr")]
        [switch]$NoRestart
    )
    BEGIN {
        $TotalUpdates = $UpdateUrls.Count
        $UpdatesInstalled = 0
        $StartTime = Get-Date
        Write-Host "Installing $TotalUpdates updates..." -ForegroundColor Cyan
        $WusaExitCodes = @{
            0          = "The operation completed successfully.";
            1          = "No updates were installed (possibly already installed).";
            2          = "The system needs to be restarted to complete the installation.";
            3          = "The update could not be installed.";
            4          = "A higher version of the update is already installed.";
            5          = "The update is not applicable to your system.";
            6          = "Another update installation is in progress.";
            87         = "Invalid parameter.";
            2359302    = "The update package is damaged or missing required files.";
            2359303    = "The update was cancelled by the user.";
            2145124329 = "Access denied.";
            2145124330 = "Update not installed due to licensing restrictions.";
            2149842967 = "The update is already installed.";
            2145124327 = "File is corrupt or invalid.";
            3010       = "A restart is required to complete the installation.";
            1168       = "Element not found (likely update not applicable).";
            1612       = "Update file could not be found.";
            1613       = "The update cannot be installed in this configuration.";
            1619       = "The update package is open by another process.";
        }
    }
    PROCESS {
        foreach ($UpdateUrl in $UpdateUrls) {
            if ($UpdateUrl -match 'KB(\d+)') {
                $KbNumber = "KB$($matches[1])"
            }
            else {
                Write-Host "No KB number found in the update URL: $UpdateUrl. Skipping..." -ForegroundColor Gray
                continue
            }
            $IsUpdateInstalled = wmic qfe list brief | Select-String -Pattern $KbNumber
            if ($IsUpdateInstalled) {
                Write-Host "Update $KbNumber is already installed. Skipping..." -ForegroundColor Gray
                continue
            }
            $UpdateFullFileName = [System.IO.Path]::GetFileName($UpdateUrl)
            $FullDownloadPath = Join-Path -Path $DownloadPath -ChildPath $UpdateFullFileName
            if (Test-Path -Path $FullDownloadPath) {
                Write-Host "$UpdateFullFileName is already downloaded. Skipping download..." -ForegroundColor Gray
            }
            else {
                Write-Host "Downloading $UpdateFullFileName..." -ForegroundColor Cyan
                try {
                    Invoke-WebRequest -Uri $UpdateUrl -OutFile $FullDownloadPath -ErrorAction Stop
                    Write-Host "Downloaded $UpdateFullFileName." -ForegroundColor Green
                }
                catch {
                    Write-Error -Message "Error downloading $UpdateFullFileName : $($_.Exception.Message)"
                    continue
                }
            }
            Write-Host "Installing $UpdateFullFileName..." -ForegroundColor Yellow
            $Arguments = @("/quiet", "/norestart")
            if ($Quiet) { 
                $Arguments[0] = "/quiet"
            }
            if ($NoRestart) { 
                $Arguments[1] = "/norestart"
            }
            $Arguments += $FullDownloadPath
            try {
                $Result = Start-Process -FilePath "wusa.exe" -ArgumentList $Arguments -Wait -PassThru
                $ExitCode = $Result.ExitCode
                if ($ExitCode -eq 0) {
                    Write-Host "Update $UpdateFullFileName installed successfully." -ForegroundColor Green
                    $UpdatesInstalled++
                }
                else {
                    $ErrorDescription = $WusaExitCodes[$ExitCode] -or "Unknown error."
                    Write-Error -Message "Failed to install $UpdateFullFileName (Exit Code: $ExitCode - $ErrorDescription)!"
                }
            }
            catch {
                Write-Error -Message "Error installing $UpdateFullFileName : $($_.Exception.Message)"
            }
            Remove-Item -Path $FullDownloadPath -WhatIf -Verbose
        }
    }
    END {
        $EndTime = Get-Date
        $Duration = $EndTime - $StartTime
        Write-Host "Installation completed. $UpdatesInstalled out of $TotalUpdates updates installed." -ForegroundColor Green
        Write-Verbose -Message "Total duration: $($Duration.ToString('hh\:mm\:ss'))"
        if ($UpdatesInstalled -gt 0 -and -not $NoRestart) {
            Write-Host "System restart is recommended to complete the update process." -ForegroundColor DarkCyan
        }
    }
}
