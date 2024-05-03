Function Show-DirectoryInformation {
    <#
    .SYNOPSIS
    Retrieves information about directories, such as file count or total file size.

    .DESCRIPTION
    This function retrieves information about directories, allowing users to specify whether they want to display the count or size of files within those directories.
    It provides options to include subdirectories in the search and to specify the depth of subdirectory levels to include. Additionally, users can specify the unit of measurement for file size and provide credentials for accessing remote paths.

    .PARAMETER Path
    File system path of the directory for which information is to be retrieved.
    .PARAMETER InformationType
    Display the count or size of files, values are "Size" or "Count". Default is "Count".
    .PARAMETER Recurse
    Include subdirectories in the search. By default, only the specified directory is searched.
    .PARAMETER Depth
    Maximum number of subdirectory levels to include in the search.
    .PARAMETER Unit
    Unit of measurement for file size detail, values are "Bytes", "KB", "MB", or "GB". Default is "Bytes".
    .PARAMETER Credential
    Specifies credentials for accessing remote paths.

    .EXAMPLE
    Show-DirectoryInformation -Path $env:windir

    .NOTES
    v0.0.8
    #>
    [CmdletBinding()]
    [Alias("Show-DRInfo")]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Enter a file system path")]
        [Alias("p")]
        [string]$Path,

        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Specify whether to display Size or Count of files")]
        [ValidateSet("Size", "Count")]
        [Alias("i")]
        [string]$InformationType = "Count",

        [Parameter(Mandatory = $false, HelpMessage = "Include subdirectories in the search")]
        [Alias("rc")]
        [switch]$Recurse,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the depth of subdirectory levels to include")]
        [Alias("d")]
        [int32]$Depth,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the unit of measurement for Size detail (KB, MB, GB, Bytes)")]
        [Alias("u")]
        [ValidateSet("Bytes", "KB", "MB", "GB")]
        [string]$Unit = "Bytes",

        [Parameter(Mandatory = $false, HelpMessage = "Credentials for accessing remote paths")]
        [System.Management.Automation.Credential()]
        [System.Management.Automation.PSCredential]$Credential
    )
    BEGIN {
        try {
            $ResolvedPath = Resolve-Path -Path $Path -Credential $Credential -ErrorAction Stop
        }
        catch {
            Write-Error -Message "Failed to resolve the path: $_"
            return
        }
        if (-not (Test-Path -Path $ResolvedPath -PathType Container)) {
            Write-Error -Message "The specified path '$ResolvedPath' does not exist or is not a directory."
            return
        }
        if ($InformationType -eq 'Size' -and (-not $PSBoundParameters.ContainsKey("Unit"))) {
            $PSBoundParameters.Add("Unit", "Bytes")
        }
        $GciParams = @{
            Path      = $ResolvedPath
            Directory = $true
        }
        if ($Depth) {
            $GciParams.Add("Depth", $Depth)
        }
        if ($Recurse) {
            $GciParams.Add("Recurse", $Recurse)
        }
    }
    PROCESS {
        Write-Verbose -Message "Processing $($ResolvedPath.Path)"
        $Directories = Get-ChildItem @GciParams
        if ($InformationType -eq "Count") {
            Write-Verbose -Message "Getting file count..."
            $CountScriptBlock = {
                param($Directory)
                (Get-ChildItem -Path $Directory.FullName -File -ErrorAction SilentlyContinue).Count
            }
            $Directories | ForEach-Object {
                [PSCustomObject]@{
                    Directory = $_.FullName
                    Count     = &$CountScriptBlock -Directory $_
                }
            }
        }
        else {
            Write-Verbose -Message "Getting file size in $($PSBoundParameters['Unit']) units"
            $SizeScriptBlock = {
                param($Directory, $Unit)
                $FileSize = Get-ChildItem -Path $Directory.FullName -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
                switch ($Unit) {
                    "KB" { 
                        return [math]::Round($FileSize.Sum / 1KB, 2)
                    }
                    "MB" { 
                        return [math]::Round($FileSize.Sum / 1MB, 2)
                    }
                    "GB" { 
                        return [math]::Round($FileSize.Sum / 1GB, 2)
                    }
                    default { 
                        return $FileSize.Sum 
                    }
                }
            }
            $Directories | ForEach-Object {
                [PSCustomObject]@{
                    Directory = $_.FullName
                    Size      = &$SizeScriptBlock -Directory $_ -Unit $Unit
                }
            }
        }
    }
    END {
        Write-Verbose -Message "Ending $($MyInvocation.MyCommand)"
    }
}
