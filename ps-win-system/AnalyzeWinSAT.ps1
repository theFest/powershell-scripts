Function AnalyzeWinSAT {
    <#
    .SYNOPSIS
    Analyze Windows System Assessment Tool (WinSAT) scores.

    .DESCRIPTION
    This function retrieves WinSAT scores for various components of a computer's performance.

    .PARAMETER ComputerName
    NotMandatory - specifies the name of the remote computer to analyze, default is localhost.
    .PARAMETER Username
    NotMandatory - specifies the username for authentication on the remote computer.
    .PARAMETER Password
    NotMandatory - specifies the password for authentication on the remote computer.
    .PARAMETER ExportPath
    NotMandatory - path to export WinSAT scores as a CSV file.
    .PARAMETER Detailed
    NotMandatory - display detailed WinSAT information.

    .EXAMPLE
    AnalyzeWinSAT -ComputerName "remote_computer" -Username "remote_user" -Password "remote_pass" -ExportPath "C:\Temp\WinSAT_Scores.csv"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [string]$Pass,

        [Parameter(Mandatory = $false)]
        [string]$ExportPath = "$env:USERPROFILE\Desktop\WinSAT_Scores.txt",

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    $Cred = $null
    if ($Username -and $Pass) {
        $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
        $Cred = New-Object System.Management.Automation.PSCredential ($Username, $SecurePassword)
    }
    try {
        $Options = New-CimSessionOption -Protocol Dcom
        $Session = New-CimSession -ComputerName $ComputerName -Credential $Cred -SessionOption $Options -ErrorAction Stop
        $WinSAT = Get-CimInstance -ClassName Win32_WinSAT -CimSession $Session
        $Score = $WinSAT.CPUScore
        $D3dScore = $WinSAT.D3DScore
        $DiskScore = $WinSAT.DiskScore
        $GraphicsScore = $WinSAT.GraphicsScore
        $MemoryScore = $WinSAT.MemoryScore
        Write-Host "WinSAT Scores for $ComputerName :"
        Write-Host "CPU Score: $Score"
        Write-Host "D3D Score: $D3dScore"
        Write-Host "Disk Score: $DiskScore"
        Write-Host "Graphics Score: $GraphicsScore"
        Write-Host "Memory Score: $MemoryScore"
        if ($Detailed) {
            Write-Host "Detailed WinSAT Information:" -ForegroundColor Yellow
            Write-Output -InputObject $WinSAT
        }
        if ($ExportPath) {
            $CsvData = @{
                ComputerName  = $ComputerName
                CPUScore      = $Score
                D3DScore      = $D3dScore
                DiskScore     = $DiskScore
                GraphicsScore = $GraphicsScore
                MemoryScore   = $MemoryScore
            }
            $CsvData | Out-File -FilePath $ExportPath -Verbose
            Write-Host "WinSAT scores exported to $ExportPath"
        }
    }
    catch {
        Write-Host "An error occurred: $($_.Exception.Message)"
    }
    finally {
        if ($Session) {
            Remove-CimSession -CimSession $Session -Verbose
        }
    }
}
