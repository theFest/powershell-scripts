Function Invoke-IsoExtraction {
    <#
    .SYNOPSIS
    Function that extracts ISO's contents.
    
    .DESCRIPTION
    Also downloads and installs 7Zip client if version not match, if other version is found, version 19 will replace older one, and extract ISO contents.
    
    .PARAMETER ISOImage
    Mandatory - path of an ISO image's. Location can be declared with this parametar.
    .PARAMETER ISOExpandPath
    Mandatory - path on a system drive where you want your extracted contents.
    .PARAMETER CheckIntegrity
    NotMandatory - switch for integrity check which is done before extracting image's.
    
    .EXAMPLE
    Invoke-IsoExtraction -ISOImage "$env:TEMP\YourImage.iso" -ISOExpandPath "$env:TEMP\MyImage"
    Invoke-IsoExtraction -ISOImage "$env:TEMP\YourImage.iso" -ISOExpandPath "$env:TEMP\MyImage" -CheckIntegrity
    
    .NOTES
    v0.1.1
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ISOImage,

        [Parameter(Mandatory = $true)]
        [string]$ISOExpandPath,

        [Parameter(Mandatory = $false)]
        [switch]$CheckIntegrity
    )
    BEGIN {
        $StartTime = Get-Date
        Write-Verbose -Message "Checking if 7-Zip is already installed"
        $7Zip = Get-Package -Provider Programs -IncludeWindowsInstaller -Name "7-Zip*" -AllVersions -ErrorAction SilentlyContinue
        if (!$7Zip) {
            Write-Verbose -Message "Download and install 7-Zip if it's not already installed"
            Write-Output "7-Zip is not installed. Downloading and installing 7-Zip."
            $7zURL = "https://www.7-zip.org/a/7z1900-x64.exe"
            $7zInstaller = "$env:TEMP\7z1900-x64.exe"
            Invoke-WebRequest -Uri $7zURL -OutFile $7zInstaller -Verbose
            Start-Process $7zInstaller -ArgumentList '/S /D="C:\Program Files\7-Zip"' -Wait -WindowStyle Hidden
        }
    }
    PROCESS {
        Write-Verbose -Message "Checking if the 7-Zip version is 19.00 or higher"
        if ($7Zip.Version -ge '19.00') {
            Write-Verbose -Message "Loop through each ISO image"
            foreach ($Image in $ISOImage) {
                Write-Verbose -Message "Determine the file name of the ISO image without its extension"
                $ISOExpandPathName = [System.IO.Path]::GetFileNameWithoutExtension($Image)
                Write-Verbose -Message "Check the integrity of the ISO image if requested"
                if ($CheckIntegrity) {
                    Write-Output "Checking the integrity of: $Image."
                    $7zPath = "$env:ProgramFiles\7-Zip\7z.exe"
                    $7zArgs = 't', $Image
                    Start-Process $7zPath -ArgumentList $7zArgs -Wait -WindowStyle Hidden
                }
                Write-Verbose -Message "Expand the ISO image"
                Write-Output "Extracting in progress: $Image."
                $7zPath = "$env:ProgramFiles\7-Zip\7z.exe"
                $7zArgs = 'x', '-y', "-o$ISOExpandPath\$ISOExpandPathName", $Image
                try {
                    Start-Process $7zPath -ArgumentList $7zArgs -Wait -WindowStyle Hidden -ErrorAction Stop
                }
                catch [System.IO.FileNotFoundException] {
                    Write-Host "An error occurred while starting the process: File not found"
                }
                catch [System.IO.IOException] {
                    Write-Host "An error occurred while starting the process: I/O error"
                }
                catch [System.OutOfMemoryException] {
                    Write-Host "An error occurred while starting the process: Out of memory"
                }
                catch [System.Security.SecurityException] {
                    Write-Host "An error occurred while starting the process: Security Exception"
                }
                catch {
                    Write-Host "An error occurred while starting the process: $_"
                }
            }
        }
        else {
            Write-Error -Message "7-Zip version is outdated. Version 19.00 or higher is required to extract ISO image."
        }
    }
    END {
        Write-Host "Total extract duration: $((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")" -ForegroundColor Cyan 
    }
}