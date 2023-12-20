Function Send-LogsToFTP {
    <#
    .SYNOPSIS
    Sends log files from a specified folder to an FTP server.

    .DESCRIPTION
    This function uploads log files from a specified folder to an FTP server using WinSCP .NET assembly.

    .PARAMETER LogFolderPath
    Mandatory - path to the folder containing log files.
    .PARAMETER FtpHostName
    Mandatory - the FTP server's hostname.
    .PARAMETER FtpUser
    Mandatory - the username for the FTP server.
    .PARAMETER FtpPass
    Mandatory - the password for the FTP server.

    .EXAMPLE
    Send-LogsToFTP -LogFolderPath "$env:SystemDrive\Logs" -FtpHostName "ftp.somesite.com" -FtpUser "ftp_user" -FtpPass "ftp_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFolderPath,

        [Parameter(Mandatory = $true)]
        [string]$FtpHostName,

        [Parameter(Mandatory = $true)]
        [string]$FtpUser,

        [Parameter(Mandatory = $true)]
        [string]$FtpPass
    )
    if (-not (Test-Path -Path $LogFolderPath -PathType Container)) {
        Write-Error -Message "Invalid log folder path: $LogFolderPath!"
        return
    }
    $LogFiles = Get-ChildItem $LogFolderPath -Filter *.log
    if ($LogFiles.Count -eq 0) {
        Write-Warning -Message "No log files found in $LogFolderPath, exiting!"
        return
    }
    $ScriptPath = $(Split-Path -Parent $MyInvocation.MyCommand.Definition)
    [Reflection.Assembly]::LoadFrom($(Join-Path $ScriptPath "WinSCPnet.dll")) | Out-Null
    $SessionOptions = New-Object WinSCP.SessionOptions
    $SessionOptions.Protocol = [WinSCP.Protocol]::ftp
    $SessionOptions.FtpSecure = [WinSCP.FtpSecure]::Explicit
    $SessionOptions.HostName = $FtpHostName
    $SessionOptions.UserName = $FtpUser
    $SessionOptions.Password = $FtpPass
    $Session = New-Object WinSCP.Session
    try {
        $Session.Open($SessionOptions)
        $TransferOptions = New-Object WinSCP.TransferOptions
        $TransferOptions.TransferMode = [WinSCP.TransferMode]::Automatic
        $TransferResult = $Session.PutFiles("$LogFolderPath\*.log", "/", $False, $TransferOptions)
        if ($TransferResult.IsSuccess) {
            foreach ($Transfer in $TransferResult.Transfers) {
                Remove-Item $Transfer.FileName -Force -Verbose
            }
        }
        else {
            foreach ($Tran in $TransferResult.Transfers) {
                Rename-Item $Tran.FileName ($Tran.FileName + (Get-Random)) -Force -Verbose
            }
        }
    }
    finally {
        $Session.Dispose()
    }
    Write-Host "Upload completed successfully" -ForegroundColor Green
}
