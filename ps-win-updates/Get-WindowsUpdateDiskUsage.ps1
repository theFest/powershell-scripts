Function Get-WindowsUpdateDiskUsage {
    <#
    .SYNOPSIS
    Gets disk usage information, including space used by Windows Updates.

    .DESCRIPTION
    This function retrieves information about the disk space on a specified drive, including the space used by Windows Updates in the 'SoftwareDistribution\Download' directory.

    .PARAMETER DriveLetter
    Drive letter for which disk usage information is to be retrieved.
    .PARAMETER ComputerName
    Name of the remote computer, if specified, the function retrieves disk usage information from the specified remote computer.
    .PARAMETER User
    Specifies the username for authentication on the remote computer.
    .PARAMETER Pass
    Specifies the password for authentication on the remote computer.

    .EXAMPLE
    Get-WindowsUpdateDiskUsage
    Get-WindowsUpdateDiskUsage -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$DriveLetter = "C",

        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Pass
    )
    try {
        $WindowsUpdatePath = Join-Path -Path $env:SystemRoot -ChildPath 'SoftwareDistribution\Download'
        if ($ComputerName -ne $env:COMPUTERNAME) {
            $SecPass = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ($User, $SecPass)
            $UsedSpaceGB = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                param($Path)
                if (Test-Path -Path $Path) {
                    $TotalSize = Get-ChildItem -Path $Path -Recurse -File | Measure-Object -Property Length -Sum
                    $TotalSize.Sum / 1GB
                }
                else {
                    0
                }
            } -ArgumentList $WindowsUpdatePath -ErrorAction Stop
        }
        else {
            if (Test-Path -Path $WindowsUpdatePath) {
                $TotalSize = Get-ChildItem -Path $WindowsUpdatePath -Recurse -File | Measure-Object -Property Length -Sum
                $UsedSpaceGB = $TotalSize.Sum / 1GB
            }
            else {
                $UsedSpaceGB = 0
            }
        }
        $Volume = Get-Volume -DriveLetter $DriveLetter -ErrorAction Stop
        $TotalFreeSpaceGB = [math]::Round($Volume.SizeRemaining / 1GB, 2)
        Write-Host "Total Free Space on Drive $DriveLetter : ${TotalFreeSpaceGB}GB"
        Write-Host "Used Space for Windows Updates: ${UsedSpaceGB}GB"
        Write-Host "Used Space (excluding Windows Updates): $([math]::Round(($Volume.Size - $Volume.SizeRemaining - $UsedSpaceGB), 2))GB"
    }
    catch {
        Write-Error -Message "Error: $($_.Exception.Message)"
    }
}
