function Use-RandomPasswordGenerator {
    <#
    .SYNOPSIS
    Downloads, extracts, and runs Sordum Random Password Generator to create secure random passwords.

    .DESCRIPTION
    Sordum Random Password Generator is a portable freeware tool to generate random, secure passwords. This function downloads, extracts, and runs the tool with optional password generation parameters.

    .EXAMPLE
    Use-RandomPasswordGenerator -StartApplication -Verbose
    Use-RandomPasswordGenerator -PasswordLength 20 -UseUppercase $false -UseNumbers $false

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "The length of the password to generate")]
        [int]$PasswordLength = 16,

        [Parameter(Mandatory = $false, HelpMessage = "Include uppercase letters in the password")]
        [bool]$UseUppercase = $true,

        [Parameter(Mandatory = $false, HelpMessage = "Include lowercase letters in the password")]
        [bool]$UseLowercase = $true,

        [Parameter(Mandatory = $false, HelpMessage = "Include numbers in the password")]
        [bool]$UseNumbers = $true,

        [Parameter(Mandatory = $false, HelpMessage = "Include special characters in the password")]
        [bool]$UseSpecialCharacters = $true,

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading Random Password Generator tool")]
        [uri]$DownloadUrl = "https://www.sordum.org/files/download/random-password-generator/RandomPW.zip",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where Random Password Generator tool will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\RandomPasswordGenerator",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveFiles,

        [Parameter(Mandatory = $false, HelpMessage = "Start the Random Password Generator application after extraction")]
        [switch]$StartApplication
    )
    $ZipFilePath = Join-Path $DownloadPath "RandomPW.zip"
    $ExtractPath = Join-Path $DownloadPath "RandomPW"
    $Executable = Join-Path $ExtractPath "RandomPW.exe"
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if (-not (Test-Path -Path $DownloadPath)) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        if (-not (Test-Path -Path $ZipFilePath)) {
            Write-Host "Downloading Random Password Generator tool..." -ForegroundColor Green
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $ZipFilePath -UseBasicParsing -Verbose
            if ((Get-Item $ZipFilePath).Length -eq 0) {
                throw "The downloaded ZIP file is empty or corrupt!"
            }
        }
        Write-Host "Extracting Random Password Generator tool..." -ForegroundColor Green
        if (Test-Path -Path $ExtractPath) {
            Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction Stop
        }
        try {
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFilePath, $DownloadPath)
        }
        catch {
            Write-Host "Extracting with Shell.Application..." -ForegroundColor Yellow
            $Shell = New-Object -ComObject Shell.Application
            $Zip = $Shell.NameSpace($ZipFilePath)
            $Destination = $Shell.NameSpace($DownloadPath)
            $Destination.CopyHere($Zip.Items(), 4)
        }
        Write-Host "Files in extraction directory:" -ForegroundColor Yellow
        Get-ChildItem -Path $DownloadPath -Recurse | ForEach-Object {
            Write-Host $_.FullName -ForegroundColor Yellow
        }
        if (-Not (Test-Path -Path $Executable)) {
            throw "Random Password Generator executable not found in $ExtractPath"
        }
        Write-Verbose -Message "Random Password Generator executable located at: $($Executable)"
        if ($StartApplication) {
            Write-Host "Starting Random Password Generator tool..." -ForegroundColor Green
            Start-Process -FilePath $Executable
        }
        else {
            Write-Host "Generating random password with specified parameters..." -ForegroundColor Green
            $cmdArguments = "-l $PasswordLength"
            if (-not $UseUppercase) { $cmdArguments += " -noupper" }
            if (-not $UseLowercase) { $cmdArguments += " -nolower" }
            if (-not $UseNumbers) { $cmdArguments += " -nonum" }
            if (-not $UseSpecialCharacters) { $cmdArguments += " -nospecial" }
            Start-Process -FilePath $Executable -ArgumentList $cmdArguments
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        Write-Host "Random Password Generator tool operation completed." -ForegroundColor Cyan
        if ($RemoveFiles) {
            Write-Warning -Message "Cleaning up, removing the temporary folder..."
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
    }
}
