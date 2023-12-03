Function Disable-WindowsUpdate {
    <#
    .SYNOPSIS
    Disables Windows updates using a third-party tool, credits to Sordum.

    .DESCRIPTION
    This function downloads and runs a third-party tool to disable Windows updates.

    .PARAMETER UpdateOperation
    NotMandatory - update operation to perform, the available options are '/D', '/E', and '/D /P' (default). '/D' disables updates, '/E' enables updates, and '/D /P' disables updates permanently. Default is '/D /P'.
    .PARAMETER WudUrl
    NotMandatory - specifies the URL of the Windows Update Disabler tool to download.
    .PARAMETER RemoveWUB
    NotMandatory - whether to remove Windows Update Disable tool after disabling Windows Updates.
    .PARAMETER Restart
    NotMandatory - indicates whether to restart the computer after applying the update operation.

    .EXAMPLE
    Disable-WindowsUpdate -Verbose
    Disable-WindowsUpdate -UpdateOperation /E -Restart

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, HelpMessage = "'/D'-->disable | '/E'-->enable | '/D /P'-->disable&protect")]
        [ValidateSet("/D", "/E", "/D /P")]
        [string]$UpdateOperation = "/D /P",

        [Parameter(Mandatory = $false)]
        [uri]$WudUrl = "https://www.sordum.org/files/downloads.php?st-windows-update-blocker",

        [Parameter(Mandatory = $false)]
        [switch]$RemoveWUB,

        [Parameter(Mandatory = $false)]
        [switch]$Restart
    )
    try {
        New-Item -Path "$env:TEMP" -Name "WU_Disable" -ItemType Directory -Force | Out-Null
        if (!(Test-Path -Path "$env:TEMP\WU_Disable\Wub_v1.8.zip")) {
            Write-Host "Downloading Windows Update disabler..." -ForegroundColor Green
            Invoke-WebRequest -Uri $WudUrl -OutFile "$env:TEMP\WU_Disable\Wub_v1.8.zip" -UseBasicParsing -Verbose
        }
        Expand-Archive -Path "$env:TEMP\WU_Disable\Wub_v1.8.zip" -DestinationPath "$env:TEMP\WU_Disable" -Force -Verbose
        Clear-Host
        Write-Verbose -Message "Downloaded and expanded, starting Wub to disable updates..."
        Start-Process cmd -ArgumentList "/c $env:TEMP\WU_Disable\Wub\Wub_x64.exe $UpdateOperation" -WindowStyle Minimized -Wait
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        if (("wuauserv", "WaaSMedicSvc" | Get-Service).Status -eq "Stopped") {
            Write-Host "Windows Update services disabled" -ForegroundColor Cyan
        }
        else {
            Write-Host "Windows Update services enabled" -ForegroundColor Cyan
        }
    }
    if ($RemoveWUB) {
        Write-Warning -Message "Cleaning up, remove the temporary folder..."
        Remove-Item -Path "$env:TEMP\WU_Disable" -Force -Recurse -Verbose
    }
    if ($Restart) {
        Write-Warning -Message "Restarting computer..."
        Restart-Computer -Force
    }
}
