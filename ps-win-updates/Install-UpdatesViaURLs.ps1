Function Install-UpdatesViaURLs {
    <#
    .SYNOPSIS
    Installs updates from specified URLs, in this example from Windows Update Catalog.

    .DESCRIPTION
    This function installs updates from a list of URLs, it downloads the updates, installs them quietly, and provides information about the installation progress.

    .PARAMETER UpdateUrls
    Array of URLs pointing to the updates that need to be installed.
    .PARAMETER DownloadPath
    Path where the updates will be downloaded. Defaults to the system's temporary directory.
    .PARAMETER Quiet
    Indicates whether the installation should be done quietly without displaying prompts or messages.
    .PARAMETER NoRestart
    Indicates whether a system restart should be suppressed after installing the updates.

    .EXAMPLE
    Install-UpdatesViaURLs -UpdateUrls "https://example.com/update1.msu", "https://example.com/update2.exe" -DownloadPath "C:\Temp" -Quiet -NoRestart

    .NOTES
    v0.3.7
    - Change UpdateUrls as needed
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [Alias("u")]
        [string[]]$UpdateUrls = @(
            "https://catalog.s.download.windowsupdate.com/your_update_link-1.msu",
            "https://catalog.s.download.windowsupdate.com/your_update_link-2.exe",
            "https://catalog.s.download.windowsupdate.com/your_update_link-3.msu",
            "https://catalog.s.download.windowsupdate.com/your_update_link-4.exe"
            # Add more update URLs as needed
        ),

        [Parameter(Mandatory = $false)]
        [Alias("d")]
        [string]$DownloadPath = $env:TEMP,

        [Parameter(Mandatory = $false)]
        [Alias("qt")]
        [switch]$Quiet,

        [Parameter(Mandatory = $false)]
        [Alias("nr")]
        [switch]$NoRestart
    )
    BEGIN {
        $TotalUpdates = $UpdateUrls.Count
        $UpdatesInstalled = 0
        Write-Host "Installing $TotalUpdates updates..." -ForegroundColor Cyan
    }
    PROCESS {
        foreach ($UpdateUrl in $UpdateUrls) {
            $UpdateFileName = [System.IO.Path]::GetFileName($UpdateUrl)
            $FullDownloadPath = Join-Path -Path $DownloadPath -ChildPath $UpdateFileName
            if (Test-Path -Path $FullDownloadPath) {
                Write-Host "$UpdateFileName is already downloaded. Skipping..." -ForegroundColor Gray
            }
            else {
                Write-Host "Downloading is starting $UpdateFileName..." -ForegroundColor Cyan
                try {
                    Invoke-WebRequest -Uri $UpdateUrl -OutFile $FullDownloadPath -ErrorAction Stop
                    Write-Host "Downloaded $UpdateFileName." -ForegroundColor Green
                }
                catch {
                    Write-Error -Message "Error downloading $UpdateFileName : $($_.Exception.Message)"
                    continue
                }
            }
            Write-Host "Installing $UpdateFileName..." -ForegroundColor Yellow
            $Arguments = "/quiet", "/norestart"
            if ($Quiet) { 
                $Arguments += "/quiet" 
            }
            if ($NoRestart) { 
                $Arguments += "/norestart" 
            }
            $Arguments += $FullDownloadPath
            $Result = Start-Process -FilePath "wusa.exe" -ArgumentList $Arguments -Wait -PassThru
            if ($Result.ExitCode -eq 0) {
                Write-Host "Update $UpdateFileName installed successfully." -ForegroundColor Green
                $UpdatesInstalled++
            }
            else {
                Write-Error -Message "Failed to install $UpdateFileName (Exit Code: $($Result.ExitCode))!"
            }
            Remove-Item -Path $FullDownloadPath -Force -Verbose
        }
    }
    END {
        Write-Host "Installed $UpdatesInstalled out of $TotalUpdates updates." -ForegroundColor Yellow
    }
}
