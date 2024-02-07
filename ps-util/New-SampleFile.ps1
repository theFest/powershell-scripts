#Requires -Version 4.0
Function New-SampleFile {
    <#
    .SYNOPSIS
    Generates a new sample file with specified size and properties.

    .DESCRIPTION
    This function creates a new file with customizable size and properties. It allows you to specify the target path, filename, size, and other optional parameters.

    .PARAMETER Path
    Path where the file will be created, default is the current directory.
    .PARAMETER Filename
    The name of the file, if not provided, a random filename will be generated.
    .PARAMETER MaximumSize
    Maximum size of the file, you can include a unit (B, KB, MB, GB, TB), default is 100KB.
    .PARAMETER MinimumSize
    Specifies the minimum size allowed for the file, default is 5.
    .PARAMETER ExactSize
    Exact size for the file, overriding MaximumSize, must be greater than or equal to MinimumSize.
    .PARAMETER FileCount
    The number of files to be created, default is 1.
    .PARAMETER Force
    Forces the creation of the file, overwriting any existing file with the same name.
    .PARAMETER Passthru
    Returns the created file as output.
    .PARAMETER Compress
    Compresses the file into a ZIP archive.
    .PARAMETER VerboseOutput
    Enables verbose output for detailed information during file creation.
    .PARAMETER UseUtcTimestamp
    Appends a UTC timestamp to the filename for better versioning.
    .PARAMETER SizeUnit
    Specifies the unit for the file size (B, KB, MB, GB, TB), default is MB.

    .EXAMPLE
    New-SampleFile -Path "$env:USERPROFILE\Desktop" -Filename "example.txt" -MaximumSize "10 MB" -Force

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]$Path = ".",

        [Parameter(Mandatory = $false)]
        [string]$Filename = [System.IO.Path]::GetRandomFileName(),

        [Parameter(Mandatory = $false)]
        [ValidateNotNullorEmpty()]
        [string]$MaximumSize = "100KB",

        [Parameter(Mandatory = $false)]
        [decimal]$MinimumSize = 5,

        [Parameter(Mandatory = $false)]
        [ValidateScript({ $_ -gt $MinimumSize })]
        [decimal]$ExactSize,

        [Parameter(Mandatory = $false)]
        [ValidateScript({ $_ -ge 1 })]
        [int]$FileCount = 1,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$Passthru,

        [Parameter(Mandatory = $false)]
        [switch]$Compress,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseOutput,

        [Parameter(Mandatory = $false)]
        [switch]$UseUtcTimestamp,

        [Parameter(Mandatory = $false)]
        [ValidateSet("B", "KB", "MB", "GB", "TB")]
        [string]$SizeUnit = "MB"
    )
    BEGIN {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"
    }
    PROCESS {
        if ((Test-Path -Path $Path) -and ((Get-Item -Path $Path).PSIsContainer)) {
            for ($i = 0; $i -lt $FileCount; $i++) {
                $Output = Join-Path -Path (Convert-Path $Path) -ChildPath $Filename
                if ($FileCount -gt 1) {
                    $Output = "$Output$i"
                }
                if ($Force -and (Test-Path -Path $Output)) {
                    Write-Verbose -Message "Deleting existing file"
                    Remove-Item -Path $Output -Force -Verbose
                }
                if ($ExactSize -and !$Compress) {
                    $Size = $ExactSize
                }
                else {
                    $Split = $MaximumSize -split '\s+'
                    $Size = [decimal]$Split[0]
                    if ($Split.Length -gt 1) {
                        $SizeUnit = $Split[1]
                    }
                    else {
                        $SizeUnit = "B"
                    }
                }
                if ($UseUtcTimestamp) {
                    $Output = "$Output-$((Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss"))"
                }
                Write-Verbose -Message "Creating $Output with size $Size $SizeUnit"
                if ($PSCmdlet.ShouldProcess($Output)) {
                    try {
                        switch ($SizeUnit) {
                            "B" { $SizeInBytes = $Size }
                            "KB" { $SizeInBytes = [decimal]($Size * 1KB) }
                            "MB" { $SizeInBytes = [decimal]($Size * 1MB) }
                            "GB" { $SizeInBytes = [decimal]($Size * 1GB) }
                            "TB" { $SizeInBytes = [decimal]($Size * 1TB) }
                            default { throw "Invalid size unit: $SizeUnit" }
                        }
                        if ($Compress) {
                            $CompressedPath = $Output + ".zip"
                            Compress-Archive -Path (New-Object byte[] $SizeInBytes) -DestinationPath $CompressedPath -Force
                            Write-Verbose "File compressed: $CompressedPath"
                            if ($Passthru) {
                                Get-Item -Path $CompressedPath -Verbose
                            }
                        }
                        else {
                            $Stream = [System.IO.File]::Create($Output)
                            $Stream.SetLength($SizeInBytes)
                            $Stream.Close()
                            Write-Host "File created" -ForegroundColor Green
                            if ($Passthru) {
                                Get-Item -Path $Output -Verbose
                            }
                        }
                    }
                    catch {
                        Write-Warning -Message "Failed to create file: $_"
                    }
                }
            }
        }
        else {
            Write-Warning -Message "Could not verify $(Convert-path $Path) as a filesystem path or directory!"
        }
    }
    END {
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
    }
}
