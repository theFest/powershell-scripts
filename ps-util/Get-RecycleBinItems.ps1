Function Get-RecycleBinItems {
    <#
    .SYNOPSIS
    Retrieves items from the recycle bin with optional filtering and sorting.

    .DESCRIPTION
    This function retrieves items from the recycle bin and optionally includes sub-items, filters based on specified criteria, and sorts the results.

    .PARAMETER IncludeSubItems
    Specifies whether to include items from subfolders within the recycle bin.
    .PARAMETER Filter
    Filters items based on a specified pattern.
    .PARAMETER SortProperty
    Property by which to sort the items, allowed values: 'Name', 'Path', 'OriginalPath', 'OriginalFullName', 'Size', 'DateDeleted'.
    .PARAMETER Descending
    Indicates sorting order, if present, items will be sorted in descending order; otherwise, ascending order will be used.

    .EXAMPLE
    Get-RecycleBinItems -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$IncludeSubItems,

        [Parameter(Mandatory = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $false)]
        [ValidateSet("DateDeleted", "Name", "Path", "OriginalPath", "OriginalFullName", "Size")]
        [string]$SortProperty = "DateDeleted",

        [Parameter(Mandatory = $false)]
        [switch]$Descending
    )
    BEGIN {
        Write-Verbose -Message "Starting $($MyInvocation.MyCommand)"
        $Shell = New-Object -ComObject Shell.Application
        $RecycleBin = $Shell.Namespace(0xa)
        $Items = @()
    }
    PROCESS {
        foreach ($Item in $RecycleBin.Items()) {
            $ItemDetails = [PSCustomObject]@{
                Name             = $Item.Name
                Path             = $Item.Path
                OriginalPath     = $Item.ExtendedProperty("System.Recycle.FullPathAndFileName")
                OriginalFullName = $Item.ExtendedProperty("System.Recycle.OriginalFileName")
                Size             = $Item.ExtendedProperty("System.Size")
                DateDeleted      = $Item.ExtendedProperty("System.Recycle.DateDeleted")
            }
            if ($IncludeSubItems) {
                foreach ($SubItem in $Item.GetFolder.Items()) {
                    $SubItemDetails = [PSCustomObject]@{
                        Name             = $SubItem.Name
                        Path             = $SubItem.Path
                        OriginalPath     = $SubItem.ExtendedProperty("System.Recycle.FullPathAndFileName")
                        OriginalFullName = $SubItem.ExtendedProperty("System.Recycle.OriginalFileName")
                        Size             = $SubItem.ExtendedProperty("System.Size")
                        DateDeleted      = $SubItem.ExtendedProperty("System.Recycle.DateDeleted")
                    }
                    $Items += $SubItemDetails
                }
            }
            $Items += $itemDetails
        }
    }
    END {
        if ($Filter) {
            $Items = $Items | Where-Object { $_.Name -like $Filter }
        }
        $SortedItems = $Items | Sort-Object -Property $SortProperty -Descending:$Descending
        Write-Verbose -Message "Ending $($MyInvocation.MyCommand)"
        Write-Output -InputObject $SortedItems
    }
}
