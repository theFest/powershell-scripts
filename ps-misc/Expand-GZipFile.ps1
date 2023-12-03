Function Expand-GZipFile {
    <#
    .SYNOPSIS
    Decompresses a GZip file.

    .DESCRIPTION
    This function decompresses a GZip file to a specified location.

    .PARAMETER InputFile
    Mandatory - specifies the path to the input GZip file.
    .PARAMETER OutputFile
    Mandatory - the path for the output file after decompression.
    .PARAMETER Overwrite
    NotMandatory - indicates whether to overwrite an existing output file.

    .EXAMPLE
    Expand-GZipFile -InputFile "C:\Files\InputFile.gz" -OutputFile "C:\Files\OutputFile.exe"

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
        [switch]$Overwrite
    )
    try {
        if (-not $Overwrite -and (Test-Path -Path $OutputFile -PathType Leaf)) {
            throw "Output file already exists. To overwrite, use -Overwrite switch!"
        }
        Write-Host "Expanding $($InputFile) to $($OutputFile)" -ForegroundColor Cyan
        $InputStream = New-Object IO.FileStream($InputFile, [IO.FileMode]::Open, [IO.FileAccess]::Read)
        $OutputStream = New-Object IO.FileStream($OutputFile, [IO.FileMode]::Create, [IO.FileAccess]::Write)
        $GzipStream = New-Object System.IO.Compression.GZipStream($InputStream, [IO.Compression.CompressionMode]::Decompress)
        $Buffer = New-Object byte[](4096)
        $TotalBytes = 0
        $BytesRead = 0
        do {
            $BytesRead = $GzipStream.Read($Buffer, 0, $Buffer.Length)
            $TotalBytes += $BytesRead
            $OutputStream.Write($Buffer, 0, $BytesRead)
        } while ($BytesRead -gt 0)
        Write-Host "Expanded $($TotalBytes) bytes." -ForegroundColor DarkGreen
        $GzipStream.Dispose()
        $OutputStream.Dispose()
        $InputStream.Dispose()
    }
    catch {
        Write-Error -Message "Error: $_"
    }
}
