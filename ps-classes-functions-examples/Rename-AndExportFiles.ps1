Function Rename-AndExportFiles {
    <#
    .SYNOPSIS
    Rename and optionally export files based on specified criteria.
    
    .DESCRIPTION
    This function renames files based on provided criteria like file extension, strings in the file names, and date attributes. It also optionally exports file details to an output file.
    
    .PARAMETER FilesPath
    Mandatory - the path to the folder containing the files to be processed.
    .PARAMETER FileExtension
    Not Mandatory - specifies the file extension to filter files.
    .PARAMETER RenameStringIn
    Not Mandatory - the string to find in file names.
    .PARAMETER RenameStringOut
    Not Mandatory - the string to replace in file names.
    .PARAMETER ExportFileDetails
    Not Mandatory - export file details to the output file.
    .PARAMETER OutFile
    Mandatory - specifies the output file path.
    .PARAMETER IncludeSubdirectories
    Not Mandatory - include subdirectories in the search.
    .PARAMETER AppendToOutput
    Not Mandatory - append to the output file if it exists.
    .PARAMETER SkipExistingFiles
    Not Mandatory - skip renaming if the file with the new name already exists.
    .PARAMETER LogActions
    Not Mandatory - switch to enable logging actions.
    .PARAMETER LogFilePath
    Not Mandatory - specifies the log file path.
    .PARAMETER MinimumFileSize
    Not Mandatory - specifies the minimum file size.
    .PARAMETER CreatedAfter
    Not Mandatory - specifies the minimum creation date for files.
    .PARAMETER ModifiedAfter
    Not Mandatory - specifies the minimum modification date for files.
    .PARAMETER CreateBackup
    Not Mandatory - switch to create a backup of renamed files.
    .PARAMETER LogLevel
    Not Mandatory - log level (Info, Warning, Error).

    .EXAMPLE
    Rename-AndExportFiles -FilesPath "C:\Data" -FileExtension "txt" -RenameStringIn "_old" -RenameStringOut "_new" -ExportFileDetails -OutFile "C:\Output\output.csv" -LogActions -LogFilePath "C:\Logs\log.txt"

    .NOTES
    v0.3.4
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Provide the path to the folder")]
        [ValidateScript({
                if (-not (Test-Path -Path $_ -PathType Container)) {
                    throw "The specified folder does not exist: $_"
                }
                $true
            })]
        [string]$FilesPath,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the file extension")]
        [ValidateNotNullOrEmpty()]
        [string]$FileExtension,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the string to find in file names")]
        [string]$RenameStringIn,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the string to replace in file names")]
        [string]$RenameStringOut,

        [Parameter(Mandatory = $false, HelpMessage = "Export details of files to the output file")]
        [switch]$ExportFileDetails,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the output file")]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,

        [Parameter(Mandatory = $false, HelpMessage = "Include subdirectories in the search")]
        [switch]$IncludeSubdirectories,

        [Parameter(Mandatory = $false, HelpMessage = "Append to the output file if it already exists")]
        [switch]$AppendToOutput,

        [Parameter(Mandatory = $false, HelpMessage = "Skip renaming if the file with the new name already exists")]
        [switch]$SkipExistingFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Enable logging actions")]
        [switch]$LogActions,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the log file path")]
        [string]$LogFilePath,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the minimum file size")]
        [ValidateRange(0, [int]::MaxValue)]
        [int]$MinimumFileSize,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the minimum creation date")]
        [ValidateScript({
                if ($_ -is [datetime] -and $_ -gt (Get-Date)) {
                    throw "The date should be in the past."
                }
                $true
            })]
        [datetime]$CreatedAfter,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the minimum modification date")]
        [ValidateScript({
                if ($_ -is [datetime] -and $_ -gt (Get-Date)) {
                    throw "The date should be in the past."
                }
                $true
            })]
        [datetime]$ModifiedAfter,

        [Parameter(Mandatory = $false, HelpMessage = "Create a backup of renamed files")]
        [switch]$CreateBackup,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the log level")]
        [ValidateSet("Info", "Warning", "Error")]
        [string]$LogLevel = "Info"
    )
    try {
        $Filter = "*.*"
        if ($FileExtension) {
            $Filter = "*.$FileExtension"
        }
        $Files = Get-ChildItem -Path $FilesPath -File -Recurse:$IncludeSubdirectories -Filter $Filter |
        Where-Object {
                     (!$MinimumFileSize -or $_.Length -ge $MinimumFileSize) -and
                     (!$CreatedAfter -or $_.CreationTime -ge $CreatedAfter) -and
                     (!$ModifiedAfter -or $_.LastWriteTime -ge $ModifiedAfter)
        }
        if ($Files.Count -eq 0) {
            throw "No files found with the specified criteria in: $FilesPath"
        }
        $LogEntries = @()
        foreach ($File in $Files) {
            if ($RenameStringIn) {
                $NewName = $File.Name -replace $RenameStringIn, $RenameStringOut
                if ($NewName -ne $File.Name) {
                    if ($SkipExistingFiles -and (Test-Path (Join-Path $File.DirectoryName $NewName))) {
                        $LogEntries += "Skipped renaming $($File.FullName) to $($NewName) (File already exists)."
                        continue
                    }
                    else {
                        if ($CreateBackup) {
                            $BackupPath = Join-Path $File.DirectoryName "Backup_$($File.Name)"
                            Copy-Item -Path $File.FullName -Destination $BackupPath -Verbose
                        }
                        Rename-Item -Path $File.FullName -NewName $NewName -Force -Verbose
                        $LogEntries += "Renamed $($File.FullName) to $($NewName)."
                    }
                }
            }
            if ($ExportFileDetails) {
                $File | Select-Object FullName, Name, Directory, Length, CreationTime, LastWriteTime | Export-Csv -Path $OutFile -NoTypeInformation -Append:$AppendToOutput -Force
            }
            else {
                $File.Name | Out-File -FilePath $OutFile -Append:$AppendToOutput -Force
            }
        }
        if ($LogActions -and $LogFilePath -and $LogEntries.Count -gt 0) {
            $LogEntries | ForEach-Object { "[$(Get-Date)] [$LogLevel] $_" } | Out-File -FilePath $LogFilePath -Append -Force
        }
    }
    catch {
        Write-Error -Message "Error: $_"
    }
}
