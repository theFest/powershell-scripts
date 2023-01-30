Function OoklaConnectionTester {
    <#
    .SYNOPSIS
    Ookla tester for Internet connection performance and network stability. 
    
    .DESCRIPTION
    With this function you can test your Internet connection. It includes script or gui based test with ability to send log to remote destination. 
    
    .PARAMETER Retries
    Mandatory - enter number of test retries.
    .PARAMETER OoklaURI
    NotMandatory - download source of speedtest executable. 
    .PARAMETER LocalPath
    NotMandatory - define local path where you want speedtest executable to reside.
    .PARAMETER LogFilePath
    NotMandatory - declare path for log file on you machine.
    .PARAMETER SendLog
    NotMandatory - if you wanna send log, choose to send it to either remote computer of web destination.
    .PARAMETER RemotePass
    NotMandatory - when sending log to remote computer, here enter a password of the remote target machine.
    .PARAMETER RemoteUser
    NotMandatory - when sending log to remote computer, here enter a username of the remote target machine.
    .PARAMETER RemoteComputerName
    NotMandatory - when sending log to remote computer, here enter a hostname of the remote target machine.
    .PARAMETER RemoteComputerLocation
    NotMandatory - when sending log to remote computer, here enter a path of the remote target machine, something like "C:\Temp".
    .PARAMETER WebPathUrl
    NotMandatory - if sending log to remote web destination, here enter an URL for that location.
    .PARAMETER WebPathKey
    NotMandatory - if sending log to remote web destination, here enter an secret key for corresponding web location.
    .PARAMETER OpenLog
    NotMandatory - use this switch if you want to open log file after testing finishes.
    .PARAMETER GuiTester
    NotMandatory - if you wish to use Ookla GUI tester, use this switch. Executable URL is predifined.
    
    .EXAMPLE
    OoklaConnectionTester -GuiTester
    OoklaConnectionTester -Retries 25 -LocalPath "$env:USERPROFILE\Desktop\OoklaST" -LogFilePath "$env:USERPROFILE\Desktop\OoklaST\SpeedTest.csv"
    OoklaConnectionTester -Retries 25 -LocalPath "$env:USERPROFILE\Desktop\OoklaST" -LogFilePath "$env:USERPROFILE\Desktop\OoklaST\SpeedTest.csv" -OpenLog
    OoklaConnectionTester -Retries 50 -SendLog RemoteComputer -RemoteComputerName "Hostname_of_remote_computer" -RemoteComputerLocation "C:\Temp" -RemoteUser "username_of_remote_computer" -RemotePass "password_of_remote_computer"
    OoklaConnectionTester -Retries 100 -SendLog RemoteWebPath -WebPathUrl "https://desired_web_path/destination_folder" -WebPathKey "web_path_secret_key"
    
    .NOTES
    v1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [int]$Retries,

        [Parameter(Mandatory = $false, Position = 1)]
        [uri]$OoklaURI = "https://install.speedtest.net/app/cli/ookla-speedtest-1.1.1-win64.zip",

        [Parameter(Mandatory = $false, Position = 2)]
        [System.IO.FileInfo]$LocalPath = "$env:TEMP\OoklaSpeedTest",

        [Parameter(Mandatory = $false, Position = 3)]
        [System.IO.FileInfo]$LogFilePath = "$env:TEMP\OoklaSpeedTest\SpeedTestResults.csv",

        [Parameter(Mandatory = $false, Position = 4)]
        [ValidateSet('RemoteComputer', 'RemoteWebPath')]
        [string]$SendLog,

        [Parameter(Mandatory = $false, Position = 5)]
        [string]$RemotePass,

        [Parameter(Mandatory = $false, Position = 6)]
        [string]$RemoteUser,

        [Parameter(Mandatory = $false, Position = 7)]
        [string]$RemoteComputerName,

        [Parameter(Mandatory = $false, Position = 8)]
        [string]$RemoteComputerLocation,

        [Parameter(Mandatory = $false, Position = 9)]
        [uri]$WebPathUrl,

        [Parameter(Mandatory = $false, Position = 10)]
        [string]$WebPathKey,

        [Parameter(Mandatory = $false)]
        [switch]$OpenLog,

        [Parameter(Mandatory = $false)]
        [switch]$GuiTester
    )
    BEGIN {
        $LocalPathFolder = [System.IO.Path]::GetDirectoryName($LocalPath)
        $LocalPathFolderName = [System.IO.Path]::GetFileName($LocalPath)
        New-Item -Path $LocalPathFolder -Name $LocalPathFolderName -ItemType Directory -Force | Out-Null
        if ($GuiTester) {
            if (!(Test-Path -Path "$env:ProgramFiles\Speedtest\Speedtest.exe")) {
                Write-Output "Downloading SpeedTest GUI application for Windows..."
                [uri]$GuiTester = "https://install.speedtest.net/app/windows/latest/speedtestbyookla_x64.msi"
                $GuiUriName = [System.IO.Path]::GetFileName($GuiTester)
                $LocalPathName = [System.IO.Path]::Combine("$LocalPath\$GuiUriName")
                Invoke-WebRequest -Uri $GuiTester -OutFile $LocalPathName -Verbose
                Write-Output "Starting SpeedTest semi-silent installation..."
                $InstallerArgs = @{
                    FilePath     = 'msiexec.exe'
                    ArgumentList = @(
                        "/i $LocalPath\speedtestbyookla_x64.msi",
                        "/qr"
                        "/l* $LocalPath\speedtestbyookla_x64_msi.log"
                    )
                    Wait         = $true
                }
                Start-Process @InstallerArgs -NoNewWindow -Verbose
            }
            Write-Output "Starting SpeedTest GUI application..."
            Invoke-Item -Path "$env:ProgramFiles\Speedtest\Speedtest.exe" -Verbose
            if ((Get-Process -Name SpeedTest -Verbose).Responding) {
                Write-Output "SpeedTest GUI application is running, exiting..."
            }
            exit
        }
        $UriName = [System.IO.Path]::GetFileName($OoklaURI)
        $LocalPathName = [System.IO.Path]::Combine("$LocalPath\$UriName")
        if (!(Test-Path -Path "$LocalPath\speedtest.exe")) {
            Invoke-WebRequest -Uri $OoklaURI -OutFile $LocalPathName -Verbose
            Expand-Archive -Path $LocalPathName -DestinationPath $LocalPath -Force -Verbose
        }
        Write-Output "SpeedTest executable found, preparing..."
    }
    PROCESS {
        Write-Output "Starting initial connection test..."
        $Timer = [Diagnostics.Stopwatch]::StartNew()
        $SpeedTestArgs = @{
            FilePath     = "$LocalPath\speedtest.exe"
            ArgumentList = @(
                "--format=json"
                "--accept-license"
                "--accept-gdpr"
            )
            Wait         = $true
        }
        Write-Output ("`rInitial test is starting: (0)")
        Start-Process @SpeedTestArgs -WindowStyle Hidden
        Write-Output "Time taken for initial test [$($Timer.Elapsed.Seconds)] seconds." 
        $StartTime = Get-Date
        Write-Output "Initial test has finished, please wait..."
        for ($Retries = $Retries; $Retries -gt 0; $Retries--) {
            $Speedtest = & "$LocalPath\speedtest.exe" --format=json --accept-license --accept-gdpr
            $Speedtest = $Speedtest | ConvertFrom-Json
            Write-Output ("`rRemaining connection test: " + ("{0:d2}" -f "($Retries)"))
            $SpeedObject = [PSCustomObject]@{
                Timestamp      = $Speedtest.timestamp
                PacketLoss     = [math]::Round($Speedtest.packetLoss)
                Jitter         = [math]::Round($Speedtest.ping.jitter)
                Latency        = [math]::Round($Speedtest.ping.latency)
                ExternalIP     = $Speedtest.interface.externalIp
                InternalIP     = $Speedtest.interface.internalIp
                DownloadSpeed  = [math]::Round($Speedtest.download.bandwidth / 1000000 * 8, 2)
                UploadSpeed    = [math]::Round($Speedtest.upload.bandwidth / 1000000 * 8, 2)
                ServerPort     = $Speedtest.server.port
                UsedServer     = $Speedtest.server.host
                ServerCountry  = $Speedtest.server.country
                ServerLocation = $Speedtest.server.location
                ServerName     = $Speedtest.server.name
                ISP            = $Speedtest.isp
                URL            = $Speedtest.result.url
            }
            $SpeedObject | Export-Csv $LogFilePath -NoTypeInformation -Append
        }
    }
    END {
        $TotalTime = Write-Output "TotalTestTime[$((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")]"
        Add-Content -Value $TotalTime -Path $LogFilePath -Verbose
        switch ($SendLog) {
            'RemoteComputer' {
                Write-Output "Sending log to remote computer: '$RemoteComputerName'..."
                $SecRemotePassword = ConvertTo-SecureString -AsPlainText $RemotePass -Force
                $SecuredCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $RemoteUser, $SecRemotePassword
                Write-Output "Testing if WinRM is properly configured on remote computer..."
                if (Test-WSMan -ComputerName $RemoteComputerName -Authentication default -Credential $SecuredCredentials) {
                    Write-Output "WinRM test has passed successfully..."
                    $RemotePath = New-PSSession –ComputerName $RemoteComputerName -Credential $SecuredCredentials
                    Copy-Item –Path $LogFilePath –Destination $RemoteComputerLocation –ToSession $RemotePath -Verbose
                    Write-Output "Closing WinRM PowerShell session..."
                    $RemotePath | Remove-PSSession -Verbose
                }
                else {
                    Write-Error -Message "WinRM is not properly configured on: '$RemoteComputerName'!"
                }
            }
            'RemoteWebPath' {
                Write-Output "Sending log to Web destination: '$WebPathUrl'..."
                [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls, ssl3"
                $Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $Headers.Add("Content-Type", "text/csv")
                $Headers.Add("x-amz-acl", "bucket-owner-full-control")
                $SendName = [System.IO.Path]::GetFileName($LogFilePath)
                $SendUrlPath = [System.IO.Path]::Combine("$WebPathUrl/$SendName")
                try {
                    Invoke-RestMethod $SendUrlPath -Method "PUT" -Headers $Headers -UserAgent $WebPathKey -InFile $LogFilePath -Verbose      
                }
                catch {
                    Write-Error -Message "Cannot send log to web path!"
                }
            }     
        }
        if ($OpenLog) {
            Invoke-Item -Path $LogFilePath -Verbose
        }
        return $TotalTime
    }
}