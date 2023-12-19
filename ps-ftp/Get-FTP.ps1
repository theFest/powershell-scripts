Function Get-FTP {
    <#
    .SYNOPSIS
    Downloads files via FTP.
    
    .DESCRIPTION
    This function downloads files from a remote FTP server to a local destination.
    
    .PARAMETER User
    NotMandatory - specifies the username for FTP authentication.
    .PARAMETER Pass
    NotMandatory - specifies the password for FTP authentication.
    .PARAMETER Site
    Mandatory - specifies the FTP server address.
    .PARAMETER Port
    NotMandatory - the port number for the FTP connection.
    .PARAMETER Source
    Mandatory - the path of files on the FTP server to download.
    .PARAMETER Destination
    Mandatory - the local directory to save downloaded files.
    .PARAMETER Timeout
    NotMandatory - timeout duration for the FTP connection in seconds.
    .PARAMETER Secure
    NotMandatory - indicates whether to use a secure FTP connection.
    .PARAMETER ActiveMode
    NotMandatory - indicates whether to use active mode for FTP transfer.
    .PARAMETER TrustAnyTLSCert
    NotMandatory - indicates whether to trust any TLS certificate for secure connections.
    .PARAMETER EnableLog
    NotMandatory - indicates whether to enable logging for the FTP session.
    
    .EXAMPLE
    Get-FTP -Site "ftp.example.com" -User "username" -Pass "password" -Source "/remote/directory/*.txt" -Destination "C:\Local\Download\" 
    
    .NOTES
    v0.0.1
    #>
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
        $SessionOptions.HostName = "$Site"
        $SessionOptions.UserName = "$User"
        $SessionOptions.Password = "$Pass"
        $SessionOptions.PortNumber = "$Port"
        $SessionOptions.Timeout = New-TimeSpan -Seconds $Timeout
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
            $Session.SessionLogPath = "$env:TEMP\ftp.log" 
        }
        $Session.Open($SessionOptions)
        $TransferOptions = New-Object WinSCP.TransferOptions
        $TransferOptions.TransferMode = [WinSCP.TransferMode]::Binary
        $TransferResult = $Session.GetFiles("$Source", "$Destination", $False, $TransferOptions)
        $TransferResult.Check()
        foreach ($Transfer in $TransferResult.Transfers) {
            if ($Transfer.IsSuccess) {
                Write-Output ("$(Get-Date -f "dd.MM.yyyy hh:mm:ss") {0} was transferred to {1}." -f $Transfer.FileName, $Destination) 
            }
            else {
                Write-Output ("$(Get-Date -f "dd.MM.yyyy hh:mm:ss") {0} was not transferred to {1}. Error: {2}." -f $Source, $Destination, $TransferResult.failures[0].Message -Replace '(?:\s|\r|\n)', ' ')
            }
        }
    }
    catch [WinSCP.SessionException] {
        Write-Error -Message "Error: $($_.Exception.Message)"
        return 2
    }
    finally {
        $Session.Dispose()
    }
}
