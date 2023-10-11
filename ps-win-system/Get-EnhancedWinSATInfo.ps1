Function Get-EnhancedWinSATInfo {
    <#
    .SYNOPSIS
    Retrieve and analyze Windows System Assessment Tool (WinSAT) scores with enhanced features.

    .DESCRIPTION
    This function retrieves and analyzes WinSAT scores for various components of a computer's performance.
    It provides the option to export the data to a CSV file, and it can display detailed information if needed.

    .PARAMETER ComputerName
    Specifies the name of the remote computer to analyze. Default is localhost.
    .PARAMETER Username
    Specifies the username for authentication on the remote computer.
    .PARAMETER Password
    Specifies the password for authentication on the remote computer.
    .PARAMETER ExportPath
    Path to export WinSAT scores as a CSV file. Default is "$env:USERPROFILE\Desktop\WinSAT_Scores.csv".
    .PARAMETER Detailed
    Display detailed WinSAT information.

    .EXAMPLE
    Get-EnhancedWinSATInfo -ComputerName "remote_computer" -Username "remote_user" -Password "remote_pass" -ExportPath "C:\Temp\WinSAT_Scores.csv" -Detailed

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $true)]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [string]$Password,

        [Parameter(Mandatory = $false)]
        [string]$ExportPath = "$env:USERPROFILE\Desktop\WinSAT_Scores.csv",

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    try {
        $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        $Cred = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
        $Options = New-CimSessionOption -Protocol Dcom
        $Session = New-CimSession -ComputerName $ComputerName -Credential $Cred -SessionOption $Options -ErrorAction Stop
        $WinSAT = Get-CimInstance -ClassName Win32_WinSAT -CimSession $Session
        $WinSATData = @{
            ComputerName    = $ComputerName
            CPUScore        = $WinSAT.CPUScore
            D3DScore        = $WinSAT.D3DScore
            DiskScore       = $WinSAT.DiskScore
            GraphicsScore   = $WinSAT.GraphicsScore
            MemoryScore     = $WinSAT.MemoryScore
            TotalScore      = $WinSAT.WinSPRLevel
        }
        Write-Host "WinSAT Scores for $ComputerName :"
        $WinSATData | Format-Table -AutoSize
        if ($Detailed) {
            Write-Host "Detailed WinSAT Information:" -ForegroundColor Yellow
            Write-Output -InputObject $WinSAT
        }
        if ($ExportPath) {
            $WinSATData | Export-Csv -Path $ExportPath -NoTypeInformation -Verbose
            Write-Host "WinSAT scores exported to $ExportPath"
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