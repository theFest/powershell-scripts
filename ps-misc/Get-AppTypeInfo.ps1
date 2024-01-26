Function Get-AppTypeInfo {
    <#
    .SYNOPSIS
    Retrieves information about different types of installed applications on the system.

    .DESCRIPTION
    This function that provides details about various types of installed applications on a Windows system.
    Supports multiple application types, such as InstalledApps, AppX packages, Start menu apps, SoftwarePackages, Win32Apps, and ChocolateyPackages.

    .PARAMETER AppType
    Specifies the type of applications to retrieve. Valid values include:
    - InstalledApps: Retrieves information using Get-WmiObject for installed programs.
    - AppX: Retrieves information about AppX packages using Get-AppxPackage.
    - GetStartApps: Retrieves information about Start menu apps using Get-StartApps.
    - SoftwarePackages: Retrieves information about package management packages using Get-Package.
    - Win32Apps: Retrieves information about Win32 apps using registry queries.
    - ChocolateyPackages: Retrieves information about Chocolatey packages using 'choco list'.
    .PARAMETER IncludeSystemApps
    Includes system applications in the results when specified.

    .EXAMPLE
    Get-AppTypeInfo -AppType InstalledApps
    Get-AppTypeInfo -AppType AppX
    Get-AppTypeInfo -AppType GetStartApps
    Get-AppTypeInfo -AppType SoftwarePackages
    Get-AppTypeInfo -AppType Win32Apps
    Get-AppTypeInfo -AppType ChocolateyPackages

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet("InstalledApps", "AppX", "GetStartApps", "SoftwarePackages", "Win32Apps", "ChocolateyPackages")] # PowerShellGet,WinGet
        [string]$AppType = "InstalledApps",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSystemApps
    )
    BEGIN {
        $StartTime = Get-Date
    }
    PROCESS {
        switch ($AppType) {
            "InstalledApps" {
                Write-Verbose -Message "Getting installed programs using Get-WmiObject, this can take time..."
                $InstalledApps = Get-WmiObject -Query "SELECT * FROM Win32_Product"
                $InstalledApps | Select-Object Name, Version
            }
            "AppX" {
                Write-Verbose -Message "Getting AppX packages using Get-AppxPackage..."
                $AppxPackages = Get-AppxPackage
                $AppxPackages | Select-Object Name, Version
            }
            "GetStartApps" {
                Write-Verbose -Message "Getting Start menu apps using Get-StartApps..."
                $StartApps = Get-StartApps
                $StartApps | Select-Object Name, AppID
            }
            "SoftwarePackages" {
                Write-Verbose -Message "Getting package management packages using Get-Package..."
                $SoftwarePackages = Get-Package
                $SoftwarePackages | Select-Object DisplayName, Version
            }
            "Win32Apps" {
                Write-Verbose -Message "Getting Win32 apps using Get-Package..."
                $Win32Apps = Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue
                $Win32Apps | Where-Object { $_.DisplayName } | Select-Object DisplayName, DisplayVersion
            }
            "ChocolateyPackages" {
                Write-Verbose "Checking for Chocolatey, getting packages using 'choco list'..."
                if (-not(Get-Command choco.exe -ErrorAction SilentlyContinue)) {
                    try {
                        Write-Verbose -Message "Installing Chocolatey, please wait..."
                        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
                    }
                    catch {
                        Write-Error -Message "Failed to install Chocolatey: $($_.Exception.Message)"
                        return
                    }
                }
                $ChocoListOutput = choco list 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $ChocoListOutput | ForEach-Object {
                        $Name, $Version = ($_ -split '\|', 2) -replace '\s+', ''
                        [PSCustomObject]@{
                            Name    = $Name
                            Version = $Version
                        }
                    }
                }
                else {
                    Write-Error -Message "Failed to retrieve Chocolatey packages! Error: $ChocoListOutput"
                }
            }
            default {
                Write-Warning -Message "Invalid AppType: $AppType. Please specify a valid app type!"
            }
        }
    }
    END {
        $EndTime = Get-Date ; $ElapsedTime = $EndTime - $StartTime
        Write-Host "Total execution time: $($ElapsedTime.TotalSeconds) seconds."
    }
}
