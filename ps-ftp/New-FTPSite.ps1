Function New-FTPSite {
    <#
    .SYNOPSIS
    Creates a new FTP site in IIS.
    
    .DESCRIPTION
    This fucntion creates a new FTP site in IIS with specified configurations.
    
    .PARAMETER YesNo
    Mandatory - specifies whether to continue or exit the function ('y' or 'n').
    .PARAMETER SiteName
    NotMandatory - specifies the name for the FTP site (default: MyNewFTPSite).
    .PARAMETER FtpDirectory
    NotMandatory - the directory for FTP uploads (default: Uploads).
    .PARAMETER FtpUser
    NotMandatory - specifies the username for FTP access (default: ftpUser).
    .PARAMETER FtpPass
    NotMandatory - specifies the password for the FTP user (default: P@ssw0rd).
    
    .EXAMPLE
    New-FTPSite -YesNo "y" -SiteName "NewFTPSite" -FtpDirectory "MyUploads" -FtpUser "MyUser" -FtpPass "MyPassword"
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Enter 'y' to continue or 'n' to exit")]
        [ValidateSet("y", "n")]
        [string]$YesNo,
    
        [Parameter(Mandatory = $false, HelpMessage = "Specify the name for the FTP site")]
        [string]$SiteName = "MyNewFTPSite",
    
        [Parameter(Mandatory = $false, HelpMessage = "Specify the directory for FTP uploads")]
        [string]$FtpDirectory = "Uploads",
    
        [Parameter(Mandatory = $false, HelpMessage = "Specify the username for FTP access")]
        [string]$FtpUser = "ftpUser",
    
        [Parameter(Mandatory = $false, HelpMessage = "Specify the password for the FTP user")]
        [ValidateNotNullOrEmpty()]
        [string]$FtpPass = "P@ssw0rd"
    )
    BEGIN {
        if ($YesNo -ne "y") {
            Write-Host "`nExiting back to menu.`n`n" -ForegroundColor Yellow
            return
        }
        if (-not (Test-Path -Path "HKLM:\software\microsoft\InetStp")) {
            Write-Host "IIS is not installed on this machine!" -ForegroundColor Red
            return
        }
        $IIsVersion = Get-ItemProperty "HKLM:\software\microsoft\InetStp"
        if ($IIsVersion.MajorVersion -eq 8 -or ($IIsVersion.MajorVersion -eq 7 -and $IIsVersion.MinorVersion -ge 5)) {
            Import-Module WebAdministration
        }
        elseif (-not (Get-PSSnapIn | Where-Object { $_.Name -eq "WebAdministration"; })) {
            Add-PSSnapIn WebAdministration
        }
        $FeatureWebServer = Get-WindowsFeature -Name 'web-Server'
        if (-not $FeatureWebServer.Installed) {
            Add-WindowsFeature -Name 'web-Server'
            Write-Host "IIS Role installed" -ForegroundColor Green
        }
        else {
            Write-Host "IIS role already installed" -ForegroundColor DarkGray
        }
        $FeatureFTP = Get-WindowsFeature -Name 'web-FTP-Server'
        if (-not $FeatureFTP.Installed) {
            Add-WindowsFeature -Name 'web-FTP-Server'
            Write-Host "FTP Role installed" -ForegroundColor Green
        }
        else {
            Write-Host "FTP role already installed" -ForegroundColor DarkGray
        }
    }
    PROCESS {
        $FtpPath = "IIS:\Sites\$SiteName"
        $FtpBinding = @{ protocol = 'FTP'; bindingInformation = '*:21:' }
        $Websites = Get-ChildItem IIS:\Sites
        $FtpPresent = $Websites | Where-Object { $_.Bindings.Collection.Protocol -eq 'FTP' }
        if ($FtpPresent) {
            Write-Host "FTP Site '$SiteName' already exists, skipping creation" -ForegroundColor Yellow
            return
        }
        try {
            New-Item -Path $FtpPath -ItemType "VirtualDirectory" -Bindings $FtpBinding -ErrorAction Stop | Out-Null
            Write-Host "FTP Site '$SiteName' created successfully" -ForegroundColor Green
            $Acl = Get-Acl $FtpPath
            $Permission = "NETWORK SERVICE", "Read"
            $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $Permission
            $Acl.SetAccessRule($AccessRule)
            Set-Acl $FtpPath $Acl -Verbose
            Write-Host "Permissions set for the FTP Site" -ForegroundColor Green
            $FtpConfig = Get-Item "$FtpPath/ftp"
            $FtpConfig.EnableSsl = $true
            $FtpConfig.Authentication.Basic.Enabled = $true
            $FtpConfig.Authentication.Basic.UserName = $FtpUser
            $FtpConfig.Authentication.Basic.Password = ConvertTo-SecureString $FtpPass-AsPlainText -Force
            $FtpConfig | Set-Item -Verbose
            Write-Host "FTP Site settings configured" -ForegroundColor Green
            $FtpDir = "$FtpPath\$FtpDirectory"
            New-Item -Path $FtpDir -ItemType Directory -ErrorAction Stop | Out-Null
            Write-Host "FTP Directory '$FtpDirectory' created successfully" -ForegroundColor Green
            $FtpLogging = Get-Item "$FtpPath/logfile"
            $FtpLogging.LogFormat = "W3C"
            $FtpLogging.LogExtFileFlags = "Date, Time, ClientIP, UserName, SiteName, ComputerName, ServerIP, Method, UriStem, UriQuery, HttpStatus, Win32Status, BytesSent, BytesRecv, TimeTaken, ServerPort, UserAgent, Cookie, Referer"
            $FtpLogging.LogTargetW3C = "File"
            $FtpLogging.LogFileDirectory = "C:\inetpub\logs\LogFiles"
            $FtpLogging | Set-Item -Verbose
            Write-Host "FTP Logging configured" -ForegroundColor Green
            $FtpUser = New-Object System.Security.Principal.NTAccount("YourDomain", $FtpUser)
            $FtpDirInfo = Get-Acl $FtpDir
            $FtpDirInfo.SetAccessRuleProtection($true, $false)
            $FtpAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($FtpUser, "FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")
            $FtpDirInfo.AddAccessRule($FtpAccessRule)
            Set-Acl $FtpDir $FtpDirInfo -Verbose
            Write-Host "User '$FtpUser' added to FTP Directory '$FtpDirectory'" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to create FTP Site: $_" -ForegroundColor Red
            return
        }
    }
    END {
        $Websites = Get-ChildItem IIS:\Sites
        $FtpPresent = $Websites | Where-Object { $_.Bindings.Collection.Protocol -eq 'FTP' }
        if ($FtpPresent) {
            Write-Host "FTP Site was created successfully" -ForegroundColor Green
            $Site = $Websites | Where-Object { $_.Name -eq $SiteName }
            if ($Site) {
                $FtpStatus = $Site.State
                if ($FtpStatus -eq 'Started') {
                    Write-Host "FTP Site is running" -ForegroundColor Green
                }
                else {
                    Write-Host "FTP Site is not running, starting it..." -ForegroundColor Yellow
                    Start-WebItem $Site
                }
            }
            else {
                Write-Host "FTP Site not found!" -ForegroundColor Red
            }
        }
        else {
            Write-Host "FTP Site was not created!" -ForegroundColor Red
        }
    }
}
