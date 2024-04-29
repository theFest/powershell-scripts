Function Invoke-SpeechSynthesizer {
    <#
    .SYNOPSIS
    Generates speech from text using the System.Speech.Synthesis module.

    .DESCRIPTION
    This function generates speech from text using the System.Speech.Synthesis module in PowerShell.
    It allows for various modes of operation including Once, ForLoop, and TimeLoop, each with its own behavior for speech synthesis. Additionally, it provides options for adjusting volume, rate, pitch, specifying the voice, language, and more.

    .PARAMETER Mode
    Mode of operation for speech synthesis, values are Once, ForLoop, and TimeLoop.
    .PARAMETER InputText
    Text to be synthesized into speech.
    .PARAMETER ReadFromFile
    Whether the input text should be read from a file. If this switch is used, the InputText parameter must specify the file path.
    .PARAMETER ReadFromWeb
    Indicates whether the input text should be read from a web URL.
    .PARAMETER Url
    URL from which to read the input text when using the ReadFromWeb switch.
    .PARAMETER Volume
    Volume of the synthesized speech (0-100).
    .PARAMETER Rate
    Rate of speech synthesis (-10 to 10).
    .PARAMETER Duration
    Duration (in seconds) for the TimeLoop mode.
    .PARAMETER Iterations
    Number of iterations for the ForLoop mode.
    .PARAMETER Interval
    Interval (in seconds) between each iteration in the ForLoop mode.
    .PARAMETER Voice
    Voice to be used for speech synthesis.
    .PARAMETER Language
    Language for speech synthesis.
    .PARAMETER Pitch
    Pitch of the synthesized speech.
    .PARAMETER Pause
    Pauses the speech synthesis if this switch is used.
    .PARAMETER Progress
    Displays progress information during speech synthesis.
    .PARAMETER Callback
    Callback function to be executed after speech synthesis completes.
    
    .EXAMPLE
    Invoke-SpeechSynthesizer -InputText "Hello, how are you?" -Mode ForLoop -Iterations 2
    Invoke-SpeechSynthesizer -Mode Once -ReadFromFile -InputText "$env:USERPROFILE\Desktop\SpeechFile.txt"

    .NOTES
    v0.1.6
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Once", "ForLoop", "TimeLoop")]
        [string]$Mode = "Once",

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$InputText,

        [Parameter(Mandatory = $false)]
        [switch]$ReadFromFile,

        [Parameter(Mandatory = $false)]
        [switch]$ReadFromWeb,

        [Parameter(Mandatory = $false)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [int]$Volume = 75,

        [Parameter(Mandatory = $false)]
        [ValidateRange(-10, 10)]
        [int]$Rate = 0,

        [Parameter(Mandatory = $false)]
        [int]$Duration = 30,

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 1,

        [Parameter(Mandatory = $false)]
        [int]$Interval = 1,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Microsoft David Desktop", "Microsoft Zira Desktop", "Microsoft Matej")]
        [string]$Voice = "Microsoft David Desktop",

        [Parameter(Mandatory = $false)]
        [string]$Language = "en-US",

        [Parameter(Mandatory = $false)]
        [int]$Pitch = 0,

        [Parameter(Mandatory = $false)]
        [switch]$Pause,

        [Parameter(Mandatory = $false)]
        [string]$OutputFile,

        [Parameter(Mandatory = $false)]
        [switch]$Progress,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Callback
    )
    BEGIN {
        $StartTime = Get-Date
        Add-Type -AssemblyName System.Speech
        $SpeechSynthesizer = New-Object -TypeName "System.Speech.Synthesis.SpeechSynthesizer"
        try {
            $SpeechSynthesizer.SelectVoice($Voice)
        }
        catch {
            Write-Warning -Message "Voice '$Voice' not available or installed. Using default voice"
        }
        $SpeechSynthesizer.Rate = $Rate
        $SpeechSynthesizer.Volume = $Volume
        $SpeechSynthesizer.SetOutputToDefaultAudioDevice()
        if ($ReadFromFile) {
            if (-not $InputText) {
                Write-Warning -Message "InputText parameter is required when using ReadFromFile switch"
                return
            }
            elseif (-not (Test-Path -Path $InputText)) {
                Write-Warning -Message "File '$InputText' does not exist."
                return
            }
            $InputText = Get-Content -Path $InputText -Raw
        }
        elseif ($ReadFromWeb) {
            $InputText = (Invoke-WebRequest -Uri $Url).Content
        }
    }
    PROCESS {
        $SpeakAction = {
            param ($Text)
            $SpeechSynthesizer.Speak($Text)
        }
        if ($Pause) {
            $SpeechSynthesizer.Pause()
        }
        switch ($Mode) {
            "Once" {
                Invoke-Command -ScriptBlock $SpeakAction -ArgumentList $InputText
            }
            "ForLoop" {
                $Iterations * ($Interval + 1)
                for ($i = 1; $i -le $Iterations; $i++) {
                    Invoke-Command -ScriptBlock $SpeakAction -ArgumentList $InputText
                    if ($Progress) {
                        Write-Progress -Activity "Speaking" -Status "Iteration $i/$Iterations" -PercentComplete (($i / $Iterations) * 100)
                    }
                    if ($i -lt $Iterations) {
                        Start-Sleep -Seconds $Interval
                    }
                }
            }
            "TimeLoop" {
                $EndTime = (Get-Date).AddSeconds($Duration)
                do {
                    Invoke-Command -ScriptBlock $SpeakAction -ArgumentList $InputText
                    if ($Progress) {
                        $TimeLeft = [math]::Round(($EndTime - (Get-Date)).TotalSeconds)
                        Write-Progress -Activity "Speaking" -Status "Time left: $TimeLeft seconds" -PercentComplete ((($EndTime - (Get-Date)).TotalSeconds / $Duration) * 100)
                    }
                    Start-Sleep -Seconds $Interval
                } until ((Get-Date) -gt $EndTime)
            }
            default {
                Write-Warning -Message "Invalid mode. Please use 'Once', 'ForLoop', or 'TimeLoop'!"
            }
        }
        if ($Pause) {
            $SpeechSynthesizer.Resume()
        }
        if ($Callback) {
            & $Callback
        }
    }
    END {
        $SpeechSynthesizer.Dispose()
        Write-Verbose -Message "Total speech duration: $((Get-Date).Subtract($StartTime).Duration())"
    }
}
