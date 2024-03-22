Function Get-LockingProcess {
    <#
    .SYNOPSIS
    Retrieves information about processes locking a specific file or directory using Handle utility.

    .DESCRIPTION
    This function retrieves information about processes locking a specific file or directory using the Handle utility. It downloads the Handle utility if not already available and parses its output to identify processes with open handles matching the specified file or directory path.

    .PARAMETER Path
    Specifies the path or filename. You can enter a partial name without wildcards.
    .PARAMETER HandlePath
    Path to the Handle utility executable. If not provided, the function downloads the latest Handle utility from Sysinternals website to the temporary directory.
    .PARAMETER ProcessID
    Process ID (PID) of the process to filter the results, only handles associated with the specified process ID will be included.
    .PARAMETER OutputFormat
    Format of the output, values are 'Table' and 'List', default is 'Table'.
    .PARAMETER IncludeProcessTypes
    An array of process types to include in the results. By default, all process types are included.
    .PARAMETER ExcludeProcessTypes
    An array of process types to exclude from the results. By default, no process types are excluded.
    .PARAMETER MaxResults
    The maximum number of results to return, default is unlimited.
    .PARAMETER TimeoutInSeconds
    Timeout duration (in seconds) for downloading the Handle utility, default is 60 seconds.

    .EXAMPLE
    Get-LockingProcess -Path "C:\Example\File.txt"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Specify the path or filename, you can enter a partial name without wildcards")]
        [ValidateScript({
                if (Test-Path -Path $_ -PathType Leaf) { 
                    $true 
                }
                else { 
                    throw "File does not exist at $_" 
                }
            })]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
                if (
                    Test-Path -Path $_ -PathType Container) { 
                    $true 
                }
                else { 
                    throw "Directory does not exist at $_" 
                }
            })]
        [string]$HandlePath = (Join-Path $env:TEMP "handle.exe"),

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$ProcessID,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Table", "List")]
        [string]$OutputFormat = "Table",

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [ValidateCount(1, [int]::MaxValue)]
        [string[]]$IncludeProcessTypes,

        [Parameter(Mandatory = $false)]
        [ValidateNotNull()]
        [ValidateCount(1, [int]::MaxValue)]
        [string[]]$ExcludeProcessTypes,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$MaxResults,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [int]::MaxValue)]
        [int]$TimeoutInSeconds = 60
    )
    BEGIN {
        try {
            Write-Verbose -Message "Checking Handle utility..."
            if (-not (Test-Path $HandlePath)) {
                Write-Verbose -Message "Downloading the latest Handle utility..."
                $Url = "https://live.sysinternals.com/handle.exe"
                Invoke-WebRequest -Uri $Url -OutFile $HandlePath -TimeoutSec $TimeoutInSeconds -Verbose
                Write-Verbose -Message "Handle utility downloaded to: $HandlePath"
            }
            else {
                Write-Verbose -Message "Using existing Handle utility at: $HandlePath"
            }
            [Regex]$MatchPattern = "(?<Name>\w+\.\w+)\s+pid:\s+(?<PID>\b(\d+)\b)\s+type:\s+(?<Type>\w+)\s+\w+:\s+(?<Path>.*)"
            $Results = @()
        }
        catch {
            Write-Warning -Message "Error: $_"
            return
        }
    }
    PROCESS {
        try {
            Write-Verbose -Message "Invoking Handle utility for path: $Path"
            $Data = & $HandlePath $Path
            Write-Verbose -Message "Handle utility output:`n$Data"
            $MyMatches = $MatchPattern.Matches($Data)
            foreach ($Match in $MyMatches) {
                $ProcessIDMatch = $Match.Groups["PID"].Value
                Write-Verbose -Message "Found matching PID: $ProcessIDMatch"
                if ($ProcessID -eq $null -or $ProcessIDMatch -eq $ProcessID) {
                    $Type = $Match.Groups["Type"].Value
                    Write-Verbose -Message "Type of handle: $Type"
                    if (($null -eq $IncludeProcessTypes -or $IncludeProcessTypes -contains $Type) -and
                        ($null -eq $ExcludeProcessTypes -or $ExcludeProcessTypes -notcontains $Type)) {
                        $Result = [PSCustomObject]@{
                            FullName = $Match.Groups["Name"].Value
                            Name     = $Match.Groups["Name"].Value.Split(".")[0]
                            ID       = $ProcessIDMatch
                            Type     = $Type
                            Path     = $Match.Groups["Path"].Value
                        }
                        Write-Verbose -Message "Adding result:`n$Result"
                        $Results += $Result
                        if ($MaxResults -gt 0 -and $Results.Count -ge $MaxResults) {
                            break
                        }
                    }
                }
            }
        }
        catch {
            Write-Warning -Message "Error: $_"
            return
        }
    }
    END {
        try {
            if ($Results.Count -gt 0) {
                Write-Verbose -Message "Displaying results:"
                if ($OutputFormat -eq "Table") {
                    $Results | Format-Table
                }
                elseif ($OutputFormat -eq "List") {
                    $Results | Format-List
                }
            }
            else {
                Write-Warning -Message "No matching handles found!"
            }
        }
        catch {
            Write-Warning -Message "Error: $_"
        }
    }
}
