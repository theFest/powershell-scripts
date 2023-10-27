Function Rename-FilesBatch {
    <#
    .SYNOPSIS
    Rename your data.
    
    .DESCRIPTION
    Simple function for renaming files, folders, extensions and more.
    
    .PARAMETER FilesPath
    Mandatory - location of your data.  
    .PARAMETER RenameFiles
    NotMandatory - batch of files to be renamed.
    .PARAMETER ReplaceStringIn
    NotMandatory - declare string that you want to be removed.  
    .PARAMETER ReplaceStringOut
    NotMandatory - declare string that you want to be added.
    .PARAMETER AddNewPrefix
    NotMandatory - declare prefix string that you want to be added. 
    .PARAMETER AddNewSuffix
    NotMandatory - declare suffix string that you want to be added.  
    .PARAMETER Substring
    NotMandatory - define substring that you want to be removed.  
    .PARAMETER PSIsContainer
    NotMandatory - rename either files or folders with this switch.  
    .PARAMETER Methods
    NotMandatory - currently use available methods to upper/lower case your files. 
    .PARAMETER ReplaceExtensionTo
    NotMandatory - choose extension that you wish to replace.  
    .PARAMETER Manage
    Mandatory - choose operation that you want to use.
    .PARAMETER Recurse
    NotMandatory - include subdirectories.
    .PARAMETER Force
    NotMandatory - force to override.
    .PARAMETER OutputToFile
    NotMandatory - if you want result to be written to file, use this switch together with Outfile. 
    .PARAMETER OutFile
    NotMandatory - define location where your output file will be populated and resides.
    
    .EXAMPLE
    Rename-FilesBatch -FilesPath 'F:\Test\a' -Manage RenameWithIndex -RenameFiles test ##-->RenameFiles
    Rename-FilesBatch -FilesPath 'F:\Test\a' -Manage ChangeExtension -ReplaceExtensionTo .csv ##-->ChangeExtension
    Rename-FilesBatch -FilesPath 'F:\Test\a' -Manage ReplaceString -ReplaceStringIn 'test_' -ReplaceStringOut 'demo_' ##-->ReplaceString
    Rename-FilesBatch -FilesPath 'F:\Test\a' -Manage SetNewPrefixSuffix -AddNewPrefix YYYYY -AddNewSuffix ZZZZZ ##-->SetNewPrefixSuffix
    Rename-FilesBatch -FilesPath 'F:\Test\a' -Manage MethodOptions -Methods ToLower ##-->MethodOptions
    Rename-FilesBatch -FilesPath 'F:\Test\a' -Manage SubString -Substring 1 ##-->SubString

    .NOTES
    v0.1.1
    #>
    [CmdletBinding()]
    param(
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
        [ValidateSet('ToLower', 'ToUpper')]
        [string]$Methods,

        [Parameter(Mandatory = $false)]
        [ValidateSet('.ps1', '.txt', '.csv', '.ini', '.json', '.exe', '.xml', '.jpg', '.msu', '.log', '.bin')]
        [string]$ReplaceExtensionTo,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateSet('RenameWithIndex', 'ChangeExtension', 'ReplaceString', 'MethodOptions', 'SubString', 'SetNewPrefixSuffix')]
        [string]$Manage,

        [Parameter(Mandatory = $false)]
        [switch]$Recurse,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$OutputToFile,

        [Parameter(Mandatory = $false)]
        [string]$OutFile
    )
    $FilesPathLocation = [System.IO.Path]::GetDirectoryName($FilesPath)
    Set-Location -Path $FilesPathLocation
    $Files = Get-ChildItem -Path $FilesPath -Recurse:$Recurse -Force:$Force | Where-Object { $_.PSIsContainer -eq $PSIsContainer }
    #$Files = Get-ChildItem -Path $FilesPath -File:$FilesOnly -Filter $Filter -Include $Include -Exclude $Exclude -ReadOnly:$ReadOnly -Hidden:$Hidden -System:$System -Recurse:$Recurse -Depth $Depth | Where-Object { $_.PSIsContainer -eq $PSIsContainer }
    switch ($Manage) {
        'RenameWithIndex' {
            $WO = Write-Output "`nTotal : "$Files.Count "Files renamed to; $RenameFiles`n"
            $AddExtension = $Files.Extension | Select-Object -First 1
            $F = $Files.FullName | ForEach-Object -Begin { $Count = 1 } -Process { Rename-Item $_ -NewName $RenameFiles$Count$AddExtension -PassThru -Verbose; $Count++ } -End { Tee-Object -InputObject $WO -Variable 'RenamedFiles' | Out-Null }
        }
        'ChangeExtension' {
            $WO = Write-Output "`nTotal : "$Files.Count "Files have changed extension to; $ReplaceExtensionTo`n"
            $F = $Files.FullName | ForEach-Object -Process { Rename-Item $_ -NewName ([System.IO.Path]::ChangeExtension($_, "$ReplaceExtensionTo")) -PassThru -Verbose } -End { Tee-Object -InputObject $WO -Variable 'RenamedFiles' | Out-Null }
        }
        'ReplaceString' {
            $WO = Write-Output "`nTotal : "$Files.Count "Files that have replaced string; $ReplaceStringIn>>$ReplaceStringOut`n"
            $F = $Files.FullName | ForEach-Object -Process { Rename-Item $_ -NewName $_.Replace("$ReplaceStringIn", "$ReplaceStringOut") -PassThru -Verbose } -End { Tee-Object -InputObject $WO -Variable 'RenamedFiles' | Out-Null }
        }
        'SetNewPrefixSuffix' {
            $WO = Write-Output "`nTotal : "$Files.Count "Files that changed Prefix;$AddNewPrefix and/or suffix; $AddNewSuffix`n"
            $F = $Files | ForEach-Object -Process { Rename-Item -Path $_ -NewName "$AddNewPrefix$($_.BaseName)$AddNewSuffix$($_.Extension)" -PassThru -Verbose } -End { Tee-Object -InputObject $WO -Variable 'RenamedFiles' | Out-Null }
        }
        'MethodOptions' {
            $WO = Write-Output "`nTotal : "$Files.Count "Files that changed method; $Methods`n"
            $F = $Files | Rename-Item -NewName { $_.BaseName.$Methods() + $_.Extension } -PassThru -Verbose
            Tee-Object -InputObject $WO -Variable 'RenamedFiles' | Out-Null
        }
        'SubString' {
            $WO = Write-Output "`nTotal : "$Files.Count "Files that have added substring; $Substring`n"
            $F = $Files | Rename-Item -NewName { $_.BaseName.Substring($Substring) + $_.Extension } -PassThru -Verbose
            Tee-Object -InputObject $WO -Variable 'RenamedFiles' | Out-Null
        }
    }
    Write-Host $RenamedFiles
    if ($OutputToFile.IsPresent) {
        $F | Select-Object FullName, CreationTime, LastAccessTime, LastWriteTime, Attributes, Extension, Exists `
        | Format-Table | Out-File $OutFile
    }
}