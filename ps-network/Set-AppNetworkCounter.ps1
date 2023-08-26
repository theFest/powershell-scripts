Function Set-AppNetworkCounter {
    <#
    .SYNOPSIS
    Monitors network usage of applications using AppNetworkCounter. Credits to Nirsoft for creating this tool.

    .DESCRIPTION
    This function is used to monitor network usage of applications using the AppNetworkCounter utility.
    It downloads the utility, captures network usage data, and provides options to save the output in various formats.
    The function allows customization through parameters such as capture time, output file format, sorting column, and more.

    .PARAMETER CaptureTime
    Mandatory - specifies the duration for which network usage data should be captured.
    .PARAMETER CaptureUnit
    Mandatory - specifies the time unit for the capture time. Available options: "seconds", "minutes", "hours".
    .PARAMETER SaveOutput
    Mandatory - format in which the captured data should be saved. Available options include "/sjson", "/scomma", "/shtml", "/sverhtml", "/sxml", "/stab", and "/stext".
    .PARAMETER SortColumn
    NotMandatory - column by which the captured data should be sorted. Available options for sorting include "Application Name", "Application Path", "Received Bytes", and "Sent Bytes".
    .PARAMETER DownloadPath
    NotMandatory - local path where the AppNetworkCounter utility archive should be downloaded. The default path is the user's desktop.
    .PARAMETER OutputFilePath
    NotMandatory - the path where the captured network usage data should be saved. The default path is the user's desktop.
    .PARAMETER AppNetCounterUrl
    NotMandatory - URL from which the AppNetworkCounter utility should be downloaded.
    .PARAMETER ConfigFile
    NotMandatory - a configuration file to customize the behavior of the AppNetworkCounter utility.
    .PARAMETER TranslateLanguage
    NotMandatory - language for translating the user interface. Available options: "ar", "pt-br", "nl", "fr", "de", "el", "hu", "it", "fa", "pl", "ro", "ru", "sk", "tr", "cs", "sv", "th", "es", "zh", "ja".
    .PARAMETER WaitProcess
    NotMandatory - use this switch to wait (in session) for the process to end or release.
    .PARAMETER AsJob
    NotMandatory - use this switch to run as a background job.

    .EXAMPLE
    Set-AppNetworkCounter -CaptureTime 10 -CaptureUnit Seconds -SaveOutput /scomma
    Set-AppNetworkCounter -CaptureTime 10 -CaptureUnit Seconds -SaveOutput /scomma -AsJob
    Set-AppNetworkCounter -CaptureTime 10 -CaptureUnit Seconds -SaveOutput /scomma -WaitProcess
    Set-AppNetworkCounter -CaptureTime 10 -CaptureUnit Seconds -SaveOutput /scomma -TranslateLanguage 'de'

    .NOTES
    v0.0.5
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "duration for which network usage data should be captured")]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$CaptureTime,

        [Parameter(Mandatory = $true, HelpMessage = "time unit for the capture time")]
        [ValidateSet("Seconds", "Minutes", "Hours")]
        [string]$CaptureUnit,

        [Parameter(Mandatory = $true, HelpMessage = "format in which the captured data should be saved")]
        [ValidateSet("/sjson", "/scomma", "/shtml", "/sverhtml", "/sxml", "/stab", "/stext")]
        [string]$SaveOutput,

        [Parameter(Mandatory = $false, HelpMessage = "column by which the captured data should be sorted")]
        [ValidateSet("Application Name", "Application Path", "Received Bytes", "Sent Bytes")]
        [string]$SortColumn,

        [Parameter(Mandatory = $false, HelpMessage = "local path where the AppNetworkCounter utility archive should be downloaded")]
        [string]$DownloadPath = "$env:USERPROFILE\Desktop\AppNetworkCounter\AppNetworkCounter-x64.zip",

        [Parameter(Mandatory = $false, HelpMessage = "path where the captured network usage data should be saved")]
        [string]$OutputFilePath = "$env:USERPROFILE\Desktop\AppNetworkCounter\NetworkReport",

        [Parameter(Mandatory = $false, HelpMessage = "URL from which the AppNetworkCounter utility should be downloaded")]
        [uri]$AppNetCounterUrl = "https://www.nirsoft.net/utils/appnetworkcounter-x64.zip",

        [Parameter(Mandatory = $false, HelpMessage = "configuration file to customize the behavior of the AppNetworkCounter utility")]
        [string]$ConfigFile,

        [Parameter(Mandatory = $false, HelpMessage = "language for translating the user interface")]
        [ValidateSet("ar", "pt-br", "nl", "fr", "de", "el", "hu", "it", "fa", "pl", "ro", "ru", "sk", "tr", "cs", "sv", "th", "es", "zh", "ja")]  
        [string]$TranslateLanguage,

        [Parameter(Mandatory = $false, HelpMessage = "wait for the process to end or release")]
        [switch]$WaitProcess,

        [Parameter(Mandatory = $false, HelpMessage = "run the process as a background job")]
        [switch]$AsJob
    )
    BEGIN {
        $TimeUnitInSeconds = @{
            "Seconds" = 1
            "Minutes" = 60
            "Hours"   = 3600
        }[$CaptureUnit]
        $Duration = $CaptureTime * $TimeUnitInSeconds * 1000
        if (Get-Process -Name AppNetworkCounter -ErrorAction SilentlyContinue) {
            Stop-Process -Name AppNetworkCounter -Force -Verbose
        }
        $TempDir = Split-Path -Path $DownloadPath
        if (!(Test-Path -Path $TempDir -PathType Container)) {
            New-Item -Path $TempDir -ItemType Directory | Out-Null
        }
        if ($AsJob) {
            Write-Host "Starting AppNetworkCounter in the background..." -ForegroundColor Cyan
        }
    }
    PROCESS {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        try {
            Write-Verbose -Message "AppNetworkCounter downloading is starting..."
            Invoke-WebRequest -Uri $AppNetCounterUrl -OutFile $DownloadPath -UseBasicParsing -Verbose
        }
        catch {
            Write-Error -Message "An error occurred: $($_.Exception.Message)"
            return
        }
        if (Test-Path -Path $DownloadPath -ErrorAction Stop) {
            Expand-Archive -Path $DownloadPath -DestinationPath "$env:USERPROFILE\Desktop\AppNetworkCounter" -Force -Verbose
            $AppPath = "$env:USERPROFILE\Desktop\AppNetworkCounter\AppNetworkCounter.exe"
            if ($TranslateLanguage) {
                $TranslationLinks = @{
                    "ar"    = "arabic.zip"
                    "pt-br" = "brazilian_portuguese.zip"
                    "nl"    = "dutch.zip"
                    "fr"    = "french.zip"
                    "de"    = "german.zip"
                    "el"    = "greek.zip"
                    "hu"    = "hungarian.zip"
                    "it"    = "italian.zip"
                    "fa"    = "persian.zip"
                    "pl"    = "polish.zip"
                    "ro"    = "romanian.zip"
                    "ru"    = "russian.zip"
                    "sk"    = "slovak.zip"
                    "tr"    = "turkish.zip"
                    "cs"    = "czech.zip"
                    "sv"    = "swedish.zip"
                    "th"    = "thai.zip"
                    "es"    = "spanish.zip"
                    "zh"    = "schinese.zip"
                    "ja"    = "japanese.zip"
                }
                if ($TranslationLinks.ContainsKey($TranslateLanguage)) {
                    $TranslationLink = "https://www.nirsoft.net/utils/trans/appnetworkcounter_" + $TranslationLinks[$TranslateLanguage]
                    Write-Host "Translating to $TranslateLanguage" -ForegroundColor Yellow
                    $TranslationFilePath = Join-Path -Path $TempDir -ChildPath "AppNetworkCounter_lng.ini"
                    try {
                        Write-Verbose -Message "Downloading translation file..."
                        $TranslationZipPath = Join-Path -Path $TempDir -ChildPath "Translation.zip"
                        Invoke-WebRequest -Uri $TranslationLink -OutFile $TranslationZipPath -UseBasicParsing -Verbose
                        Expand-Archive -Path $TranslationZipPath -DestinationPath $TempDir -Force -Verbose
                        $TranslationFilePath
                    }
                    catch {
                        Write-Error -Message "An error occurred while downloading translation: $($_.Exception.Message)"
                        return
                    }
                }
                else {
                    Write-Warning -Message "Unsupported translation language: $TranslateLanguage"
                }
            }
            else {
                Start-Process -FilePath $AppPath -WindowStyle Minimized
                Write-Verbose "Creating default config file..."
            }
            $Process = Get-Process -Name AppNetworkCounter -ErrorAction SilentlyContinue
            if ($null -ne $Process) {
                Write-Host "Stopping process gracefully..." -ForegroundColor Cyan
                $Process.CloseMainWindow()
                Start-Sleep -Seconds 3
                if (!$Process.HasExited) {
                    Write-Host "Forcefully terminating process..." -ForegroundColor DarkGreen
                    Stop-Process -InputObject $Process -Force -Verbose -ErrorAction Ignore
                }
                else {
                    Write-Host "Process has already exited gracefully, config file should be created." -ForegroundColor Green
                }
            }
            $CommandArgs = @("/CaptureTime", $Duration)
            if ($ConfigFile) {
                $CommandArgs += "/cfg", $ConfigFile
            }
            if ($SaveOutput) {
                $OutFileExt = @{
                    "/stext"    = "txt"
                    "/stab"     = "tsv"
                    "/scomma"   = "csv"
                    "/shtml"    = "html"
                    "/sverhtml" = "html"
                    "/sxml"     = "xml"
                    "/sjson"    = "json"
                }[$SaveOutput]
                $OutputFileBaseName = [System.IO.Path]::GetFileNameWithoutExtension($OutputFilePath)
                $OutputFilePath = Join-Path -Path $TempDir -ChildPath "$OutputFileBaseName.$OutFileExt"
                $CommandArgs += $SaveOutput, $OutputFilePath
            }
            else {
                Write-Warning -Message "Invalid 'SaveOutput' value provided!"
            }
            if ($SortColumn) {
                $CommandArgs += "/sort", $SortColumn
            }
            if ($WaitProcess) {
                Write-Host "Process is running for the next $CaptureTime $CaptureUnit, please wait..." -ForegroundColor Cyan
            }
            $StartProcessParams = @{
                FilePath               = $AppPath
                ArgumentList           = $CommandArgs
                Wait                   = $WaitProcess
                WindowStyle            = "Hidden"
                WorkingDirectory       = "$env:USERPROFILE\Desktop\AppNetworkCounter"
                RedirectStandardError  = "$env:USERPROFILE\Desktop\AppNetworkCounter\anc-rse.txt"
                RedirectStandardOutput = "$env:USERPROFILE\Desktop\AppNetworkCounter\anc-rso.txt"
            }
            if ($AsJob) {
                Write-Verbose -Message "Running the process in the background job..."
                $JobScriptBlock = {
                    param ($AppPath, $StartProcessParams)
                    Start-Process @StartProcessParams | Out-Null
                }
                Start-Job -ScriptBlock $JobScriptBlock -ArgumentList $AppPath, $StartProcessParams | Out-Null
                Write-Host "AppNetworkCounter process is running in the background." -ForegroundColor Cyan
            }
            else {
                Write-Verbose -Message "Running the process normally..."
                Start-Process @StartProcessParams | Out-Null
                Write-Host "Process has finished, check results." -ForegroundColor Green
            }
        }
        else {
            Write-Error -Message "Failed to download file: $($_.Exception)"
        }
    }
    END {
        if (!$WaitProcess -and !$AsJob) {
            Write-Host "Process is running for the next $CaptureTime $CaptureUnit..." -ForegroundColor Cyan
        }
    }
}
