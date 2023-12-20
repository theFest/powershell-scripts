Function Show-FTPDirectory {
    <#
    .SYNOPSIS
    Retrieves and displays the contents of a remote directory on an FTP server.

    .DESCRIPTION
    This function retrieves and displays information about files and directories within a specified directory on the FTP server.

    .PARAMETER User
    NotMandatory - specifies the username for FTP authentication.
    .PARAMETER Pass
    NotMandatory - specifies the password for FTP authentication.
    .PARAMETER Site
    Mandatory - specifies the FTP server address.
    .PARAMETER Port
    NotMandatory - specifies the port number for the FTP connection.
    .PARAMETER RemoteDir
    NotMandatory - specifies the remote directory path to display the contents of.
    .PARAMETER Secure
    NotMandatory - indicates whether to use a secure FTP connection.
    .PARAMETER ActiveMode
    NotMandatory - indicates whether to use active mode for FTP transfer.
    .PARAMETER TrustAnyTLSCert
    NotMandatory - indicates whether to trust any TLS certificate for secure connections.
    .PARAMETER EnableLog
    NotMandatory - indicates whether to enable logging for the FTP session.

    .EXAMPLE
    Show-FTPDirectory -Site "ftp.example.com" -User "username" -Pass "password" -RemoteDir "/remote/directory/"

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

        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$RemoteDir = "/",

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
        $Session.Open($sessionOptions)
        $DirectoryInfo = $Session.ListDirectory($RemoteDir)
        foreach ($File in $DirectoryInfo.Files) { 
            $FileType = if ($File.isDirectory) { 'Directory' } else { 'File' }
            $LastWriteTime = $File.LastWriteTime.ToString("dd.MM.yyy HH:mm:ss")
            [PSCustomObject]@{
                Type          = $FileType
                Permissions   = $File.FilePermissions.Text
                Owner         = $File.Owner
                Size          = $File.Length
                LastWriteTime = $LastWriteTime
                Name          = $File.Name
            }
        }
    }
    catch [WinSCP.SessionException] {
        Write-Error -Message "Error: $($_.Exception.Message)"
        return 2
    }
    catch {
        Write-Error -Message "Error: $($_.Exception.Message)"
        return 2
    }
    finally {
        $Session.Dispose()
    }
}
