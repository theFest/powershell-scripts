Function Compress-GZipFile {
    <#
    .SYNOPSIS
    Compresses a file using GZip compression.
    
    .DESCRIPTION
    This function compresses a specified file using GZip compression.

    .PARAMETER InputFile
    Mandatory - path to the input file to be compressed.
    .PARAMETER OutputFile
    Mandatory - specifies the path for the output compressed file.
    .PARAMETER LogFile
    NotMandatory - the path to the log file for recording compression status and errors.
    
    .EXAMPLE
    Compress-GZipFile -InputFile "C:\Path\To\Input\File.txt" -OutputFile "C:\Path\To\Output\File.gz" -LogFile "C:\Path\To\Log\log.txt"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InputFile,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $false)]
        [string]$LogFile
    )
    try {
        if (-not (Test-Path $InputFile -PathType Leaf)) {
            Write-Host "Error: Input file '$InputFile' not found!" -ForegroundColor DarkGray
            return
        }
        $InputStream = New-Object IO.FileStream(
            $InputFile,
            [IO.FileMode]::Open,
            [IO.FileAccess]::Read
        )
        $OutputStream = New-Object IO.FileStream(
            $OutputFile,
            [IO.FileMode]::Create,
            [IO.FileAccess]::Write
        )
        $GzipStream = New-Object System.IO.Compression.GZipStream(
            $OutputStream,
            [IO.Compression.CompressionMode]::Compress
        )
        $InputStream.CopyTo($GzipStream)
        $GzipStream.Dispose()
        $LogMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Compression successful for '$InputFile'."
        Add-Content -Path $LogFile -Value $LogMessage
        Write-Host $LogMessage
    }
    catch {
        $ErrorMessage = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Error: $_"
        Add-Content -Path $LogFile -Value $ErrorMessage
        Write-Host $ErrorMessage -ForegroundColor Red
    }
    finally {
        if ($InputStream) {
            $InputStream.Close() 
        }
        if ($OutputStream) {
            $OutputStream.Close() 
        }
        if ($GzipStream) { 
            $GzipStream.Close() 
        }
    }
}
