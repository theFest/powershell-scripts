Function Show-AdvancedDirectoryInfo {
    <#
    .SYNOPSIS
    Provides information about directories including file size or file count within a specified path.

    .DESCRIPTION
    This function retrieves details about directories at a given path, it can display either the size or the count of files within each directory.

    .PARAMETER Path
    Mandatory - path to the directory for which information is retrieved.
    .PARAMETER Detail
    NotMandatory - level of detail to display: "Size" for file size information, "Count" for file count.
    .PARAMETER Recurse
    NotMandatory - include subdirectories in the search.
    .PARAMETER Depth
    NotMandatory - depth of subdirectory levels to include.

    .EXAMPLE
    Show-AdvancedDirectoryInfo -Path $env:windir

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    [Alias("Show-AdvDRInfo")]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Enter a file system path")]
        [ValidateScript({ ( 
                    Test-Path $_ ) -AND ((Get-Item $_).psprovider.name -eq "FileSystem") })]
        [string]$Path,

        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "What detail do you want to see? Size or Count of files")]
        [ValidateSet("Size", "Count")]
        [string]$Detail = "Count",

        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Include subdirectories in the search")]
        [switch]$Recurse,

        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Specify the depth of subdirectory levels to include")]
        [int32]$Depth
    )
    DynamicParam {
        if ($Detail -eq "Size") {
            $Attributes = New-Object System.Management.Automation.ParameterAttribute
            $Attributes.HelpMessage = "Enter a unit of measurement: KB, MB, GB Bytes."
            $AttributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $AttributeCollection.Add($Attributes)
            $Alias = New-Object System.Management.Automation.AliasAttribute -ArgumentList "as"
            $AttributeCollection.Add($Alias)
            $Set = New-Object -type System.Management.Automation.ValidateSetAttribute -ArgumentList ("bytes", "KB", "MB", "GB")
            $AttributeCollection.add($Set)
            $DynParam1 = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("Unit", [string], $AttributeCollection)
            $DynParam1.Value = "Bytes"
            $ParamDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
            $ParamDictionary.Add("Unit", $DynParam1)
            return $ParamDictionary
        }
    }
    BEGIN {
        Write-Verbose -Message "Starting $($MyInvocation.MyCommand)"
        if ($Detail -eq 'Size' -AND (-not $PSBoundParameters.ContainsKey("unit"))) {
            $PSBoundParameters.Add("Unit", "bytes")
        }
        $GetCountScriptBlock = {
            param($Path)
            (Get-ChildItem -Path $Path -File).Count
        }
        $GetSizeScriptBlock = {
            param($Path, $Unit)
            $Sum = (Get-ChildItem $Path -File | Measure-Object -Sum -Property length).Sum
            switch ($Unit) {
                "KB" { 
                    "$([math]::round($Sum/1KB,2))KB" 
                }
                "MB" { 
                    "$([math]::round($Sum/1MB,2))MB" 
                }
                "GB" { 
                    "$([math]::round($Sum/1GB,2))GB" 
                }
                default { 
                    $Sum 
                }
            }
        }
        Write-Verbose -Message "PSBoundParameters"
        Write-Verbose -Message ($PSBoundParameters | Out-String)
        $GciParams = @{
            Path      = $Path
            Directory = $true
        }
        if ($PSBoundParameters["Depth"]) {
            $GciParams.Add("Depth", $PSBoundParameters["Depth"])
        }
        if ($PSBoundParameters["Recurse"]) {
            $GciParams.Add("Recurse", $PSBoundParameters["Recurse"])
        }
    }
    PROCESS {
        Write-Verbose -Message "Processing $(Convert-Path $Path)"
        $Directories = Get-ChildItem @GciParams
        if ($Detail -eq "Count") {
            Write-Verbose -Message "Getting file count..."
            if ($Recurse) {
                $Directories | Get-ChildItem -Recurse -Directory | Format-Wide -Property { "$($_.Name) [$( &$GetCountScriptBlock $_.Fullname)]" } -AutoSize -GroupBy @{Name = "Path"; Expression = { $_.Parent } }
            }
            else {
                $Directories | Format-Wide -Property { "$($_.Name) [$( &$GetCountScriptBlock $_.Fullname)]" } -AutoSize -GroupBy @{Name = "Path"; Expression = { $_.Parent } }
            }
        }
        else {
            Write-Verbose -Message "Getting file size in $($PSBoundParameters['Unit']) units"
            if ($Recurse) {
                $Directories | Get-ChildItem -Recurse -Directory | Format-Wide -Property { "$($_.Name) [$( &$GetSizeScriptBlock -Path $_.Fullname -Unit $($PSBoundParameters['Unit']))]" } -AutoSize -GroupBy @{Name = "Path"; Expression = { $_.Parent } }
            }
            else {
                $Directories | Format-Wide -Property { "$($_.Name) [$( &$GetSizeScriptBlock -Path $_.Fullname -Unit $($PSBoundParameters['Unit']))]" } -AutoSize -GroupBy @{Name = "Path"; Expression = { $_.Parent } }
            }
        }
    }
    END {
        Write-Verbose -Message "Ending $($MyInvocation.MyCommand)"
    }
}
