function Start-MediaPlayback {
    <#
    .SYNOPSIS
    Plays a specified media file.

    .DESCRIPTION
    This function plays a specified media file either synchronously or asynchronously depending on the provided parameters. It uses the System.Media.SoundPlayer class to load and play the sound file.

    .EXAMPLE
    Start-MediaPlayback -File "C:\Windows\WinSxS\amd64_microsoft-windows-shell-sounds_31bf3856ad364e35_10.0.19041.4474_none_8bc3e36c6aca02bc\Windows Background.wav" -Async

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Enter the path to the media file to be played")]
        [string]$File,
        
        [Parameter(Mandatory = $false, HelpMessage = "Specify this switch to play the media file asynchronously")]
        [switch]$Async
    )
    try {
        $Player = New-Object System.Media.SoundPlayer
        $Player.SoundLocation = $File
        $Player.Load()
        if ($Async.IsPresent) {
            $Player.Play()
        }
        else {
            $Player.PlaySync()
        }
    }
    catch {
        Write-Error -Message "An error occurred while trying to play the sound: $_"
    }
}
