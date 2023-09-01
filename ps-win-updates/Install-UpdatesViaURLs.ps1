Function Install-UpdatesViaURLs {
    <#
    .SYNOPSIS
    Installs Windows updates from specified URLs, in this example from Windows Update Catalog.

    .DESCRIPTION
    This function downloads and installs Windows updates from a list of update URLs, it checks if an update is already downloaded and skips it if so.
    After downloading, it uses the Windows Update Standalone Installer (wusa.exe) to install the updates silently. It tracks the number of updates installed and provides status messages.

    .EXAMPLE
    Install-UpdatesViaURLs

    .NOTES
    Version: 0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$UpdateUrls = @(
            "https://catalog.s.download.windowsupdate.com/your_update_link-1.msu",
            "https://catalog.s.download.windowsupdate.com/your_update_link-2.exe",
            "https://catalog.s.download.windowsupdate.com/your_update_link-3.msu",
            "https://catalog.s.download.windowsupdate.com/your_update_link-4.exe"
            # Add more update URLs as needed
        )
    )
    $TotalUpdates = $UpdateUrls.Count
    $UpdatesInstalled = 0
    Write-Host "Installing $TotalUpdates updates..." -ForegroundColor Cyan
    foreach ($UpdateUrl in $UpdateUrls) {
        $UpdateFileName = [System.IO.Path]::GetFileName($UpdateUrl)
        $DownloadPath = Join-Path -Path $env:TEMP -ChildPath $UpdateFileName

        if (Test-Path -Path $DownloadPath) {
            Write-Host "$UpdateFileName is already downloaded. Skipping..." -ForegroundColor Gray
        }
        else {
            Write-Host "Downloading is starting $UpdateFileName..." -ForegroundColor Cyan
            try {
                Invoke-WebRequest -Uri $UpdateUrl -OutFile $DownloadPath -ErrorAction Stop
                Write-Host "Downloaded $UpdateFileName." -ForegroundColor Green
            }
            catch {
                Write-Error "Error downloading $UpdateFileName : $($_.Exception.Message)"
                continue
            }
        }
        Write-Host "Installing $UpdateFileName..." -ForegroundColor Yellow
        $Result = Start-Process -FilePath "wusa.exe" -ArgumentList "/quiet /norestart $DownloadPath" -Wait -PassThru
        if ($Result.ExitCode -eq 0) {
            Write-Host "Update $UpdateFileName installed successfully." -ForegroundColor Green
            $UpdatesInstalled++
        }
        else {
            Write-Error "Failed to install $UpdateFileName (Exit Code: $($Result.ExitCode))."
        }
        Remove-Item -Path $DownloadPath -Force -Verbose
    }
    Write-Host "Installed $UpdatesInstalled out of $TotalUpdates updates." -ForegroundColor Yellow
}
