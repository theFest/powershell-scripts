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
    Mandatory - format in which the captured network usage data should be saved. Available options include "/sjson", "/scomma", "/shtml", "/sverhtml", "/sxml", "/stab", and "/stext".
    .PARAMETER SortColumn
    NotMandatory - column by which the captured data should be sorted. Available options for sorting include "Application Name", "Application Path", "Received Bytes", and "Sent Bytes".
    .PARAMETER DownloadPath
    NotMandatory - local path where the AppNetworkCounter utility archive should be downloaded. The default path is the user's desktop.
    .PARAMETER OutputFilePath
    NotMandatory - the path where the captured network usage data should be saved. The default path is the user's desktop.
    .PARAMETER AppNetCounterUrl
    NotMandatory - URL from which the AppNetworkCounter utility should be downloaded. The default URL is "https://www.nirsoft.net/utils/appnetworkcounter-x64.zip".
    .PARAMETER ConfigFile
    NotMandatory - a configuration file to customize the behavior of the AppNetworkCounter utility.
    .PARAMETER WaitProcess
    NotMandatory - use this switch is to wait(in session) for process to end or release.
    .PARAMETER AsJob
    NotMandatory - use this switch to run as background job.

    .EXAMPLE
    Set-AppNetworkCounter -CaptureTime 10 -CaptureUnit Seconds -SaveOutput /scomma
    Set-AppNetworkCounter -CaptureTime 10 -CaptureUnit Seconds -SaveOutput /scomma -AsJob
    Set-AppNetworkCounter -CaptureTime 10 -CaptureUnit Seconds -SaveOutput /scomma -WaitProcess

    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript({ 
                $_ -gt 0 
            })]
        [int]$CaptureTime,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Seconds", "Minutes", "Hours")]
        [string]$CaptureUnit,

        [Parameter(Mandatory = $true)]
        [ValidateSet("/sjson", "/scomma", "/shtml", "/sverhtml", "/sxml", "/stab", "/stext")]
        [string]$SaveOutput,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Application Name", "Application Path", "Received Bytes", "Sent Bytes")]
        [string]$SortColumn,

        [Parameter(Mandatory = $false)]
        [string]$DownloadPath = "$env:USERPROFILE\Desktop\AppNetworkCounter\AppNetworkCounter-x64.zip",

        [Parameter(Mandatory = $false)]
        [string]$OutputFilePath = "$env:USERPROFILE\Desktop\AppNetworkCounter\NetworkReport",

        [Parameter(Mandatory = $false)]
        [uri]$AppNetCounterUrl = "https://www.nirsoft.net/utils/appnetworkcounter-x64.zip",

        [Parameter(Mandatory = $false)]
        [ValidateScript({ 
                Test-Path -PathType Leaf -Path $_ 
            })]
        [string]$ConfigFile,

        [Parameter(Mandatory = $false)]
        [switch]$WaitProcess,

        [Parameter(Mandatory = $false)]
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
        }
        if (Test-Path -Path $DownloadPath -ErrorAction Stop) {
            Expand-Archive -Path $DownloadPath -DestinationPath "$env:USERPROFILE\Desktop\AppNetworkCounter" -Force -Verbose
            $AppPath = "$env:USERPROFILE\Desktop\AppNetworkCounter\AppNetworkCounter.exe"
            Start-Process -FilePath $AppPath -WindowStyle Minimized
            Write-Verbose "Creating default config file..." 
            Start-Sleep -Seconds 2
            $Process = Get-Process -Name AppNetworkCounter -ErrorAction SilentlyContinue
            if ($null -ne $Process) {
                Write-Host "Stopping process gracefully..." -ForegroundColor Cyan
                $Process.CloseMainWindow()
                Start-Sleep -Seconds 3
                if (!$Process.HasExited) {
                    Write-Host "Forcefully terminating process..."
                    Stop-Process -InputObject $Process -Force -Verbose
                }
                else {
                    Write-Host "Process has already exited gracefully, config file should be created." -ForegroundColor Green
                }
            }
            else {
                Write-Host "Process not found!" -ForegroundColor DarkRed
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
                Write-Host "Process is running for next $CaptureTime $CaptureUnit, please wait..." -ForegroundColor Cyan
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
            Write-Error -Message "Failed to download file: $($_.Exception.Message)"
        }
    }
    END {
        if (-not $WaitProcess -and -not $AsJob) {
            Write-Host "Process is running for next $CaptureTime $CaptureUnit..." -ForegroundColor Cyan
        }
    }
}
