Function Get-DirectoryInfo {
    <#
    .SYNOPSIS
    Retrieves statistics for a specified directory including file and folder counts, sizes, etc.
    
    .DESCRIPTION
    This function gathers information about a directory such as the number of files, folders, total size of files, and optionally folder sizes. It allows filtering by file type and excluding hidden items.
    
    .PARAMETER Path
    Mandatory - specifies the path of the directory.
    .PARAMETER IncludeSubdirectories
    NotMandatory - indicates whether to include subdirectories in the search.
    .PARAMETER CalculateFileSize
    NotMandatory - whether to calculate the total size of files in the directory.
    .PARAMETER CalculateFolderSize
    NotMandatory - whether to calculate the total size of folders in the directory.
    .PARAMETER ExcludeHiddenItems
    NotMandatory - excludes hidden and system items from the statistics.
    .PARAMETER FilterFileType
    NotMandatory - filters statistics by a specific file type (extension).
    
    .EXAMPLE
    Get-DirectoryInfo -Path "C:\SomeFolder" -IncludeSubdirectories -CalculateFileSize -CalculateFolderSize -FilterFileType ".txt"
    
    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSubdirectories,

        [Parameter(Mandatory = $false)]
        [switch]$CalculateFileSize,

        [Parameter(Mandatory = $false)]
        [switch]$CalculateFolderSize,

        [Parameter(Mandatory = $false)]
        [switch]$ExcludeHiddenItems,

        [Parameter(Mandatory = $false)]
        [string]$FilterFileType
    )
    BEGIN {
        $FolderCount = 0
        $FileCount = 0
        $TotalSize = 0
        $FolderSize = 0
    }
    PROCESS {
        $Items = Get-ChildItem -Path $Path -Recurse:$IncludeSubdirectories -ErrorAction SilentlyContinue
        foreach ($Item in $Items) {
            if ($ExcludeHiddenItems -and ($Item.Attributes -match "Hidden" -or $Item.Attributes -match "System")) {
                continue
            }
            if ($Item.PSIsContainer) {
                $FolderCount++
                if ($CalculateFolderSize) {
                    $FolderSize += Get-ChildItem -Path $Item.FullName -Recurse -ErrorAction SilentlyContinue |
                    Where-Object { !$_.PSIsContainer } |
                    Measure-Object -Property Length -Sum |
                    Select-Object -ExpandProperty Sum
                }
            }
            else {
                if (-not $FilterFileType -or $Item.Extension -eq $FilterFileType) {
                    $FileCount++
                    if ($CalculateFileSize) {
                        $TotalSize += $Item.Length
                    }
                }
            }
        }
    }
    END {
        $Result = @{
            FolderCount = $FolderCount
            FileCount   = $FileCount
            TotalSize   = $TotalSize
            FolderSize  = $FolderSize
        }
        return $Result
    }
}