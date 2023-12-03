Function Rename-FilesBatch {
    <#
    .SYNOPSIS
    Rename files based on various options.

    .DESCRIPTION
    This function renames files based on the specified management option. Options include renaming with an index, changing file extensions, replacing strings, adding prefixes or suffixes, modifying case, and extracting substrings.

    .PARAMETER FilesPath
    Mandatory - the path of the files to be processed.
    .PARAMETER RenameFiles
    NotMandatory - new name for files when using the 'RenameWithIndex' option.
    .PARAMETER ReplaceStringIn
    NotMandatory - string to be replaced when using the 'ReplaceString' option.
    .PARAMETER ReplaceStringOut
    NotMandatory - string to replace with when using the 'ReplaceString' option.
    .PARAMETER AddNewPrefix
    NotMandatory - prefix to be added when using the 'SetNewPrefixSuffix' option.
    .PARAMETER AddNewSuffix
    NotMandatory - suffix to be added when using the 'SetNewPrefixSuffix' option.
    .PARAMETER Substring
    NotMandatory - number of characters to extract when using the 'SubString' option.
    .PARAMETER PSIsContainer
    NotMandatory - indicates whether to process container items.
    .PARAMETER Methods
    NotMandatory - case modification method ('ToLower' or 'ToUpper') when using the 'MethodOptions' option.
    .PARAMETER ReplaceExtensionTo
    NotMandatory - the new file extension when using the 'ChangeExtension' option.
    .PARAMETER Manage
    Mandatory - specifies the management option. Valid options are 'RenameWithIndex', 'ChangeExtension', 'ReplaceString', 'MethodOptions', 'SubString', and 'SetNewPrefixSuffix'.
    .PARAMETER Recurse
    NotMandatory - indicates whether to include subdirectories.
    .PARAMETER Force
    NotMandatory - forces the operation to proceed without prompting for confirmation.
    .PARAMETER OutFile
    NotMandatory - specifies the output file for detailed information.

    .EXAMPLE
    Rename-FilesBatch -FilesPath "C:\MyFiles" -RenameFiles "File" -Manage RenameWithIndex -Recurse -Force
    Rename-FilesBatch -FilesPath "C:\MyFiles" -ReplaceStringIn "Old" -ReplaceStringOut "New" -Manage ReplaceString -Recurse

    .NOTES
    v0.1.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$FilesPath,

        [Parameter(Mandatory = $false)]
        [string]$RenameFiles,

        [Parameter(Mandatory = $false)]
        [string]$ReplaceStringIn,

        [Parameter(Mandatory = $false)]
        [string]$ReplaceStringOut,

        [Parameter(Mandatory = $false)]
        [string]$AddNewPrefix,

        [Parameter(Mandatory = $false)]
        [string]$AddNewSuffix,

        [Parameter(Mandatory = $false)]
        [int]$Substring = $null,

        [Parameter(Mandatory = $false)]
        [switch]$PSIsContainer,

        [Parameter(Mandatory = $false)]
        [ValidateSet("ToLower", "ToUpper")]
        [string]$Methods,

        [Parameter(Mandatory = $false)]
        [ValidateSet(".ps1", ".txt", ".csv", ".ini", ".json", ".exe", ".xml", ".jpg", ".msu", ".log", ".bin")]
        [string]$ReplaceExtensionTo,

        [Parameter(Mandatory = $true)]
        [ValidateSet("RenameWithIndex", "ChangeExtension", "ReplaceString", "MethodOptions", "SubString", "SetNewPrefixSuffix")]
        [string]$Manage,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [string]$OutFile
    )
    $FilesPathLocation = [System.IO.Path]::GetDirectoryName($FilesPath)
    Set-Location -Path $FilesPathLocation -Verbose
    $Files = Get-ChildItem -Path $FilesPath -Recurse:$Recurse -Force:$Force | Where-Object { $_.PSIsContainer -eq $PSIsContainer }
    $RenamedFiles = switch ($Manage) {
        "RenameWithIndex" {
            Write-Output "`nTotal : $($Files.Count) Files renamed to; $RenameFiles`n"
            $Files | ForEach-Object -Process {
                $NewName = "{0}{1}{2}" -f $RenameFiles, $_.BaseName, $_.Extension
                $_ | Rename-Item -NewName $NewName -PassThru -Verbose
            } -End { Out-Null }
        }
        "ChangeExtension" {
            Write-Output "`nTotal : $($Files.Count) Files have changed extension to; $ReplaceExtensionTo`n"
            $Files | ForEach-Object -Process {
                $_ | Rename-Item -NewName ([System.IO.Path]::ChangeExtension($_.FullName, "$ReplaceExtensionTo")) -PassThru -Verbose
            } -End { Out-Null }
        }
        "ReplaceString" {
            Write-Output "`nTotal : $($Files.Count) Files that have replaced string; $ReplaceStringIn>>$ReplaceStringOut`n"
            $Files | ForEach-Object -Process {
                $NewName = $_.Name.Replace("$ReplaceStringIn", "$ReplaceStringOut")
                $_ | Rename-Item -NewName $NewName -PassThru -Verbose
            } -End { Out-Null }
        }
        "SetNewPrefixSuffix" {
            Write-Output "`nTotal : $($Files.Count) Files that changed Prefix;$AddNewPrefix and/or suffix; $AddNewSuffix`n"
            $Files | ForEach-Object -Process {
                $NewName = "{0}{1}{2}{3}" -f $AddNewPrefix, $_.BaseName, $AddNewSuffix, $_.Extension
                $_ | Rename-Item -NewName $NewName -PassThru -Verbose
            } -End { Out-Null }
        }
        "MethodOptions" {
            Write-Output "`nTotal : $($Files.Count) Files that changed method; $Methods`n"
            $Files | ForEach-Object -Process {
                $newName = switch ($Methods) {
                    "ToLower" { $_.BaseName.ToLower() + $_.Extension }
                    "ToUpper" { $_.BaseName.ToUpper() + $_.Extension }
                }
                $_ | Rename-Item -NewName $newName -PassThru -Verbose
            } -End { Out-Null }
        }
        "SubString" {
            Write-Output "`nTotal : $($Files.Count) Files that have added substring; $Substring`n"
            $Files | ForEach-Object -Process {
                $NewName = "{0}{1}{2}" -f $_.BaseName.Substring(0, $Substring), $_.Extension
                $_ | Rename-Item -NewName $NewName -PassThru -Verbose
            } -End { Out-Null }
        }
    }
    return $RenamedFiles
    if ($OutFile) {
        $Files | Select-Object FullName, CreationTime, LastAccessTime, LastWriteTime, Attributes, Extension, Exists |
        Format-Table | Out-File $OutFile
    }
}
