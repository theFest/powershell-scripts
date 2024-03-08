Function Invoke-WindowsUpdateCleanup {
    <#
    .SYNOPSIS
    Performs Windows Update cleanup using DISM commands.

    .DESCRIPTION
    This function initiates Windows Update cleanup using DISM commands, provides options to perform various cleanup tasks, such as starting component cleanup, resetting the base image, and superseding service packs.

    .PARAMETER StartComponentCleanup
    Specifies whether to start component cleanup, this option deletes the updated components immediately.
    .PARAMETER ResetBase
    Specifies whether to delete all superseded versions of every component, be aware that all existing service packs and updates cannot be uninstalled after this command is completed.
    .PARAMETER SPSuperseded
    Whether to remove all backup components needed to uninstall a service pack, after using this command, you cannot remove the service pack anymore.

    .EXAMPLE
    Invoke-WindowsUpdateCleanup -StartComponentCleanup

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$StartComponentCleanup,

        [Parameter(Mandatory = $false)]
        [switch]$ResetBase,

        [Parameter(Mandatory = $false)]
        [switch]$SPSuperseded
    )
    try {
        Write-Verbose -Message "Initiating Windows Update cleanup..."
        $DismArgs = @("/online", "/Cleanup-Image")
        if ($StartComponentCleanup) {
            $DismArgs += "/StartComponentCleanup"
        }
        if ($ResetBase) {
            $DismArgs += "/ResetBase"
        }
        if ($SPSuperseded) {
            $DismArgs += "/SPSuperseded"
        }
        $CmdArguments = "cmd /c dism.exe $($DismArgs -join ' ')"
        $Result = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $CmdArguments" -PassThru -Wait
        if ($Result.ExitCode -eq 0) {
            Write-Host "Windows Update cleanup completed" -ForegroundColor Green
        }
        else {
            throw "Error: Windows Update cleanup failed with exit code $($Result.ExitCode)!"
        }
    }
    catch {
        Write-Error -Message "Error: $_"
    }
}
