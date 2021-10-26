Function ListFiles {
    <#
    .SYNOPSIS
    List folder contents and outputs to a file.
    
    .DESCRIPTION
    List folder contents and outputs to a file with options such as replace and substring.
    
    .PARAMETER FilesPath
    Mandatory - path of the folder that contents you would with to list to a file.
    .PARAMETER Manage
    Mandatory - change option like mentioned in examples.   
    .PARAMETER ReplaceStringIn
    NotMandatory - choose string you would wish replaced.  
    .PARAMETER ReplaceStringOut
    NotMandatory - choose string you would wish to replace with.   
    .PARAMETER Substring
    NotMandatory - remove 'n' number of characters from start of the string.    
    .PARAMETER OutFile
    Mandatory - specify where you would with for a file to reside.
    
    .EXAMPLES 
    ## ListFiles
    ListFiles -FilesPath 'F:\Test' -Manage ListFiles -OutFile 'F:\Test\Test.txt'
    ## WithoutExtensionReplaceString
    ListFiles -FilesPath 'F:\Test' -Manage WEReplaceString -ReplaceStringIn 'panel_' -OutFile 'F:\Test\Test.txt'
    ## WithoutExtensionReplaceStringSubString
    ListFiles -FilesPath 'F:\Test' -Manage WEReplaceStringSubString -ReplaceStringIn 'panel_' -Substring 3 -OutFile 'F:\Test\Test.txt'
    
    .NOTES
    V1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilesPath,

        [Parameter(Mandatory = $false)]
        [string]$ReplaceStringIn = $null,

        [Parameter(Mandatory = $false)]
        [string]$ReplaceStringOut = $null,

        [Parameter(Mandatory = $false)]
        [int]$Substring,

        [Parameter(Mandatory = $false)]
        [ValidateSet('ListFiles', 'WEReplaceString', 'WEReplaceStringSubString')]
        [string]$Manage = 'ListFiles',

        [Parameter(Mandatory = $true)]
        [string]$OutFile
    )
    BEGIN {
        Set-Location -Path $FilesPath
        $Files = Get-ChildItem -Path $FilesPath | Where-Object { $_.PSIsContainer -eq $false }
    }
    PROCESS {
        ForEach ($File in $Files) {
            switch ($Manage) {
                'ListFiles' {
                    $F = $Files.Name | Out-File $OutFile
                }
                'WEReplaceString' {
                    $F = $Files.BaseName
                    $S = ($F).Replace("$ReplaceStringIn", "$ReplaceStringOut") | Out-File $OutFile
                }
                'WEReplaceStringSubString' {
                    $F = $Files.BaseName
                    $S = ($F).Replace("$ReplaceStringIn", "$ReplaceStringOut")
                    $S.Substring("$Substring") | Out-File $OutFile
                }
            }
        }
    }
    END {
        Write-Output "`nTotal : "$Files.Count "Files written to:$OutFile, replaced string:$ReplaceStringIn>$ReplaceStringOut, substring count:$Substring `n"
    }
}