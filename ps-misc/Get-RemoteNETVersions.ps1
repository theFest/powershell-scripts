Function Get-RemoteNETVersions {
    <#
    .SYNOPSIS
    Retrieves information about installed .NET Framework versions on a local or remote computer.

    .DESCRIPTION
    This function retrieves information about installed .NET Framework versions on a local or remote computer, pt provides details such as version number, release key, release name, and registry path.

    .PARAMETER IncludeLegacyVersions
    Specifies whether to include legacy versions(4-digit versions) in the results.
    .PARAMETER Include64BitVersions
    Specifies whether to include 64-bit versions in the results.
    .PARAMETER SortByVersionDescending
    Specifies whether to sort the results by version number in descending order.
    .PARAMETER ComputerName
    Specifies the name of the remote computer, connects remotely to retrieve information.
    .PARAMETER User
    Specifies the username for authenticating to the remote computer.
    .PARAMETER Pass
    Specifies the password for authenticating to the remote computer.

    .EXAMPLE
    Get-RemoteNETVersions -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$IncludeLegacyVersions,

        [Parameter(Mandatory = $false)]
        [switch]$Include64BitVersions,

        [Parameter(Mandatory = $false)]
        [switch]$SortByVersionDescending,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Pass
    )
    BEGIN {
        if ($ComputerName) {
            Write-Verbose -Message "Connecting to remote computer: $ComputerName"
            $PingResult = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
            if (!$PingResult) {
                Write-Warning -Message "Cannot reach remote computer: $ComputerName"
                return
            }
        }
        else {
            Write-Verbose -Message "Running locally"
        }
    }
    PROCESS {
        if ($ComputerName) {
            $Credential = New-Object System.Management.Automation.PSCredential($User, (ConvertTo-SecureString -String $Pass -AsPlainText -Force))
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
            $ScriptBlock = {
                param ($IncludeLegacy, $Include64Bit, $SortDescending)
                Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse |
                Get-ItemProperty -Name Version -ErrorAction SilentlyContinue |
                Where-Object {
                    $_.Version -match "^\d+\.\d+" -and
                    ($IncludeLegacy -or $_.PSChildName -match '^\d{4}$') -and
                    ($Include64Bit -or $_.PSChildName -notmatch 'Wow6432Node')
                } | Sort-Object Version -Descending
            }
            $InstalledVersions = Invoke-Command -Session $Session -ScriptBlock $ScriptBlock -ArgumentList $IncludeLegacyVersions, $Include64BitVersions, $SortByVersionDescending
        }
        else {
            $InstalledVersions = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse |
            Get-ItemProperty -Name Version -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Version -match "^\d+\.\d+" -and
                                    ($IncludeLegacyVersions -or $_.PSChildName -match '^\d{4}$') -and
                                    ($Include64BitVersions -or $_.PSChildName -notmatch 'Wow6432Node')
            } | Sort-Object Version -Descending
        }
        if ($InstalledVersions) {
            $Table = $InstalledVersions | ForEach-Object {
                $VersionInfo = $_
                $ReleaseKey = ($VersionInfo.PSPath -split '\\')[-1]
                $ReleaseName = (Get-ItemProperty -Path $VersionInfo.PSPath -Name Release -ErrorAction SilentlyContinue).Release
                [PSCustomObject]@{
                    Version      = $VersionInfo.Version
                    ReleaseKey   = $ReleaseKey
                    ReleaseName  = $ReleaseName
                    RegistryPath = $VersionInfo.PSPath
                }
            }
            $TotalCount = $Table.Count
            Write-Host "Total .NET Framework versions found: $TotalCount" -ForegroundColor DarkGreen
            $Table | Format-Table -AutoSize -Wrap
        }
        else {
            Write-Warning -Message "No .NET Framework versions are installed!"
        }
    }
    END {
        if ($Session) {
            Remove-PSSession $Session -Verbose
        }
        Write-Verbose -Message "Completed .NET Framework version retrieval"
    }
}
