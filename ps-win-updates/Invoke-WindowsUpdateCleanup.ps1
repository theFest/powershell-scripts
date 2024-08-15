function Invoke-WindowsUpdateCleanup {
    <#
    .SYNOPSIS
    Performs a Windows Update cleanup using the Deployment Imaging Service and Management Tool (DISM).

    .DESCRIPTION
    This unction performs cleanup of Windows Update components on the local or a remote machine. It supports multiple options including component cleanup, base reset, and cleaning up superseded service pack packages.

    .EXAMPLE
    Invoke-WindowsUpdateCleanup -StartComponentCleanup
    Invoke-WindowsUpdateCleanup -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -SPSuperseded

    .NOTES
    v0.4.0
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Performs a component cleanup on the running operating system, can free up space by removing previous versions of components that are no longer needed")]
        [switch]$StartComponentCleanup,

        [Parameter(Mandatory = $false, HelpMessage = "Resets the base of all packages to the current versions of the packages, all previous versions of components are removed, making it impossible to uninstall updates")]
        [switch]$ResetBase,

        [Parameter(Mandatory = $false, HelpMessage = "Cleans up superseded service pack packages, can help in reducing the disk space used by the operating system")]
        [switch]$SPSuperseded,

        [Parameter(Mandatory = $false, HelpMessage = "Hostname of the remote computer on which the Windows Update cleanup should be performed. If not specified, the cleanup is performed on the local machine")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, HelpMessage = "Username for the remote connection, required when the `ComputerName` is specified")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for the remote connection, required when the `ComputerName` is specified")]
        [string]$Pass
    )
    $IsRebootPending = {
        $RebootPending = $false
        $PendingFile = "$env:windir\WinSxS\pending.xml"
        $RebootKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootInProgress",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\PackagesPending",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\PendingFileRenameOperations",
            "HKLM:\SOFTWARE\Microsoft\Updates\UpdateExeVolatile"
        )
        foreach ($Key in $RebootKeys) {
            if (Test-Path -Path $Key) {
                $RebootPending = $true
                break
            }
        }
        if (Test-Path -Path $pendingFile) {
            $RebootPending = $true
        }
        return $RebootPending
    }
    if (& $isRebootPending) {
        Write-Warning -Message "A reboot is pending. Please restart the system and try again!"
        return
    }
    $DismArgs = @("/Cleanup-Image")
    if ($StartComponentCleanup) { $DismArgs += "/StartComponentCleanup" }
    if ($ResetBase) { $DismArgs += "/ResetBase" }
    if ($SPSuperseded) { $DismArgs += "/SPSuperseded" }
    $LogPath = "$env:windir\Logs\DISM\dism.log"
    $DismArgs += "/LogPath:$LogPath"
    $DismArgs += "/LogLevel:3"
    $ExecuteDismCommand = {
        param (
            [string[]]$DismArgs,
            [string]$LogPath
        )
        $DismCommand = "dism.exe /online $($DismArgs -join ' ')"
        Write-Verbose -Message "Executing command: $DismCommand"
        $process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c $DismCommand" -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            Write-Host "Windows Update cleanup completed successfully." -ForegroundColor Green
        }
        else {
            throw "DISM failed with exit code $($process.ExitCode). See log at $LogPath for details!"
        }
    }
    if ($ComputerName) {
        if ($PSCmdlet.ShouldProcess($ComputerName, "Run Windows Update Cleanup")) {
            $Credential = New-Object System.Management.Automation.PSCredential ($User, (ConvertTo-SecureString $Pass -AsPlainText -Force))
            $SessionOptions = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -SessionOption $SessionOptions
            try {
                Invoke-Command -Session $Session -ScriptBlock $ExecuteDismCommand -ArgumentList ($DismArgs, $LogPath)
            }
            finally {
                Remove-PSSession -Session $Session -Verbose
            }
        }
    }
    else {
        if ($PSCmdlet.ShouldProcess("localhost", "Run Windows Update Cleanup")) {
            & $ExecuteDismCommand -DismArgs $DismArgs -LogPath $LogPath
        }
    }
}
