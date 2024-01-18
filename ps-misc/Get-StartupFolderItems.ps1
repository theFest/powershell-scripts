Function Get-StartupFolderItems {
    <#
    .SYNOPSIS
    Retrieves information about items in the user or all users startup folder.

    .DESCRIPTION
    This function retrieves information about items (files) in the user's startup folder or all users' startup folder, based on the specified scope.
    It provides details such as file path, name, scope, file type, file extension, last write time, and size. Users can filter, sort, and include hidden items as needed.

    .PARAMETER Scope
    Specifies the scope for retrieving startup items, values are "CurrentUser" or "AllUsers".
    .PARAMETER FileExtension
    Filters items based on the specified file extension.
    .PARAMETER SortByName
    Sorts the items by name in ascending order.
    .PARAMETER SortByDate
    Sorts the items by last write time in ascending order.
    .PARAMETER IncludeHidden
    Includes hidden items in the result if specified.
    
    .EXAMPLE
    Get-StartupFolderItems

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUser", "AllUsers")]
        [string]$Scope = "CurrentUser",

        [Parameter(Mandatory = $false)]
        [string]$FileExtension,

        [Parameter(Mandatory = $false)]
        [switch]$SortByName,

        [Parameter(Mandatory = $false)]
        [switch]$SortByDate,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeHidden
    )
    $StartupFolderPath = switch ($Scope) {
        "CurrentUser" { "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup" }
        "AllUsers" { "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup" }
    }
    $Items = Get-ChildItem -Path $StartupFolderPath -File -ErrorAction SilentlyContinue
    if ($null -eq $Items) {
        Write-Warning -Message "No items found in the specified scope: $Scope"
        return
    }
    if ($FileExtension) {
        $Items = $Items | Where-Object { $_.Extension -eq $FileExtension }
    }
    if (-not $IncludeHidden) {
        $Items = $Items | Where-Object { -not $_.Attributes.HasFlag([System.IO.FileAttributes]::Hidden) }
    }
    if ($SortByName) {
        $Items = $Items | Sort-Object Name
    }
    if ($SortByDate) {
        $Items = $Items | Sort-Object LastWriteTime
    }
    $OutputItems = $Items | ForEach-Object {
        [PSCustomObject]@{
            Path          = $_.FullName
            Name          = $_.Name
            Scope         = $Scope
            Type          = "Startup Folder"
            Extension     = $_.Extension
            LastWriteTime = $_.LastWriteTime
            Size          = $_.Length
        }
    }
    Write-Output -InputObject $OutputItems
}
