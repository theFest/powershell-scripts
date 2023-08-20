Function Set-AppNetworkCounter {
    <#
    .SYNOPSIS
    Monitors network usage of applications using AppNetworkCounter from Nirsoft.

    .DESCRIPTION
    This function is used to monitor network usage of applications using the AppNetworkCounter utility.
    It downloads the utility, captures network usage data, and provides options to save the output in various formats.
    The function allows customization through parameters such as capture time, output file format, sorting column, and more.

    .PARAMETER CaptureTime
    NotMandatory - specifies the duration (in minutes) for which network usage data should be captured. The default value is 20 minues.
    .PARAMETER SaveOutput
    NotMandatory - format in which the captured network usage data should be saved. Available options include "/sjson", "/scomma", "/shtml", "/sverhtml", "/sxml", "/stab", and "/stext". The default is "/sjson".
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

    .EXAMPLE
    Set-AppNetworkCounter

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateScript({ 
                $_ -gt 0 
            })]
        [int]$CaptureTime = 20,

        [Parameter(Mandatory = $false)]
        [ValidateSet("/sjson", "/scomma", "/shtml", "/sverhtml", "/sxml", "/stab", "/stext")]
        [string]$SaveOutput = "/sjson",

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
        [string]$ConfigFile
    )
    BEGIN {
        $Duration = $CaptureTime * 1000
        if (Get-Process -Name AppNetworkCounter -ErrorAction SilentlyContinue) {
            Stop-Process -Name AppNetworkCounter -Force -Verbose
        }
        $TempDir = Split-Path -Path $DownloadPath
        if (!(Test-Path -Path $TempDir -PathType Container)) {
            New-Item -Path $TempDir -ItemType Directory | Out-Null
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
            Write-Verbose "Waingin to " 
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
                    Write-Host "Process has already exited gracefully."
                }
            }
            else {
                Write-Host "Process not found." -ForegroundColor DarkRed
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
            $StartProcessParams = @{
                FilePath               = "$env:USERPROFILE\Desktop\AppNetworkCounter\AppNetworkCounter.exe"
                ArgumentList           = $CommandArgs
                WorkingDirectory       = "$env:USERPROFILE\Desktop\AppNetworkCounter"
                Wait                   = $false
                WindowStyle            = "Hidden"
                RedirectStandardOutput = "$env:USERPROFILE\Desktop\AppNetworkCounter\AppNC-RSO.txt"
                RedirectStandardError  = "$env:USERPROFILE\Desktop\AppNetworkCounter\AppNC-RSE.txt"
            }
            Start-Process @StartProcessParams | Out-Null
        }
        else {
            Write-Error -Message "Failed to download the file!"
        }
    }
    END {
        Write-Host "Process is running for next $CaptureTime minutes."
    }
}
