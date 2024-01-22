Function Restore-RecycleBinItem {
    <#
    .SYNOPSIS
    Restores an item from the Recycle Bin to a specified destination or its original location.

    .DESCRIPTION
    This function restores an item from the Recycle Bin either to a specified destination path or its original location. If a destination path is provided, the item will be restored to that path. If no destination path is provided, the item will be restored to its original location in the file system.

    .PARAMETER ItemName
    Specifies the name of the item to be restored from the Recycle Bin.
    .PARAMETER DestinationPath
    Path to which the item will be restored, if not provided, item will be restored to its original location.

    .EXAMPLE
    Restore-RecycleBinItem -ItemName "example_file.txt" -DestinationPath "$env:USERPROFILE\Desktop"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ItemName,

        [Parameter(Mandatory = $false)]
        [string]$DestinationPath
    )
    BEGIN {
        $Shell = New-Object -ComObject Shell.Application
        $RecycleBin = $Shell.Namespace(0xA)
    }
    PROCESS {
        foreach ($Item in $RecycleBin.Items()) {
            $CurrentItemName = $RecycleBin.GetDetailsOf($Item, 0)
            if ($CurrentItemName -eq $ItemName) {
                $RestoredItemPath = $Item.Path
                if (-not [string]::IsNullOrEmpty($DestinationPath)) {
                    if (-not (Test-Path -Path $DestinationPath)) {
                        New-Item -ItemType Directory -Force -Path $DestinationPath | Out-Null
                    }
                    $DestinationItem = Join-Path -Path $DestinationPath -ChildPath $ItemName
                    Copy-Item -Path $RestoredItemPath -Destination $DestinationItem -Force -Verbose
                    Remove-Item -Path $RestoredItemPath -Force -Verbose
                    Write-Host "Item '$ItemName' has been restored to '$DestinationPath'"
                    return
                }
                else {
                    $RecycleBin.MoveHere($RestoredItemPath) | Out-Null
                    Write-Host "Item '$ItemName' has been restored to its original location" -ForegroundColor Green
                    return
                }
            }
        }
    }
    END {
        #Write-Host "Item '$ItemName' not found in Recycle Bin!" -ForegroundColor DarkGray
    }
}
