Function Start-CustomFileExtensionScan {
    <#
    .SYNOPSIS
    Initiates a custom Windows Defender scan based on specified file extensions.

    .DESCRIPTION
    This function initiates a custom Windows Defender scan for files with specified file extensions in the specified directory.

    .PARAMETER Extensions
    File extensions to be scanned.
    .PARAMETER ScanPath
    Directory path to scan, default is "C:\".
    .PARAMETER StopScan
    If specified, stops an ongoing scan.

    .EXAMPLE
    Start-CustomFileExtensionScan -Extensions ".csv", ".json"
    Start-CustomFileExtensionScan -StopScan

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Extensions,

        [Parameter(Mandatory = $false)]
        [string]$ScanPath = "C:\",

        [Parameter(Mandatory = $false)]
        [switch]$StopScan
    )
    BEGIN {
        $StartTime = Get-Date
        if ($StopScan) {
            Write-Host "Stopping ongoing scan, please wait..." -ForegroundColor DarkYellow
            Start-Process -FilePath "$env:ProgramFiles\Windows Defender\MpCmdRun.exe" -ArgumentList "-Scan -Cancel" -Wait -WindowStyle Hidden
            exit
        }
    }
    PROCESS {
        try {
            $FilesToScan = Get-ChildItem -Path $ScanPath -File -Include $Extensions -Recurse -ErrorAction SilentlyContinue
            if ($FilesToScan) {
                Start-MpScan -ScanType CustomScan -ScanItem $FilesToScan.FullName
                Write-Verbose -Message "Custom file extension scan initiated for: $($Extensions -join ', ')"
            }
            else {
                Write-Warning -Message "No files found with the specified extensions in the path: $ScanPath!"
            }
        }
        catch {
            Write-Error -Message "An error occurred while initiating custom file extension scan: $_!"
        }
    }
    END {
        $ScanDuration = (Get-Date).Subtract($StartTime).ToString("hh\:mm\:ss\.fff")
        Write-Host "Total scan duration: $ScanDuration" -ForegroundColor Cyan
    }
}
