#Requires -Version 3.0
Function Get-RecentFiles {
    <#
    .SYNOPSIS
    Retrieves recently modified files within a specified path.
    
    .DESCRIPTION
    This function retrieves files modified within a certain timeframe from a specified directory path. It allows filtering by date, the number of recent files, file type, and includes options to search in subdirectories and exclude hidden files.

    .PARAMETER Path
    Directory path from which to retrieve files, defaults to the current directory.
    .PARAMETER Days
    Number of days in the past from which files should be considered, defaults to 1 day.
    .PARAMETER StartDate
    Start date from which files should be considered, overrides Days parameter if provided.
    .PARAMETER Newest
    Specifies the number of newest files to retrieve.
    .PARAMETER Filter
    Wildcard filter for file selection, defaults to '*' (all files).
    .PARAMETER IncludeSubdirectories
    Switch to include files from subdirectories within the specified path.
    .PARAMETER ExcludeHidden
    Switch to exclude hidden files from the result set.

    .EXAMPLE
    Get-RecentFiles -Path $env:windir -Days 7 -Newest 10

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateScript({
                if ((Test-Path -Path $_) -and ((Get-Item -Path $_).PSIsContainer)) {
                    $True
                }
                else {
                    throw "Verify path exists and is a FileSystem path!"
                }
            })]
        [string]$Path = ".",

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$Days = 1,

        [Parameter(Mandatory = $false)]
        [datetime]$StartDate = (Get-Date).AddDays(-$Days).Date,

        [Parameter(Mandatory = $false)]
        [int]$Newest,

        [Parameter(Mandatory = $false)]
        [string]$Filter = "*",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSubdirectories,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeHidden
    )
    BEGIN {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"
    }
    PROCESS {
        $ResolvedPath = Resolve-Path -Path $Path
        Write-Verbose -Message "Getting files matching '$Filter' from '$ResolvedPath' since $($StartDate.ToShortDateString())"
        $Files = Get-ChildItem -Path $ResolvedPath -Filter $Filter -File -Recurse:$IncludeSubdirectories | Where-Object {
            $_.LastWriteTime -ge $StartDate -and 
                     (-not $_.Attributes.HasFlag([System.IO.FileAttributes]::Hidden) -or -not $ExcludeHidden)
        } | Sort-Object LastWriteTime
        if ($Newest) {
            Write-Verbose -Message "Retrieving $Newest newest files"
            $Files = $Files | Select-Object -Last $Newest
        }
        $Files
    }
    END {
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
    }
}
