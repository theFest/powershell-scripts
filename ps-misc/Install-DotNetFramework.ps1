Function Install-DotNetFramework {
    <#
    .SYNOPSIS
    Installs a specified version of the .NET Framework.

    .DESCRIPTION
    This function allows you to install a specific version of the .NET Framework on a Windows machine. It provides options to control the installation behavior, such as quiet mode, restart options, and passive mode.

    .PARAMETER DotNetVersion
    Specifies the version of the .NET Framework to install.
    Valid values are:
    - '4.8.1 (Developer Pack)'
    - '4.8.1'
    - '4.8 (Developer Pack)'
    - '4.8'
    - '4.7.2 (Developer Pack)'
    - '4.7.2'
    - '4.7.1 (Developer Pack)'
    - '4.7.1'
    - '4.7 (Developer Pack)'
    - '4.7'
    - '4.6.2 (Developer Pack)'
    - '4.6.2'
    - '4.6.1 (Developer Pack)'
    - '4.6.1'
    - '4.6 (Developer Pack)'
    - '4.6'
    - '4.5.2 (Developer Pack)'
    - '4.5.2'
    - '4.5.1 (Developer Pack)'
    - '4.5.1'
    - '4.5'
    - '4.0'
    - '3.5 SP1'
    .PARAMETER Quiet
    Installation should be performed silently without user interaction.
    .PARAMETER PromptRestart
    Prompt the user for a restart after the installation is complete.
    .PARAMETER NoRestart
    Specifies that no restart should occur after the installation.
    .PARAMETER Passive
    Installation is passive, displaying progress but requiring no user interaction.

    .EXAMPLE
    Install-DotNetFramework -DotNetVersion '4.8.1' -Quiet -NoRestart
    
    .NOTES
    v0.0.1
    **https://dotnet.microsoft.com/en-us/download/dotnet
    **https://learn.microsoft.com/en-us/dotnet/framework/migration-guide/versions-and-dependencies
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            '4.8.1 (Developer Pack)', '4.8.1',
            '4.8 (Developer Pack)', '4.8',
            '4.7.2 (Developer Pack)', '4.7.2',
            '4.7.1 (Developer Pack)', '4.7.1',
            '4.7 (Developer Pack)', '4.7',
            '4.6.2 (Developer Pack)', '4.6.2',
            '4.6.1 (Developer Pack)', '4.6.1',
            '4.6 (Developer Pack)', '4.6',
            '4.5.2 (Developer Pack)', '4.5.2',
            '4.5.1 (Developer Pack)', '4.5.1',
            '4.5', '4.0', '3.5 SP1'
        )]
        [string]$DotNetVersion,

        [Parameter(Mandatory = $false)]
        [switch]$Quiet,

        [Parameter(Mandatory = $false)]
        [switch]$PromptRestart,

        [Parameter(Mandatory = $false)]
        [switch]$NoRestart,

        [Parameter(Mandatory = $false)]
        [switch]$Passive
    )
    BEGIN {
        $DotNetVersions = @{
            '4.8.1 (Developer Pack)' = 'https://go.microsoft.com/fwlink/?linkid=2203306'
            '4.8.1'                  = 'https://go.microsoft.com/fwlink/?linkid=2203305'
            '4.8 (Developer Pack)'   = 'https://go.microsoft.com/fwlink/?linkid=2088517'
            '4.8'                    = 'https://go.microsoft.com/fwlink/?linkid=2088631'
            '4.7.2 (Developer Pack)' = 'https://go.microsoft.com/fwlink/?linkid=874338'
            '4.7.2'                  = 'https://go.microsoft.com/fwlink/?LinkID=863265'
            '4.7.1 (Developer Pack)' = 'https://go.microsoft.com/fwlink/?linkid=2099382'
            '4.7.1'                  = 'https://go.microsoft.com/fwlink/?LinkID=2099383'
            '4.7 (Developer Pack)'   = 'https://go.microsoft.com/fwlink/?linkid=2099465'
            '4.7'                    = 'https://go.microsoft.com/fwlink/?LinkId=2099385'
            '4.6.2 (Developer Pack)' = 'https://go.microsoft.com/fwlink/?linkid=2099466'
            '4.6.2'                  = 'https://go.microsoft.com/fwlink/?linkid=2099468'
            '4.6.1 (Developer Pack)' = 'https://go.microsoft.com/fwlink/?linkid=2099470'
            '4.6.1'                  = 'https://go.microsoft.com/fwlink/?LinkId=671728'
            '4.6 (Developer Pack)'   = 'https://go.microsoft.com/fwlink/?linkid=2099469'
            '4.6'                    = 'https://go.microsoft.com/fwlink/?LinkId=2099384'
            '4.5.2 (Developer Pack)' = 'https://go.microsoft.com/fwlink/?linkid=397673&clcid=0x409'
            '4.5.2'                  = 'https://go.microsoft.com/fwlink/?LinkId=397708'
            '4.5.1 (Developer Pack)' = 'https://go.microsoft.com/fwlink/?linkid=321335&clcid=0x409'
            '4.5.1'                  = 'https://go.microsoft.com/fwlink/?LinkId=322116'
            '4.5'                    = 'https://download.microsoft.com/download/B/A/4/BA4A7E71-2906-4B2D-A0E1-80CF16844F5F/dotNetFx45_Full_setup.exe'
            '4.0'                    = 'https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe'
            '3.5 SP1'                = 'https://go.microsoft.com/fwlink/?linkid=2186537'
        }
        if (-not $DotNetVersions.ContainsKey($DotNetVersion)) {
            Write-Error "Invalid .NET Framework version. Please choose a valid version."
            return
        }
        $DownloadLink = $DotNetVersions[$DotNetVersion]
        Write-Host "Selected .NET Framework version: $DotNetVersion"
        Write-Host "Download link: $DownloadLink" -ForegroundColor DarkCyan
    }
    PROCESS {
        $InstallerPath = Join-Path $env:TEMP "$DotNetVersion.exe"
        Invoke-WebRequest -Uri $DownloadLink -OutFile $InstallerPath -UseBasicParsing
        $Arguments = @()
        if ($Quiet) {
            $Arguments += "/q"
        }
        if ($PromptRestart) {
            $Arguments += "/promptrestart"
        }
        if ($NoRestart) {
            $Arguments += "/norestart"
        }
        if ($Passive) {
            $Arguments += "/passive"
        }
        $InstallCommand = "Start-Process -FilePath $InstallerPath -ArgumentList $($Arguments -join ' ') -Wait"
        Write-Host "Installing .NET Framework $DotNetVersion..."
        Invoke-Expression -Command $InstallCommand
    }
    END {
        Write-Host ".NET Framework $DotNetVersion has been successfully installed." -ForegroundColor Green
        Remove-Item -Path $InstallerPath -Force -Verbose
    }
}
