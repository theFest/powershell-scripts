Function New-MessageBox {
    <#
    .SYNOPSIS
    Displays a customizable message box with optional text-to-speech functionality.

    .DESCRIPTION
    This function creates a message box with customizable message, buttons, icon, and title. It can also utilize text-to-speech functionality to vocalize the message.

    .PARAMETER Message
    Mandatory - message to be displayed in the message box. It must be a string between 1 and 800 characters.
    .PARAMETER Button
    NotMandatory - type of buttons in the message box, options include OkOnly, OkCancel, AbortRetryIgnore, YesNoCancel, YesNo, and RetryCancel.
    .PARAMETER Icon
    NotMandatory - icon to be displayed in the message box, options include Critical, Question, Exclamation, and Information.
    .PARAMETER Title
    NotMandatory - title of the message box, it must be a string between 1 and 60 characters.
    .PARAMETER PassThru
    NotMandatory - outputs the return value of the message box.
    .PARAMETER Voice
    NotMandatory - enables text-to-speech for the message.
    .PARAMETER VoiceGender
    NotMandatory - selects the voice gender for text-to-speech, options include Male and Female.

    .EXAMPLE
    New-MessageBox -Message "This is a message" -Button OkCancel -Icon Information -Title "Information" -PassThru

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipelinebyPropertyName = $true, HelpMessage = "Specify a display message or prompt for the message box")]
        [ValidateNotNullorEmpty()]
        [Alias("Prompt")]
        [ValidateLength(1, 800)]
        [string]$Message,
    
        [Parameter(Mandatory = $false, HelpMessage = "Specify the type of buttons in the message box")]
        [ValidateSet("OkOnly", "OkCancel", "AbortRetryIgnore", "YesNoCancel", "YesNo", "RetryCancel")]
        [string]$Button = "OkOnly",
    
        [Parameter(Mandatory = $false, HelpMessage = "Specify the icon to be displayed in the message box")]
        [ValidateSet("Critical", "Question", "Exclamation", "Information")]
        [string]$Icon = "Information",
    
        [Parameter(Mandatory = $false, HelpMessage = "Specify the title of the message box")]
        [ValidateLength(1, 60)]
        [string]$Title,
    
        [Parameter(Mandatory = $false, HelpMessage = "Output the return value of the message box")]
        [switch]$PassThru,
    
        [Parameter(Mandatory = $false, HelpMessage = "Enable text-to-speech for the message")]
        [Alias("Speak")]
        [switch]$Voice,
    
        [Parameter(Mandatory = $false, HelpMessage = "Select the voice gender for text-to-speech")]
        [ValidateSet("Male", "Female")]
        [Alias("Gender")]
        [string]$VoiceGender
    )
    BEGIN {
        try {
            Write-Verbose -Message "Loading VisualBasic assembly"
            Add-Type -AssemblyName "Microsoft.VisualBasic" -ErrorAction Stop     
            if ($Voice) {
                Write-Verbose -Message "Loading speech assembly"
                try {
                    Add-Type -Assembly System.Speech -ErrorAction Stop
                    $Synth = New-Object System.Speech.Synthesis.SpeechSynthesizer -ErrorAction Stop
                    if ($VoiceGender) {
                        Write-Verbose -Message "Selecting a $VoiceGender voice"
                        $Synth.SelectVoiceByHints($VoiceGender)
                    }
                    else {
                        Write-Verbose -Message "Using default voice"
                    }
                    $Synth.SpeakAsync($Message) | Out-Null
                }
                catch {
                    Write-Warning -Message "Failed to add System.Speech assembly or create the SpeechSynthesizer object"
                    throw $_.Exception.Message
                }
            }
        }
        catch {
            Write-Warning -Message "Failed to add Microsoft.VisualBasic assembly or create the messagebox"
            throw $_.Exception.Message
        }
    }
    PROCESS {
        try {
            $ReturnValue = [Microsoft.VisualBasic.Interaction]::Msgbox($Message, "$Button,$Icon", $Title)
        }
        catch {
            Write-Warning -Message "Failed to create the messagebox"
            throw $_.Exception.Message
        }
        if ($PassThru) {
            Write-Verbose -Message "Passing return value from message box"
            Write-Output -InputObject $ReturnValue
        }
    }
    END {
        if ($Voice) {
            try {
                $Synth.Dispose()
            }
            catch {
                Write-Warning -Message "Failed to dispose of SpeechSynthesizer object"
                throw $_.Exception.Message
            }
        }
    }
}
