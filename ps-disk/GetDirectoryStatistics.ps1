Function GetDirectoryStatistics {
    <#
    .SYNOPSIS
    Retrieves statistics about a directory,
    
    .DESCRIPTION
    This function counts the number of folders and files within the directory and its subdirectories if the IncludeSubdirectories parameter is specified and more.
    
    .PARAMETER Path
    Mandatory - specifies the path of the directory for which statistics need to be calculated.
    .PARAMETER IncludeSubdirectories
    NotMandatory - will include the subdirectories of the specified directory in the statistics calculation.
    
    .EXAMPLE
    GetDirectoryStatistics -Path "your_path" -IncludeSubdirectories
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSubdirectories
    )
    $FolderCount = 0
    $FileCount = 0
    $TotalSize = 0
    Get-ChildItem -Path $Path -Recurse:$IncludeSubdirectories | ForEach-Object {
        if ($_.PSIsContainer) {
            $FolderCount++
        }
        else {
            $FileCount++
            $TotalSize += $_.Length
        }
    }
    $Result = @{
        FolderCount = $FolderCount
        FileCount   = $FileCount
        TotalSize   = $TotalSize
    }
    return $result
}