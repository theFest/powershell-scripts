Function Find-ZeroLengthFiles {
    <#
    .SYNOPSIS
    Retrieves information about zero-length files in a specified directory.

    .DESCRIPTION
    This function searches for zero-length files in the specified directory and provides details such as file path, size, creation date, and last modified date.

    .PARAMETER Path
    Path of the directory to search for zero-length files.
    .PARAMETER Recurse
    Indicates whether to search for zero-length files recursively within subdirectories.

    .EXAMPLE
    Find-ZeroLengthFiles -Path "$env:SystemDrive\Temp" -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    [Alias("Zombie-Files")]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript( { 
                Test-Path -Path $_
            })]
        [string]$Path,

        [Parameter(Mandatory = $false, Position = 1)]
        [switch]$Recurse
    )
    BEGIN {
        Write-Verbose -Message "Starting $($MyInvocation.MyCommand)"
        $Get = "Name", "CreationDate", "LastModified", "FileSize"
        $CimParams = @{
            Classname   = "CIM_DATAFILE"
            Property    = $Get
            ErrorAction = "Stop"
            Filter      = ""
        }
    }
    PROCESS {
        Write-Verbose -Message "Using specified path $Path"
        if ((Get-Item -Path $Path).Target) {
            $Target = (Get-Item -Path $Path).Target
            Write-Verbose -Message "Reparse point was detected pointing towards $Target"
            $Path = $Target
        }
        Write-Verbose -Message "Converting $Path"
        $CPath = Convert-Path -Path $Path
        Write-Verbose -Message "Converted to $CPath"
        if ($CPath.Length -gt 3 -AND $CPath -match "\\$") {
            $CPath = $CPath -replace "\\$", ""
        }
        $Drive = $CPath.Substring(0, 2)
        Write-Verbose -Message "Using Drive $Drive..."
        $Folder = $CPath.Substring($CPath.IndexOf("\")).replace("\", "\\")
        Write-Verbose -Message "Using folder $Folder (escaped)"
        if ($Folder -match "\w+" -AND $PSBoundParameters.ContainsKey("Recurse")) {
            $Filter = "Drive='$Drive' AND Path LIKE '$Folder\\%' AND FileSize=0"
        }
        elseif ($Folder -match "\w+") {
            $Filter = "Drive='$Drive' AND Path='$Folder\\' AND FileSize=0"
        }
        else {
            $Filter = "Drive='$Drive' AND Path LIKE '\\%' AND FileSize=0"
        }
        $CimParams.Filter = $Filter
        Write-Verbose -Message "Looking for zero length files with filter $Filter"
        $i = 0
        try {
            Write-Host "Searching for zero length files in $CPath, this might take a few minutes..." -ForegroundColor Gray
            Get-CimInstance @CimParams | ForEach-Object {
                $i++
                [PSCustomObject]@{
                    PSTypeName   = "cimZeroLengthFile"
                    Path         = $_.Name
                    Size         = $_.FileSize
                    Created      = $_.CreationDate
                    LastModified = $_.LastModified
                }
            }
        }
        catch {
            Write-Warning -Message "Failed to run query! $($_.Exception.Message)"
        }
        if ($i -eq 0) {
            Write-Host "No zero length files were found in $CPath" -ForegroundColor Yellow
        }
        else {
            Write-Host "Found $i matching files" -ForegroundColor Green
        }
    }
    END {
        Write-Verbose -Message "Ending $($MyInvocation.MyCommand)"
    }
}
