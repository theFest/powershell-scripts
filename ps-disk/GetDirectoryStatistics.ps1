Function GetDirectoryStatistics {
    <#
    .SYNOPSIS
    Retrieves statistics about a directory,
    
    .DESCRIPTION
    This function counts the number of folders and files within the directory and other relevant details.
    
    .PARAMETER Path
    Mandatory - specifies the path of the directory for which statistics need to be calculated.
    .PARAMETER IncludeSubdirectories
    NotMandatory - will include the subdirectories of the specified directory in the statistics calculation.
    .PARAMETER CalculateFileSize
    NotMandatory - if specified, will calculate total file size.
    .PARAMETER CalculateFolderSize
    NotMandatory - if specified, will calculate folder size.
    .PARAMETER ExcludeHiddenItems
    NotMandatory - if used, excludes hidden items from output.
    
    .EXAMPLE
    GetDirectoryStatistics -Path "your_path" -IncludeSubdirectories -CalculateFileSize -CalculateFolderSize -ExcludeHiddenItems
    
    .NOTES
    v0.0.2
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
        [switch]$ExcludeHiddenItems
    )
    BEGIN {
        $FolderCount = 0
        $FileCount = 0
        $TotalSize = 0
        $FolderSize = 0
    }
    PROCESS {
        $Items = Get-ChildItem -Path $Path -Recurse:$IncludeSubdirectories
        foreach ($Item in $Items) {
            if ($ExcludeHiddenItems -and $Item.Attributes -match "Hidden") {
                continue
            }
            if ($Item.PSIsContainer) {
                $FolderCount++
                if ($CalculateFolderSize) {
                    $FolderSize += Get-ChildItem -Path $Item.FullName -Recurse | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum
                }
            }
            else {
                $FileCount++
                if ($CalculateFileSize) {
                    $TotalSize += $Item.Length
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