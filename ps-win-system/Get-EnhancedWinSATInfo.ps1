function Get-EnhancedWinSATInfo {
    <#
    .SYNOPSIS
    Retrieves and displays the Windows System Assessment Tool (WinSAT) scores for a specified computer.

    .DESCRIPTION
    This function connects to a specified computer, retrieves the WinSAT scores, and displays them. It can be used on the local machine or a remote machine with provided credentials. Optionally, the results can be exported to a CSV file.

    .EXAMPLE
    Get-EnhancedWinSATInfo -IncludeTimestamp -Detailed -Verbose
    "remote_host" | Get-EnhancedWinSATInfo -User "remote_user" -Pass "remote_pass" -IncludeTimestamp

    .NOTES
    v0.3.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, HelpMessage = "Name of the computer to retrieve the WinSAT scores from, defaults to the local computer")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Username to use for remote authentication, required for remote execution")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password to use for remote authentication, required for remote execution")]
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "File path to export the WinSAT scores to, defaults to the desktop of the current user")]
        [string]$ExportPath = "$env:USERPROFILE\Desktop\WinSAT_Scores.csv",

        [Parameter(Mandatory = $false, HelpMessage = "Include detailed WinSAT information in the output")]
        [switch]$Detailed,

        [Parameter(Mandatory = $false, HelpMessage = "Include a timestamp in the output and export data")]
        [switch]$IncludeTimestamp
    )
    try {
        if ($ComputerName -eq $env:COMPUTERNAME -and -not $User) {
            $WinSAT = Get-CimInstance -ClassName Win32_WinSAT
        }
        else {
            if (-not $User -or -not $Pass) {
                throw "User and Pass parameters are required for remote execution!"
            }
            $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Cred = New-Object System.Management.Automation.PSCredential ($User, $SecurePassword)
            $Options = New-CimSessionOption -Protocol Dcom
            $Session = New-CimSession -ComputerName $ComputerName -Credential $Cred -SessionOption $Options -ErrorAction Stop
            $WinSAT = Get-CimInstance -ClassName Win32_WinSAT -CimSession $Session
        }
        $WinSATData = [PSCustomObject]@{
            ComputerName  = $ComputerName
            CPUScore      = $WinSAT.CPUScore
            D3DScore      = $WinSAT.D3DScore
            DiskScore     = $WinSAT.DiskScore
            GraphicsScore = $WinSAT.GraphicsScore
            MemoryScore   = $WinSAT.MemoryScore
            TotalScore    = $WinSAT.WinSPRLevel
        }
        if ($IncludeTimestamp) {
            $WinSATData | Add-Member -MemberType NoteProperty -Name Timestamp -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        Write-Host "WinSAT Scores for $ComputerName :" -ForegroundColor Cyan
        $WinSATData | Format-Table -AutoSize
        if ($Detailed) {
            Write-Host "Detailed WinSAT Information:" -ForegroundColor Yellow
            Write-Output -InputObject $WinSAT
        }
        if ($ExportPath) {
            $WinSATData | Export-Csv -Path $ExportPath -NoTypeInformation -Force -Verbose
            Write-Host "WinSAT scores exported to $ExportPath" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
    }
    finally {
        if ($Session) {
            Remove-CimSession -CimSession $Session -Verbose
        }
    }
}
