Function ListFiles {
    <#
    .SYNOPSIS
    List folder contents and outputs to a file with additional functionalities. 

    .DESCRIPTION
    List folder contents and outputs to a file with options such as replace, substring, filter by file extension, exclude specific files by name and more.

    .PARAMETER FilesPath
    Mandatory - path of the folder that contents you would like to list to a file.
    .PARAMETER ReplaceStringIn
    NotMandatory - choose string you would wish replaced. 
    .PARAMETER ReplaceStringOut
    NotMandatory - choose string you would wish to replace with.   
    .PARAMETER Substring
    NotMandatory - remove 'n' number of characters from start of the string. 
    .PARAMETER Manage
    Mandatory - change option like mentioned in examples. 
    .PARAMETER OutFile
    Mandatory - specify where you would like for a file to reside.
    .PARAMETER IncludeExtension
    NotMandatory - which when set to true, includes the file extension in the output file, if not set, the file extension will not be included in the output file.
    .PARAMETER AppendToFile
    NotMandatory - switch statement, which if set to true, appends the output to an existing file instead of overwriting it. If not set, output will overwrite the existing file.
    .PARAMETER FileExtension
    NotMandatory - allows you to filter files in the specified directory by file extension, it is not mandatory and if no extension is provided, all files in the directory will be processed.
    .PARAMETER ExcludeFiles
    NotMandatory - array of strings that allows you to specify the names of files that should be excluded from the output. If no files are provided, all files will be processed.

    .EXAMPLE
    ListFiles -FilesPath 'C:\Test' -Manage ListFiles -OutFile 'C:\Test\Test.txt' ##-->ListFiles
    ListFiles -FilesPath 'C:\Test' -Manage ReplaceString -ReplaceStringIn 'panel_' -ReplaceStringOut 'new_panel_' -OutFile 'C:\Test\Test.txt' -IncludeExtension -AppendToFile
    ListFiles -FilesPath 'C:\Test' -Manage ReplaceStringSubString -ReplaceStringIn 'panel_' -ReplaceStringOut 'new_panel_' -Substring 3 -OutFile 'C:\Test\Test.txt' -IncludeExtension -AppendToFile -FileExtension 'txt' -ExcludeFiles 'file1.txt','file2.txt'

    .NOTES
    v1.3.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet('ListFiles', 'ReplaceString', 'ReplaceStringSubString')]
        [string]$Manage = 'ListFiles',

        [Parameter(Mandatory = $true)]
        [string]$FilesPath,

        [Parameter(Mandatory = $false)]
        [string]$ReplaceStringIn = $null,

        [Parameter(Mandatory = $false)]
        [string]$ReplaceStringOut = $null,

        [Parameter(Mandatory = $false)]
        [int]$Substring,

        [Parameter(Mandatory = $true)]
        [string]$OutFile,
    
        [Parameter(Mandatory = $false)]
        [switch]$IncludeExtension,
    
        [Parameter(Mandatory = $false)]
        [switch]$AppendToFile,
    
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' })]
        [string]$FileExtension,
    
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeFiles
    )
    BEGIN {
        Set-Location -Path $FilesPath -Verbose
    }
    PROCESS {
        $Files = Get-ChildItem -Path $FilesPath
        if ($FileExtension) {
            $Files = $Files | Where-Object { $_.Extension -eq ".$FileExtension" }
        }
        if ($ExcludeFiles) {
            $Files = $Files | Where-Object { $ExcludeFiles -notcontains $_.Name }
        }
        if (!$Files) {
            Write-Error "No files found with the specified extension"
            return
        }
        if ($AppendToFile) {
            $OutOption = '-Append'
        }
        else {
            $OutOption = '-NoClobber'
        }
        ForEach ($File in $Files) {
            switch ($Manage) {
                'ListFiles' {
                    $F = $File.Name | Out-File $OutFile $OutOption
                }
                'ReplaceString' {
                    $F = $File.BaseName
                    $S = ($F).Replace("$ReplaceStringIn", "$ReplaceStringOut") 
                    if ($IncludeExtension) {
                        $S += $File.Extension
                    }
                    $S | Out-File $OutFile $OutOption
                }
                'ReplaceStringSubString' {
                    $F = $File.BaseName
                    $S = ($F).Replace("$ReplaceStringIn", "$ReplaceStringOut")
                    $S = $S.Substring($Substring)
                    if ($IncludeExtension) {
                        $S += $File.Extension
                    }
                    $S | Out-File $OutFile $OutOption
                }
            }
        }
    }
    END {
        Write-Output "nTotal : "$Files.Count "Files written to:$OutFile, replaced string:$ReplaceStringIn>$ReplaceStringOut, substring count:$Substring, file extension filter:$FileExtension, excluded files:$ExcludeFilesn"
    }
}
