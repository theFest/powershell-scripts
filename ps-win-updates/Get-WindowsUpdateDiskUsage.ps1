function Get-WindowsUpdateDiskUsage {
    <#
    .SYNOPSIS
    Retrieves disk usage statistics related to Windows Updates, including total space used by Windows updates.

    .DESCRIPTION
    This function calculates the total disk space used by Windows updates on a specified drive, can be run on both local and remote systems. For remote systems, the function accepts credentials to securely retrieve the information and provides details such as total drive size, free space, space used by Windows updates, and space used excluding the Windows updates.

    .EXAMPLE
    Get-WindowsUpdateDiskUsage
    Get-WindowsUpdateDiskUsage -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.1.0
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
    if ($DriveLetter.Length -ne 1 -or $DriveLetter -notmatch '^[A-Za-z]$') {
        Write-Error -Message "Invalid Drive Letter. Please specify a single letter (e.g., C)."
        return
    }
    $WindowsUpdatePath = Join-Path -Path $env:SystemRoot -ChildPath 'SoftwareDistribution\Download'
    try {
        if ($ComputerName -ne $env:COMPUTERNAME) {
            if (-not $User -or -not $Pass) {
                Write-Error -Message "Username and Password are required for remote access."
                return
            }
            $SecPass = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ($User, $SecPass)
            $UsedSpaceGB = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                param($Path)
                if (Test-Path -Path $Path) {
                    $TotalSize = Get-ChildItem -Path $Path -Recurse -File | Measure-Object -Property Length -Sum
                    return [math]::Round($TotalSize.Sum / 1GB, 2)
                }
                return 0
            } -ArgumentList $WindowsUpdatePath -ErrorAction Stop
        }
        else {
            if (Test-Path -Path $WindowsUpdatePath) {
                $TotalSize = Get-ChildItem -Path $WindowsUpdatePath -Recurse -File | Measure-Object -Property Length -Sum
                $UsedSpaceGB = [math]::Round($TotalSize.Sum / 1GB, 2)
            }
            else {
                $UsedSpaceGB = 0
            }
        }
        $Volume = Get-Volume -DriveLetter $DriveLetter -ErrorAction Stop
        $TotalSizeGB = [math]::Round($Volume.Size / 1GB, 2)
        $TotalFreeSpaceGB = [math]::Round($Volume.SizeRemaining / 1GB, 2)
        $UsedSpaceExcludingUpdatesGB = [math]::Round(($TotalSizeGB - $TotalFreeSpaceGB - $UsedSpaceGB), 2)
        Write-Host "Drive Letter: $DriveLetter" -ForegroundColor Yellow
        Write-Host "Total Size of Drive: ${TotalSizeGB}GB" -ForegroundColor DarkYellow
        Write-Host "Total Free Space on Drive: ${TotalFreeSpaceGB}GB" -ForegroundColor DarkCyan
        Write-Host "Used Space for Windows Updates: ${UsedSpaceGB}GB" -ForegroundColor Green
        Write-Host "Used Space (excluding Windows Updates): ${UsedSpaceExcludingUpdatesGB}GB" -ForegroundColor Gray
    }
    catch {
        Write-Error -Message "Error: $($_.Exception.Message)"
    }
}
