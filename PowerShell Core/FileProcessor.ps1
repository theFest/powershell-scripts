Class FileProcessor {
    [string]$FilesPath
    [string]$FileExtension
    [string]$OutFile
    [string]$RenameStringIn
    [string]$RenameStringOut
    [switch]$CSVFormat
    FileProcessor(
        [string]$FilesPath,
        [string]$FileExtension,
        [string]$OutFile) {
        $this.FilesPath = $FilesPath
        $this.FileExtension = $FileExtension
        $this.OutFile = $OutFile
    }
    [void]ProcessFiles() {
        try {
            if (!(Test-Path -Path $this.FilesPath)) {
                throw "The specified folder does not exist"
            }
            $Files = Get-ChildItem -Path $this.FilesPath
            if ($this.FileExtension) {
                $Files = $Files | Where-Object { $_.Extension -eq ".$this.FileExtension" }
                if (!$Files) {
                    throw "No files found with the specified extension"
                }
            }
            if ($this.RenameStringIn) {
                $Files | Rename-Item -NewName { $_.Name -replace $this.RenameStringIn, $this.RenameStringOut }
            }
            if ($this.CSVFormat) {
                $Files | Export-Csv $this.OutFile -NoTypeInformation -Verbose
            }
            else {
                ($Files).Name | Out-File $this.OutFile -Verbose
            }
        }
        catch {
            Write-Error -Message $_
        }
    }
}

function FilesProcessor {
    <#
    .SYNOPSIS
    Used for renaming, formating,, output and other relevant file properties information.
    
    .DESCRIPTION
    Class based function that creates an instance of the FileProcessor class and assigns the input parameters to the class properties for use in the ProcessFiles method.
    
    .PARAMETER FilesPath
    Mandatory - path of the folder that contains the files to be listed.
    .PARAMETER FileExtension
    NotMandatory - extension of the files to be listed. If not specified, all files in the folder will be listed.
    .PARAMETER RenameStringIn
    NotMandatory - string that will be searched for in the file names, and replaced with the value of the RenameStringOut parameter if found.
    .PARAMETER RenameStringOut
    NotMandatory - will replace the RenameStringIn string if found in the file names.
    .PARAMETER CSVFormat
    NotMandatory - ist of files will be written to the output file in CSV format.
    .PARAMETER OutFile
    Mandatory - name of the file to which the list of files will be written.
    
    .EXAMPLE
    ListFiles -FilesPath C:\Windows -Outfile C:\Temp\results.txt -CSVFormat
    
    .NOTES
    v0.3.1
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
        [string]$OutFile
    )
    $fileProcessor = [FileProcessor]::new($FilesPath, $FileExtension, $OutFile)
    $fileProcessor.RenameStringIn = $RenameStringIn
    $fileProcessor.RenameStringOut = $RenameStringOut
    $fileProcessor.CSVFormat = $CSVFormat
    $fileProcessor.ProcessFiles()
}