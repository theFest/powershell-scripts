Function Sync-FTPDirectory {
    <#
    .SYNOPSIS
    Synchronizes directories via FTP.

    .DESCRIPTION
    This function synchronizes directories between a local directory and a remote FTP server.

    .PARAMETER User
    NotMandatory - specifies the username for FTP authentication.
    .PARAMETER Pass
    NotMandatory - specifies the password for FTP authentication.
    .PARAMETER Site
    Mandatory - specifies the FTP server address.
    .PARAMETER Port
    NotMandatory - the port number for the FTP connection.
    .PARAMETER LocalDir
    Mandatory - the local directory path.
    .PARAMETER RemoteDir
    Mandatory - the remote directory path on the FTP server.
    .PARAMETER Direction
    Mandatory - specifies the synchronization direction ('Local', 'Remote', 'Both').
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
    Sync-FTPDirectory -Site "ftp.example.com" -User "username" -Pass "password" -LocalDir "C:\Files\" -RemoteDir "/remote/directory/" -Direction "Both"

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
        [string]$LocalDir,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$RemoteDir,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('Local', 'Remote', 'Both')]
        [string]$Direction,

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
            $Session.SessionLogPath = "$env:USERPROFILE\Desktop\ftp.log"
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
            if ($Direction -ne 'Both') {
                $SynchronizationResult = $Session.SynchronizeDirectories([WinSCP.SynchronizationMode]::$($Direction), $LocalDir, $RemoteDir, $False, $True, [WinSCP.SynchronizationCriteria]::Time, $TransferOptions)
            }
            else {
                $SynchronizationResult = $Session.SynchronizeDirectories([WinSCP.SynchronizationMode]::$($Direction), $LocalDir, $RemoteDir, $False, $False, [WinSCP.SynchronizationCriteria]::Time, $TransferOptions)
            }
            $SynchronizationResult.Check()
            if ($SynchronizationResult.IsSuccess) {
                foreach ($Download in $SynchronizationResult.Downloads) {
                    Write-Host -ForegroundColor Green ("Download file {0} to {1}" -f ($Download).FileName, ($Download).Destination)
                    $Success += ($Download).FileName
                }
                foreach ($Download in $SynchronizationResult.Uploads) {
                    Write-Host -ForegroundColor Green ("Upload   file {0} to {1}" -f ($Download).FileName, ($Download).Destination)
                }
            }
            elseif ($null -ne $SynchronizationResult.Failures) {
                foreach ($Failure in $SynchronizationResult.Failures) {
                    Write-Host -ForegroundColor Red ("Error Sync file {0} to {1}" -f ($Failure).FileName, ($Failure).Destination)
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
        $Failure += (Split-Path $LocalDir -Leaf -Resolve)
    }
}
