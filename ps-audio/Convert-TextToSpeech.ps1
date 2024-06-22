function Convert-TextToSpeech {
    <#
    .SYNOPSIS
    Converts text to speech using the SAPI.SpVoice COM object.
    
    .DESCRIPTION
    Converts the specified text into audible speech using the Windows Speech API (SAPI). Allows customization of speech rate, volume, and voice selection.
    
    .EXAMPLE
    Convert-TextToSpeech -Sentence "playing sample TTS playback" -Rate -2 -Volume 80

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Enter the sentence to be spoken")]
        [string]$Sentence,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the speech rate. Range: -10 (slowest) to 10 (fastest), default is 0 (normal speed)")]
        [ValidateRange(-10, 10)]
        [int]$Rate = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the volume level. Range: 0 (silent) to 100 (loudest), default is 100")]
        [ValidateRange(0, 100)]
        [int]$Volume = 100,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the name of the voice to use, default is the first available voice")]
        [string]$VoiceName = $null
    )
    $Speak = New-Object -ComObject SAPI.SpVoice
    if ($null -eq $Speak) {
        Write-Error -Message "Failed to create SAPI.SpVoice COM object!"
        return
    }
    if ($VoiceName) {
        $Voice = $Speak.GetVoices() | Where-Object { $_.GetDescription() -like "*$VoiceName*" }
        if ($Voice.Count -gt 0) {
            $Speak.Voice = $Voice.Item(0)
        }
        else {
            Write-Warning -Message "Voice '$VoiceName' not found. Using default voice."
            $Speak.Voice = $Speak.GetVoices().Item(0)
        }
    }
    else {
        $Speak.Voice = $Speak.GetVoices().Item(0)
    }
    $Speak.Rate = $Rate
    $Speak.Volume = $Volume
    $Speak.Speak($Sentence)
}
