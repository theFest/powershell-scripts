Function Watch-DirectoryChanges {
    <#
    .SYNOPSIS
    Watches for changes in the specified directory and logs them to a file.

    .DESCRIPTION
    This function sets up a file system watcher to monitor changes in the specified directory and its subdirectories. It logs events such as file creation, modification, deletion, and renaming to a specified log file.

    .PARAMETER Path
    Specifies the path of the directory to monitor.
    .PARAMETER Filter
    File filter pattern to monitor within the directory.
    .PARAMETER IncludeSubdirectories
    Indicates whether to include subdirectories in the monitoring process. By default, subdirectories are included.
    .PARAMETER LogFilePath
    Specifies the path to the log file where the monitoring events are recorded.

    .EXAMPLE
    Watch-DirectoryChanges -Path "$env:SystemDrive\Logs" -Filter "*" -IncludeSubdirectories $true -LogFilePath "$env:SystemDrive\Temp\FileWatcherLog.log"

    .NOTES
    -This script can only be run in the console environment. Press Ctrl-C to stop monitoring.
    v0.0.1
    #>
    [CmdletBinding(ConfirmImpact = "None")]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $false)]
        [bool]$IncludeSubdirectories,

        [Parameter(Mandatory = $false)]
        [string]$LogFilePath
    )
    if ($Host.Name -ne "ConsoleHost") {
        Write-Warning -Message "This script can only be run in the console environment!"
        exit
    }
    try {
        [console]::TreatControlCAsInput = $true
    }
    catch {
        Write-Warning -Message "Unable to set TreatControlCAsInput, Ctrl-C might not work as expected!"
    }
    $FileWatcher = New-Object System.IO.FileSystemWatcher
    $FileWatcher.Path = $Path
    $FileWatcher.Filter = $Filter
    $FileWatcher.IncludeSubdirectories = $IncludeSubdirectories
    $FileWatcher.EnableRaisingEvents = $true
    $WriteAction = {
        param($FullPath, $ChangeType)
        $LogLine = "$(Get-Date), $ChangeType, $FullPath"
        Add-content $LogFilePath -Value $LogLine
        Write-Host $LogLine
    }
    Register-ObjectEvent $FileWatcher "Created" -Action {
        Write-Host "Created: $($Event.SourceEventArgs.FullPath)" | Out-Null
        $script:WriteAction.Invoke($Event.SourceEventArgs.FullPath, "Created")
    } > $null
    Register-ObjectEvent $FileWatcher "Changed" -Action {
        Write-Host "Changed: $($Event.SourceEventArgs.FullPath)" | Out-Null
        $script:WriteAction.Invoke($Event.SourceEventArgs.FullPath, "Changed")
    } > $null
    Register-ObjectEvent $FileWatcher "Deleted" -Action {
        Write-Host "Deleted: $($Event.SourceEventArgs.FullPath)" | Out-Null
        $script:WriteAction.Invoke($Event.SourceEventArgs.FullPath, "Deleted")
    } > $null
    Register-ObjectEvent $FileWatcher "Renamed" -Action {
        Write-Host "Renamed: $($Event.SourceEventArgs.FullPath)" | Out-Null
        $script:WriteAction.Invoke($Event.SourceEventArgs.FullPath, "Renamed")
    } > $null
    Write-Host "Monitoring has started: $Path\$Filter"
    Write-Host "(press Ctrl-C to stop)"
    while ($true) {
        Start-Sleep -Seconds 1
        if ($Host.UI.RawUI.KeyAvailable -and (3 -eq [int]$Host.UI.RawUI.ReadKey("AllowCtrlC,IncludeKeyUp,NoEcho").Character)) {
            Get-EventSubscriber -Force | Unregister-Event -Force
            Write-Host "`n"
            Write-Host "Monitoring ended" -BackgroundColor DarkRed
            break
        }
    }
}
