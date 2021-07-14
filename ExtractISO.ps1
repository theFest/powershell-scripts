Function ExtractISO {
    <#
    .SYNOPSIS
    This function extracts ISO contents to system drive.
    
    .DESCRIPTION
    This function not only extracts ISO contents, but also downloads and installs 7Zip client if version not match.
    If other version is found, version 19 will replace older one. Folder will be created where the ISO is located.
    
    .PARAMETER ISOImage
    Mandatory - path of an ISO image. Location can be declared with this parametar.
    .PARAMETER ISOExpandPath
    Mandatory - path on a system drive where you want your extracted contents.
    .PARAMETER ISOExpandPathName
    Mandatory - name of folder path on a system drive where you want your extracted contents.

    .EXAMPLE
    ExtractISO -ISOImage "$env:TEMP\Windows10.iso" -ISOExpandPath "$env:TEMP" --ISOExpandPathName 'MyImage'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]$ISOImage,

        [Parameter(Mandatory = $true)]
        [string]$ISOExpandPath,

        [Parameter(Mandatory = $false)]
        [string]$ISOExpandPathName
    )
    $7Zip = Get-Package -Provider Programs -IncludeWindowsInstaller -Name "7-Zip*" -AllVersions -ErrorAction SilentlyContinue
    $Install = {
        Write-Output "Downloading 7-Zip."
        $7zURL = "https://www.7-zip.org/a/7z1900-x64.exe"
        Invoke-WebRequest -Uri $7zURL -OutFile $env:APPDATA\BMX\7z1900-x64.exe -Verbose
        $Test7zPath = Test-Path -Path $env:APPDATA\BMX\7z1900-x64.exe
        if ($Test7zPath) {
            Write-Output "7-Zip is downloaded. Starting installation."
            Start-Process $env:APPDATA\BMX\7z1900-x64.exe -ArgumentList '/S /D="C:\Program Files\7-Zip"' -Wait -WindowStyle Hidden
        }    
    }
    $Expand = {
        Write-Output "7-Zip is already installed, extracting...please wait."
        $7zPath = "$env:ProgramFiles\7-Zip\7z.exe"
        $7zXArgs = 'x -y -o' + "$ISOExpandPath\$ISOExpandPathName $ISOImage"
        Start-Process -FilePath $7zPath -ArgumentList $7zXArgs -Wait -WindowStyle Hidden
    }
    New-Item -Path $ISOExpandPath -ItemType Directory -Name $ISOExpandPathName | Out-Null
    if (!$7Zip) {
        Invoke-Command -ScriptBlock $Install
        Invoke-Command -ScriptBlock $Expand
    }
    elseif ($7Zip.Version -ge '19.00') {
        Invoke-Command -ScriptBlock $Expand
    }
    else {
        Write-Error -Message "Unable to expand image '$ISOImage'. Error was: $_" -ErrorAction Stop
    }
}