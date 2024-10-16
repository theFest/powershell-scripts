function Disable-WindowsUpdate {
    <#
    .SYNOPSIS
    Disables or enables the Windows Update service on a specified computer.

    .DESCRIPTION
    This function allows you to disable or enable the Windows Update service using the Windows Update Blocker (WUB). Can operate on the local machine or remotely on a specified computer.
    It downloads the WUB tool, extracts it, and executes it with the specified operation. The function also provides options to clean up temporary files and restart the computer after the operation.

    .EXAMPLE
    Disable-WindowsUpdate -UpdateOperation '/D /P' -Verbose
    Disable-WindowsUpdate -UpdateOperation '/D' -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.6.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "'/D' --> Disable | '/E' --> Enable | '/D /P' --> Disable & Protect")]
        [ValidateSet("/D", "/E", "/D /P")]
        [string]$UpdateOperation = "/D /P",

        [Parameter(Mandatory = $false, HelpMessage = "URL for downloading the Windows Update disabler (WUB)")]
        [uri]$WubDownloadUrl = "https://www.sordum.org/files/downloads.php?st-windows-update-blocker",

        [Parameter(Mandatory = $false, HelpMessage = "Version of the Windows Update disabler (WUB) to download")]
        [string]$WubVersion = "1.8",

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory where the WUB will be downloaded and extracted")]
        [string]$DownloadPath = "$env:TEMP\WU_Disable",

        [Parameter(Mandatory = $false, HelpMessage = "Remove the temporary folder after the operation")]
        [switch]$RemoveWUB,

        [Parameter(Mandatory = $false, HelpMessage = "Restart the computer after the operation")]
        [switch]$Restart,

        [Parameter(Mandatory = $false, HelpMessage = "The name of the remote computer to execute the operation on")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, HelpMessage = "Username for authentication on the remote computer")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for authentication on the remote computer")]
        [string]$Pass
    )
    $Credential = $null
    if ($ComputerName) {
        $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($User, $SecurePassword)
    }
    else {
        $ComputerName = $env:COMPUTERNAME
    }
    try {
        Write-Host "Creating download directory..." -ForegroundColor Green
        if ($ComputerName -eq $env:COMPUTERNAME) {
            New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
        }
        else {
            Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                param ($DownloadPath)
                New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
            } -ArgumentList $DownloadPath -ErrorAction Stop
        }
        $WubZipPath = Join-Path $DownloadPath "Wub_v$WubVersion.zip"
        if (!(Test-Path -Path $WubZipPath)) {
            Write-Host "Downloading Windows Update disabler..." -ForegroundColor Green
            if ($ComputerName -eq $env:COMPUTERNAME) {
                Invoke-WebRequest -Uri $WubDownloadUrl -OutFile $WubZipPath -UseBasicParsing -Verbose
            }
            else {
                Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                    param ($WubDownloadUrl, $WubZipPath)
                    Invoke-WebRequest -Uri $WubDownloadUrl -OutFile $WubZipPath -UseBasicParsing -Verbose
                } -ArgumentList $WubDownloadUrl, $WubZipPath -ErrorAction Stop
            }
        }
        $WubExtractPath = Join-Path -Path $DownloadPath "Wub"
        Write-Host "Extracting Windows Update disabler..." -ForegroundColor Green
        if ($ComputerName -eq $env:COMPUTERNAME) {
            Expand-Archive -Path $WubZipPath -DestinationPath $WubExtractPath -Force -Verbose
        }
        else {
            Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                param ($WubZipPath, $WubExtractPath)
                Expand-Archive -Path $WubZipPath -DestinationPath $WubExtractPath -Force -Verbose
            } -ArgumentList $WubZipPath, $WubExtractPath -ErrorAction Stop
        }
        Write-Verbose -Message "Starting Wub to $UpdateOperation updates..."
        if ($ComputerName -eq $env:COMPUTERNAME) {
            Start-Process -FilePath "$($WubExtractPath)\Wub\Wub_x64.exe" -ArgumentList $UpdateOperation -Wait -NoNewWindow
        }
        else {
            Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                param ($WubExtractPath, $UpdateOperation)
                Start-Process -FilePath "$($WubExtractPath)\Wub\Wub_x64.exe" -ArgumentList $UpdateOperation -Wait -NoNewWindow
            } -ArgumentList $WubExtractPath, $UpdateOperation -ErrorAction Stop
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
    finally {
        if ($ComputerName -eq $env:COMPUTERNAME) {
            $ServicesStatus = Get-Service -Name 'wuauserv', 'WaaSMedicSvc' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status
        }
        else {
            $ServicesStatus = Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                Get-Service -Name 'wuauserv', 'WaaSMedicSvc' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status
            } -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 10
        $StatusMessage = if ($ServicesStatus -eq 'Disabled') { "disabled" } else { "enabled" }
        Write-Host "Windows Update services $StatusMessage." -ForegroundColor Cyan
    }
    if ($RemoveWUB) {
        Write-Warning -Message "Cleaning up, removing the temporary folder..."
        if ($ComputerName -eq $env:COMPUTERNAME) {
            Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
        }
        else {
            Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                param ($DownloadPath)
                Remove-Item -Path $DownloadPath -Force -Recurse -Verbose
            } -ArgumentList $DownloadPath -ErrorAction SilentlyContinue
        }
    }
    if ($Restart) {
        Write-Warning -Message "Restarting computer..."
        if ($ComputerName -eq $env:COMPUTERNAME) {
            Restart-Computer -Force
        }
        else {
            Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                Restart-Computer -Force
            } -ErrorAction SilentlyContinue
        }
    }
}
