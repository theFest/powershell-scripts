function Install-WMFUpdate {
    <#
    .SYNOPSIS
    Installs the Windows Management Framework (WMF) 5.1 update if not already installed.

    .DESCRIPTION
    This function checks if the WMF 5.1 update (KB3191566) is installed on the system. If not, it downloads and installs the update. The script logs the process and can optionally restart the computer after installation if the -Restart switch is provided.

    .EXAMPLE
    Install-WMFUpdate -Restart

    .NOTES
    v0.8.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Restarts the computer after applying changes")]
        [Alias("r")]
        [switch]$Restart
    )
    BEGIN {
        Start-Transcript -Path "$env:TEMP\WMF_Transcript.txt"
        $WMF5 = Get-HotFix -Id KB3191566 -ErrorAction SilentlyContinue -Verbose
        Write-Host "PS update check has started..." -ForegroundColor Cyan
    }
    PROCESS {
        if (!$WMF5) {
            Write-Host "WMF KB3191566 is missing, installing..."
            New-Item -Path $env:TEMP -Name WMF -ItemType Directory -Force -Verbose
            $WMF_url = 'https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win7AndW2K8R2-KB3191566-x64.zip'
            Invoke-WebRequest -Uri $WMF_url -OutFile "$env:TEMP\WMF\Win7AndW2K8R2-KB3191566-x64.zip"
            Write-Verbose -Message "WMF KB3191566 is downloading..."
            Expand-Archive -Path "$env:TEMP\WMF\Win7AndW2K8R2-KB3191566-x64.zip" -DestinationPath "$env:TEMP\WMF" -Force -Verbose
            $KB_path = Test-Path -Path "$env:TEMP\WMF\Win7AndW2K8R2-KB3191566-x64.msu" -Verbose
            if ($KB_path) {
                Write-Host "WMF KB3191566 downloaded and extracted..." -ForegroundColor DarkCyan
                while ((Get-Service -Name wuauserv).StartType -ne "Manual") {
                    Set-Service -Name wuauserv -StartupType Manual -Verbose
                    try {
                        Write-Host "Installation of KB3191566 update has started!"
                        Start-Process -FilePath "$env:TEMP\WMF\Win7AndW2K8R2-KB3191566-x64.msu" -Verbose -ArgumentList '/quiet /norestart' -Wait -WindowStyle Hidden
                    }
                    catch {
                        Write-Host "Installation of KB3191566 update has failed!"
                        return $false 
                    }
                }
            }
            else {
                Write-Host "Error in download and/or extract of WMF files!" -ForegroundColor DarkRed
                return $false
            }
        }
        else {
            Write-Host "KB3191566 is already installed" -ForegroundColor Green
            return $true
        }
    }
    END {
        if (Get-HotFix -Id KB3191566 -ErrorAction SilentlyContinue -Verbose) {
            Write-Host "WMF PowerShell 5.1 has installed/present."
            return $true
        }
        else {
            Write-Host "WMF PowerShell 5.1 installation has failed!" -ForegroundColor Red
            return $false
        }
        Stop-Transcript
        Move-Item -Path "$env:TEMP\WMF_Transcript.txt" -Destination "$env:TEMP\WMF\WMF_Transcript.txt" -Verbose -Force
        if ($Restart) {
            Write-Host "Restarting computer..." -ForegroundColor Cyan
            Restart-Computer -Force
        }
    }
}
