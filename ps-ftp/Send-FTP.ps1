Function Send-FTP {
    <#
    .SYNOPSIS
    Sends files via FTP.

    .DESCRIPTION
    This function sends files from a source directory to a destination FTP server.

    .PARAMETER User
    NotMandatory - specifies the username for FTP authentication.
    .PARAMETER Pass
    NotMandatory - specifies the password for FTP authentication.
    .PARAMETER Site
    Mandatory - specifies the FTP server address.
    .PARAMETER Port
    NotMandatory - the port number for the FTP connection.
    .PARAMETER Source
    Mandatory - the local directory path containing files to be sent.
    .PARAMETER Destination
    Mandatory - the destination directory path on the FTP server.
    .PARAMETER Timeout
    NotMandatory - the timeout duration for the FTP connection in seconds.
    .PARAMETER Secure
    NotMandatory - indicates whether to use a secure FTP connection.
    .PARAMETER ActiveMode
    NotMandatory - indicates whether to use active mode for FTP transfer.
    .PARAMETER TrustAnyTLSCert
    NotMandatory - indicates whether to trust any TLS certificate for secure connections.
    .PARAMETER EnableLog
    NotMandatory - indicates whether to enable logging for the FTP session.

    .EXAMPLE
    Send-FTP -Site "ftp.example.com" -User "username" -Pass "password" -Source "C:\local_files_path\" -Dest "/remote/directory/"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$User = "anonymous",

        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [string]$Pass = "anonymous",
        
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Site,

        [Parameter(Mandatory = $false)]
        [int]$Port = 0,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [SupportsWildcards()]
        [string]$Source,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $false)]
        [int]$Timeout = 30,

        [Parameter(Mandatory = $false)]
        [switch]$Secure = $false,

        [Parameter(Mandatory = $false)]
        [switch]$ActiveMode = $false,

        [Parameter(Mandatory = $false)]
        [switch]$TrustAnyTLSCert = $false,

        [Parameter(Mandatory = $false)]
        [switch]$EnableLog = $false
    )
    try {
        $SessionOptions = New-Object WinSCP.SessionOptions
        $SessionOptions.Protocol = [WinSCP.Protocol]::Ftp
        $SessionOptions.HostName = $Site
        $SessionOptions.UserName = $User
        $SessionOptions.Password = $Pass
        $SessionOptions.PortNumber = $Port
        $SessionOptions.Timeout = New-TimeSpan -Seconds $Timeout
        if ($Activemode) {
            $SessionOptions.FtpMode = [WinSCP.FtpMode]::Active
        }
        if ($Secure) {
            $SessionOptions.FtpSecure = [WinSCP.FtpSecure]::Explicit
        }
        if ($Secure -and $TrustAnyTLSCert) {
            $SessionOptions.GiveUpSecurityAndAcceptAnyTlsHostCertificate = $true
        }
        $Session = New-Object WinSCP.Session
        if ($EnableLog) {
            $Session.SessionLogPath = "$env:TEMP\ftp.log" 
        }
        $Success = @()
        $Failure = @()
        $Session.FileTransferProgress += { 
            param($FileSender, $e)
            Write-Progress `
                -Id 0 -Activity "Loading" -CurrentOperation ("$($e.FileName) - {0:P0}" -f $e.FileProgress) -Status ("{0:P0} complete at $($e.CPS) bps" -f $e.OverallProgress) `
                -PercentComplete ($e.OverallProgress * 100)
        }
        try {
            $Session.Open($SessionOptions)
            $TransferOptions = New-Object WinSCP.TransferOptions
            $TransferOptions.TransferMode = [WinSCP.TransferMode]::Binary
            $Filepaths = Get-ChildItem -Path $Source -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object { $_.FullName }
            foreach ($Filepath in $Filepaths) {
                $TransferResult = $Session.PutFiles("$Filepath", "$Destination", $False, $TransferOptions)
                if ($TransferResult.IsSuccess) {
                    $Success += (Split-Path $Filepath -Leaf -Resolve)
                }
                else {
                    $Failure += (Split-Path $Filepath -Leaf -Resolve)
                }   
            }
        }
        catch [WinSCP.SessionException] {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            return 2
        }
        finally {
            $Session.Dispose()
        }
    }
    catch {
        Write-Host ("Error: {0}" -f $_.Exception.Message) -ForegroundColor Red
        $Failure += (Split-Path $Source -Leaf -Resolve)
    }
}
