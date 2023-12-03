Function Rename-AndExportFiles {
    <#
    .SYNOPSIS
    Renames, formats, and exports file properties information.

    .DESCRIPTION
    This function renames files, formats output, and performs other relevant file operations.

    .PARAMETER FilesPath
    Mandatory - Path of the folder that contains the files to be processed.
    .PARAMETER FileExtension
    Not Mandatory - Extension of the files to be processed. If not specified, all files in the folder will be processed.
    .PARAMETER RenameStringIn
    Not Mandatory - A string to search for in file names and replace with the value of the RenameStringOut parameter if found.
    .PARAMETER RenameStringOut
    Not Mandatory - The string to replace RenameStringIn if found in file names.
    .PARAMETER CSVFormat
    Not Mandatory - If present, the list of files will be written to the output file in CSV format.
    .PARAMETER OutFile
    Mandatory - Name of the file to which the list of files will be written.
    .PARAMETER IncludeSubdirectories
    Not Mandatory - If present, include files from subdirectories.
    .PARAMETER AppendToOutput
    Not Mandatory - If present, append to the output file.
    .PARAMETER SkipExistingFiles
    Not Mandatory - If present, skip renaming files if the new name already exists.
    .PARAMETER LogActions
    Not Mandatory - If present, log renaming actions to a log file.
    .PARAMETER LogFilePath
    Not Mandatory - Path to the log file if logging is enabled.

    .EXAMPLE
    Rename-AndExportFiles -FilesPath "C:\Windows" -OutFile "C:\Temp\results.csv" -CSVFormat -IncludeSubdirectories -LogActions -LogFilePath "C:\Temp\rename_log.txt"

    .NOTES
    Version: 0.3.3
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilesPath,

        [Parameter(Mandatory = $false)]
        [string]$FileExtension = $null,

        [Parameter(Mandatory = $false)]
        [string]$RenameStringIn = $null,

        [Parameter(Mandatory = $false)]
        [string]$RenameStringOut = $null,

        [Parameter(Mandatory = $false)]
        [switch]$CSVFormat,

        [Parameter(Mandatory = $true)]
        [string]$OutFile,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSubdirectories,

        [Parameter(Mandatory = $false)]
        [switch]$AppendToOutput,

        [Parameter(Mandatory = $false)]
        [switch]$SkipExistingFiles,

        [Parameter(Mandatory = $false)]
        [switch]$LogActions,

        [Parameter(Mandatory = $false)]
        [string]$LogFilePath
    )
    try {
        if (!(Test-Path -Path $FilesPath -PathType Container)) {
            throw "The specified folder does not exist!"
        }
        $Filter = "*.*"
        if ($FileExtension) {
            $Filter = "*.$FileExtension"
        }
        $Files = Get-ChildItem -Path $FilesPath -File -Recurse:$IncludeSubdirectories -Filter $Filter
        if ($Files.Count -eq 0) {
            throw "No files found with the specified extension!"
        }
        $LogEntries = @()
        foreach ($File in $Files) {
            if ($RenameStringIn) {
                $NewName = $File.Name -replace $RenameStringIn, $RenameStringOut
                if ($NewName -ne $File.Name) {
                    if (($SkipExistingFiles) -and (Test-Path (Join-Path $File.DirectoryName $NewName))) {
                        if ($LogActions -and $LogFilePath) {
                            $LogEntries += "Skipped renaming $($File.FullName) to $($NewName) (File already exists)."
                        }
                    }
                    else {
                        Rename-Item -Path $File.FullName -NewName $NewName -Force -Verbose
                        if ($LogActions -and $LogFilePath) {
                            $LogEntries += "Renamed $($file.FullName) to $($NewName)."
                        }
                    }
                }
            }
            if ($CSVFormat) {
                $File | Export-Csv -Path $OutFile -NoTypeInformation -Append:$AppendToOutput -Force
            }
            else {
                $File.Name | Out-File -FilePath $OutFile -Append:$AppendToOutput -Force
            }
        }
        if ($LogActions -and $LogFilePath -and $LogEntries.Count -gt 0) {
            $LogEntries | Out-File -FilePath $LogFilePath -Append -Force
        }
    }
    catch {
        Write-Error -Message $_
    }
}
