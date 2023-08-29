Function Get-SFTPFile {
    <#
    .SYNOPSIS
    File download from a SFTP server to a local destination.

    .DESCRIPTION
    This function allows you to securely download a file from a remote SFTP server to a local destination on your computer, it utilizes the WinSCP .NET assembly to establish a secure connection and transfer the file. This function supports various authentication methods and provides detailed error handling.

    .PARAMETER Source
    Mandatory - hostname or IP address of the remote SFTP server.
    .PARAMETER Username
    Mandatory - username to authenticate with on the remote SFTP server.
    .PARAMETER Pass
    Mandatory - password for the specified username on the remote SFTP server.
    .PARAMETER RemoteFilePath
    Mandatory - path to the file on the remote SFTP server that you want to download.
    .PARAMETER LocalDestination
    Mandatory - local directory where the downloaded file will be saved.

    .EXAMPLE
    Get-SFTPFile -Source "ftp.your_domain.xyz" -Username "your_user" -Password "your_pass" -RemoteFilePath "/your_url_path/your_example_file.exe" -LocalDestination "$env:USERPROFILE\Desktop\your_example_file.exe"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Username,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Pass,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RemoteFilePath,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$LocalDestination
    )
    [System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.GetName().Name -eq "WinSCPnet.dll" } | ForEach-Object {
        [System.AppDomain]::CurrentDomain.LoadedAssemblies.Remove($_)
    }
    New-Item -Path $env:TEMP -Name FTP -ItemType Directory -Force | Out-Null
    if (!(Test-Path -Path "$env:TEMP\FTP\WinSCP-6.1.1-Automation.zip" -ErrorAction SilentlyContinue)) {
        Invoke-WebRequest -Uri "https://netix.dl.sourceforge.net/project/winscp/WinSCP/6.1.1/WinSCP-6.1.1-Automation.zip" -OutFile "$env:TEMP\FTP\WinSCP-6.1.1-Automation.zip" -UseBasicParsing -Verbose
    }
    Expand-Archive -Path "$env:TEMP\FTP\WinSCP-6.1.1-Automation.zip" -DestinationPath "$env:TEMP\FTP\WinScp" -Force -Verbose
    Add-Type -Path "$env:TEMP\FTP\WinScp\WinSCPnet.dll"
    $SessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol                             = [WinSCP.Protocol]::Sftp
        HostName                             = $Source
        UserName                             = $Username
        Password                             = $Pass
        GiveUpSecurityAndAcceptAnySshHostKey = $true
    }
    $Session = New-Object WinSCP.Session
    try {
        $Session.Open($SessionOptions)
        $TransferOptions = New-Object WinSCP.TransferOptions
        $TransferOptions.TransferMode = [WinSCP.TransferMode]::Binary
        $TransferResult = $Session.GetFiles($RemoteFilePath, $LocalDestination, $False, $TransferOptions)
        if ($TransferResult.IsSuccess) {
            Write-Host "Download successful!" -ForegroundColor Green
        }
        else {
            Write-Error -Message "Download failed: $($TransferResult.Failures[0].Message)"
        }
    }
    finally {
        if ($Session) {
            $Session.Dispose()
        }
    }
}
