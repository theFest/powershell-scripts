Function SpeechSynthesizer {
    <#
    .SYNOPSIS
    Simple function for text to speech.
    
    .DESCRIPTION
    TTS speaker that has ability to speak on both local and remote computer. 
    
    .PARAMETER Mode
    Mandatory - choose between speaking once, in 'for' or 'do while' loop.   
    .PARAMETER FilePath
    NotMandatory - load your local file that contains text content. 
    .PARAMETER HostEnteredText
    NotMandatory - add phrases by entering your text. 
    .PARAMETER WebPhrases
    NotMandatory - add phrases from web, use $url with this option. 
    .PARAMETER Computer
    NotMandatory - define hostname of remote computer, WinRM must be enabled. 
    .PARAMETER User
    NotMandatory - define username of remote computer. 
    .PARAMETER Password
    NotMandatory - define password of remote computer. 
    .PARAMETER Url
    NotMandatory - define url(modify line 111 for your url), use WebPhrases with it.
    .PARAMETER Volume
    NotMandatory - adjust volume of a speaker, default is already set to 3/4.
    .PARAMETER Rate
    NotMandatory - adjust rate of a speaker, default is already set as it should be.
    .PARAMETER Seconds
    NotMandatory - declare time for 'Do while' TimeLoop.
    .PARAMETER IterationsCount
    NotMandatory - declare number of iterations when using 'for' loop.
    .PARAMETER Interval
    NotMandatory - declare interval between iterations when using loops.
    .PARAMETER SelectVoice
    NotMandatory - choose voice of a speaker, additional language packs are needed for your region.
    
    .EXAMPLE
    SpeechSynthesizer -Mode Once -FilePath "$env:USERPROFILE\Desktop\SpeechFile.txt"
    SpeechSynthesizer -Mode ForLoop -WebPhrases -Url "your_website" -IterationsCount 10 -Interval 2
    SpeechSynthesizer -Mode TimeLoop -FilePath "$env:USERPROFILE\Desktop\SpeechFile.txt" -Seconds 60
    SpeechSynthesizer -Mode Once -Computer "remote_computer" -User "user_of_remote_computer" -Password "pass_of_remote_computer" -FilePath "$env:USERPROFILE\Desktop\SpeechFile.txt"
    
    .NOTES
    V1 
    *currently supporting en-US language ; Enables psremoting on destination computer
    *use alternative GUI app ("https://jztkft.dl.sourceforge.net/project/espeak/espeak/espeak-1.48/setup_espeak-1.48.04.exe")
    *for other languages, first install languange pack then if needed modify registry (https://winaero.com/unlock-extra-voices-windows-10/)
    *when using WebPhrases, you'll need to modify code because every web location is different. 
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('Once', 'ForLoop', 'TimeLoop')]
        [string]$Mode = 'Once',

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [switch]$HostEnteredText,

        [Parameter(Mandatory = $false)]
        [switch]$WebPhrases,

        [Parameter(Mandatory = $false)]
        [string]$Computer,

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Password,

        [Parameter(Mandatory = $false)]
        [string]$Url,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 100)]
        [int]$Volume = 75,

        [Parameter(Mandatory = $false)]
        [ValidateRange(-10, 10)]
        [int]$Rate = 0,

        [Parameter(Mandatory = $false)]
        [int]$Seconds = 30,

        [Parameter(Mandatory = $false)]
        [int]$IterationsCount = 2,

        [Parameter(Mandatory = $false)]
        [int]$Interval = 1,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Microsoft David Desktop', 'Microsoft Zira Desktop', 'Microsoft Matej')]
        [string]$SelectVoice = 'Microsoft David Desktop'
    )
    BEGIN {
        $StartTime = Get-Date
        Add-Type -AssemblyName System.Speech
        $SObject = New-Object -TypeName "System.Speech.Synthesis.SpeechSynthesizer"
        $SObject.Rate = $Rate
        $SObject.Volume = $Volume
        $SObject.SelectVoice($SelectVoice)   
        switch ($Phrases) {
            { $FilePath } { $SpeechPhrases = (Get-Content $FilePath) }
            { $HostEnteredText } { $SpeechPhrases = Read-Host 'Enter or paste text' }
            { $WebPhrases } { $SpeechPhrases = Invoke-WebRequest -Uri $Url ; $WP = ($WebPhrases.AllElements | Where-Object -Property tagname -EQ 'P').Innertext ; $WP }
            default { Write-Host "other speech method has been used" -ForegroundColor Yellow }
        }    
    }
    PROCESS {
        $Speech = {
            if (!$Computer) {
                $SObject.Speak($SpeechPhrases)               
            }   
            else {
                $Pass = ConvertTo-SecureString -AsPlainText $Password -Force
                $SecureCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Pass  
                if (!(Test-WSMan -ComputerName $Computer -Credential $SecureCredentials -Authentication Default -ErrorAction SilentlyContinue)) {
                    Write-Output "Enabling WINRM on remote computer..."
                    Invoke-WmiMethod -ComputerName $Computer -Credential $SecureCredentials -Namespace root\cimv2 -Class Win32_Process -Name Create -ArgumentList "winrm quickconfig -quiet" | Out-Null #-AsJob
                    Invoke-WmiMethod -ComputerName $Computer -Credential $SecureCredentials -Namespace root\cimv2 -Class Win32_Process -Name Create -ArgumentList "PowerShell -ExecutionPolicy Bypass -Command Enable-PSRemoting -Force -SkipNetworkProfileCheck" | Out-Null #-AsJob
                }
                $PSSession = New-PSSession -ComputerName $Computer -Credential $SecureCredentials
                Invoke-Command -Session $PSSession {
                    [Reflection.Assembly]::LoadWithPartialName('System.Speech') | Out-Null
                    $SObject = New-Object System.Speech.Synthesis.SpeechSynthesizer
                    $SObject.Speak($Using:SpeechPhrases)
                }
            }
        }
        switch ($Mode) {
            'Once' {
                Invoke-Command -ScriptBlock $Speech
            } 
            'ForLoop' {
                for ($Iterations = 0; $Iterations -lt $IterationsCount; $Iterations++) {
                    Invoke-Command -ScriptBlock $Speech
                    Start-Sleep -Seconds $Interval
                } 
            }
            'TimeLoop' {
                $TimeOut = New-TimeSpan -Seconds:$Seconds #-Minutes:$Minutes -Hours:$Hours -Days:$Days
                $EndTime = (Get-Date).Add($TimeOut)
                do {
                    Invoke-Command -ScriptBlock $Speech
                    Start-Sleep -Seconds $Interval
                } until ((Get-Date) -gt $EndTime)
            }
            default {
                "additional switch has not been defined"
            }              
        }
    }
    END {
        $SObject.Dispose()
        Write-Host "Total speech duration: $((Get-Date).Subtract($StartTime).Duration() -replace ".{4}$")" -ForegroundColor Cyan 
    }          
}