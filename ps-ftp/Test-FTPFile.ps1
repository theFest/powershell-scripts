Function Test-FTPFile { 
    <#
    .SYNOPSIS
    Checks if a file exists on a remote FTP server.
    
    .DESCRIPTION
    This function checks the existence of a specified file on the remote FTP server.
    
    .PARAMETER User
    NotMandatory - specifies the username for FTP authentication.
    .PARAMETER Pass
    NotMandatory - specifies the password for FTP authentication.
    .PARAMETER Site
    Mandatory - specifies the FTP server address.
    .PARAMETER Remotefile
    Mandatory - path of the file on the remote FTP server to check.
    .PARAMETER Port
    NotMandatory - specifies the port number for the FTP connection.
    .PARAMETER Secure
    NotMandatory - indicates whether to use a secure FTP connection.
    .PARAMETER ActiveMode
    NotMandatory - indicates whether to use active mode for FTP transfer.
    .PARAMETER TrustAnyTLSCert
    NotMandatory - indicates whether to trust any TLS certificate for secure connections.
    .PARAMETER EnableLog
    NotMandatory - indicates whether to enable logging for the FTP session.
    
    .EXAMPLE
    Test-FTPFile -Site "ftp.example.com" -User "username" -Pass "password" -Remotefile "/remote/directory/file.txt"
    
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

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$Remotefile,

        [Parameter(Mandatory = $false)]
        [int]$Port = 0,

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
        if ($ActiveMode) {
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
            $Session.SessionLogPath = "$env:USERPROFILE\Desktop\ftp.log" 
        }
        $Session.Open($SessionOptions)
        $FileExists = $Session.FileExists($Remotefile)
        if ($FileExists) {
            Write-Host ("Exists: {0}" -f $Remotefile) -ForegroundColor Green
        }
        else {
            Write-Host ("Not Exists: {0}" -f $Remotefile) -ForegroundColor Yellow
        }
        return $FileExists
    }
    catch [WinSCP.SessionException] {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}
