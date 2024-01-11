Function Install-SysInternalsSuite {
    <#
    .SYNOPSIS
    Installs the SysInternals suite to a specified or default directory.

    .DESCRIPTION
    This function downloads the latest SysInternalsSuite and extracts its contents to the specified or default installation directory.
    It checks the version of each tool and updates if a newer version is available. Additionally, it adds the tools to the System Path if they are not already present.

    .PARAMETER InstallPath
    Specifies the installation path for the SysInternals suite, defaults to "$env:ProgramFiles\SysInternals" if not specified.

    .EXAMPLE
    Install-SysInternalsSuite -InstallPath "$env:ProgramFiles\SysInternals"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$InstallPath = "$env:ProgramFiles\SysInternals"
    )
    try {
        if (-not (Test-Path -Path $InstallPath -PathType Container)) {
            New-Item -ItemType Directory -Path $InstallPath -ErrorAction Stop | Out-Null
            Write-Host ("Specified installation path '{0}' not found, creating now...." -f $InstallPath) -ForegroundColor Green
        }
        else {
            Write-Host ("Specified installation path '{0}' found, continuing...." -f $InstallPath) -ForegroundColor Green
        }
        $TempPath = Join-Path -Path $env:TEMP -ChildPath 'SysInternalsSuite'
        if (Test-Path -Path $TempPath -PathType Container) {
            $DownloadedFilesCount = (Get-ChildItem -Path $TempPath -File).Count
            Write-Host ("Updated {0} files in '{1}' from the downloaded {2} files" -f $UpdatedFilesCount, $InstallPath, $DownloadedFilesCount) -ForegroundColor Green
        }
        else {
            Write-Host ("Updated {0} files in '{1}' from the downloaded {2} files" -f $UpdatedFilesCount, $InstallPath, 0) -ForegroundColor Green
        }
        $DownloadUrl = 'https://download.sysinternals.com/files/SysinternalsSuite.zip'
        $DownloadedZip = Join-Path -Path $env:TEMP -ChildPath 'SysInternalsSuite.zip'
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $DownloadedZip -ErrorAction Stop
        Write-Host ("Downloading latest version to '{0}\SysInternalsSuite.zip'" -f $env:TEMP) -ForegroundColor Green
        Expand-Archive -LiteralPath $DownloadedZip -DestinationPath $TempPath -Force -ErrorAction Stop
        Write-Host ("Extracting files to '{0}\SysInternalsSuite'" -f $env:TEMP) -ForegroundColor Green
        $UpdatedFilesCount = 0
        $ToolsPath = Join-Path -Path $InstallPath -ChildPath '*.*'
        foreach ($Tool in Get-ChildItem -Path $TempPath -File) {
            $DestinationFile = Join-Path -Path $InstallPath -ChildPath $Tool.Name
            if (Test-Path -Path $DestinationFile) {
                $CurrentVersion = (Get-Item $DestinationFile).VersionInfo
                $DownloadedVersion = (Get-Item $Tool.FullName).VersionInfo
                if ($CurrentVersion.ProductVersion -lt $DownloadedVersion.ProductVersion) {
                    Copy-Item -LiteralPath $Tool.FullName -Destination $DestinationFile -Force -ErrorAction Stop -Verbose
                    Write-Host ("- Updating '{0}' from version {1} to version {2}" -f $Tool.Name, $CurrentVersion.ProductVersion, $DownloadedVersion.ProductVersion) -ForegroundColor Green
                    $UpdatedFilesCount++
                }
            }
            else {
                Copy-Item -LiteralPath $Tool.FullName -Destination $DestinationFile -Force -ErrorAction Stop -Verbose
                Write-Host ("- Copying new file '{0}' to '{1}'" -f $Tool.Name, $InstallPath) -ForegroundColor Green
                $UpdatedFilesCount++
            }
        }
        $SystemPath = Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH
        $CurrentPath = $SystemPath.Path -split ';'
        foreach ($Tool in Get-ChildItem -Path $toolsPath -File) {
            $ToolFullPath = $Tool.FullName
            if ($CurrentPath -notcontains $ToolFullPath) {
                Write-Host ("Adding '{0}' to the System Path" -f $Tool.Name) -ForegroundColor Green
                $CurrentPath += @($ToolFullPath)
            }
            else {
                Write-Host ("'{0}' is already present in the System Path, skipping it..." -f $Tool.Name) -ForegroundColor Green
            }
        }
        Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value ($CurrentPath -join ';')
        Write-Host ("Updated {0} files in '{1}' from the downloaded {2} files" -f $UpdatedFilesCount, $InstallPath, (Get-ChildItem -Path $TempPath -File).Count) -ForegroundColor Green
        Remove-Item -Path $TempPath -Force -Recurse -ErrorAction SilentlyContinue -Verbose
        Remove-Item -Path $DownloadedZip -Force -ErrorAction SilentlyContinue -Verbose
    }
    catch {
        Write-Warning -Message "An error occurred: $_"
        return
    }
}
