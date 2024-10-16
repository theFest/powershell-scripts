function Install-WindowsUpdates {
    <#
    .SYNOPSIS
    Installs Windows updates on a local or remote computer.

    .DESCRIPTION
    This function installs Windows updates on either the local machine or a specified remote computer.
    Provides options to include hidden updates, reinstall already installed updates, and install updates requiring a system reboot.
    It initiates a reboot after updates are installed, with an optional delay. Progress and update details can be displayed.

    .EXAMPLE
    Install-WindowsUpdates -Verbose
    Install-WindowsUpdates -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -IncludeHidden -Reboot -RebootDelay 600 -ShowProgress

    .NOTES
    v0.6.5
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify the remote computer name")]
        [Alias("c")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Provide the username for remote authentication")]
        [Alias("u")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Provide the password for the specified username")]
        [Alias("p")]
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "Install hidden updates")]
        [Alias("ih")]
        [switch]$IncludeHidden,

        [Parameter(Mandatory = $false, HelpMessage = "Reinstall already installed updates")]
        [Alias("ii")]
        [switch]$IncludeInstalled,

        [Parameter(Mandatory = $false, HelpMessage = "Install updates requiring a system reboot")]
        [Alias("ir")]
        [switch]$IncludeRebootRequired,

        [Parameter(Mandatory = $false, HelpMessage = "Reboot the remote computer after updates are installed")]
        [Alias("rb")]
        [switch]$Reboot,

        [Parameter(Mandatory = $false, HelpMessage = "Delay in seconds before initiating a reboot")]
        [Alias("d")]
        [int]$RebootDelay = 300,

        [Parameter(Mandatory = $false, HelpMessage = "Wait for the specified number of seconds before proceeding with installation")]
        [Alias("w")]
        [int]$Wait = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Show progress of update installation")]
        [Alias("sp")]
        [switch]$ShowProgress,

        [Parameter(Mandatory = $false, HelpMessage = "Show details about available updates on the remote computer")]
        [Alias("ud")]
        [switch]$ShowUpdateDetails
    )
    try {
        Write-Host "Checking for available updates on $ComputerName..." -ForegroundColor Cyan
        $Credential = $null
        if ($User -and $Pass) {
            $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecurePassword
        }
        $InstallScriptBlock = {
            param (
                [switch]$IncludeHidden,
                [switch]$IncludeInstalled,
                [switch]$IncludeRebootRequired,
                [switch]$ShowProgress,
                [switch]$ShowUpdateDetails
            )
            $UpdateSession = New-Object -ComObject Microsoft.Update.Session
            $Searcher = $UpdateSession.CreateUpdateSearcher()
            $Criteria = "IsInstalled=0"
            if ($IncludeHidden) { $Criteria += " or IsHidden=1" }
            if ($IncludeInstalled) { $Criteria += " or IsInstalled=1" }
            if ($IncludeRebootRequired) { $Criteria += " or RebootRequired=1" }
            $SearchResult = $Searcher.Search($Criteria)
            $TotalUpdates = $SearchResult.Updates.Count
            if ($ShowUpdateDetails) {
                Write-Host "Found $TotalUpdates updates available." -ForegroundColor Yellow
                foreach ($Update in $SearchResult.Updates) {
                    Write-Host "Update: $($Update.Title), ID: $($Update.Identity.UpdateID), Installed: $($Update.IsInstalled)" -ForegroundColor Gray
                }
            }
            $UpdatesInstalled = 0
            foreach ($Update in $SearchResult.Updates) {
                if (-not $Update.IsInstalled) {
                    if ($ShowProgress) {
                        $ProgressStatus = "Installing update: $($Update.Title)"
                        $PercentComplete = [math]::Round(($UpdatesInstalled / $TotalUpdates) * 100, 2)
                        Write-Host -NoNewline "$ProgressStatus [$PercentComplete%] "
                    }
                    if ($Update.PSObject.Methods -match 'GetInstaller') {
                        $Installer = $Update.GetInstaller()
                        $Installer.Install()
                    }
                    $UpdatesInstalled++
                    if ($ShowProgress) {
                        Write-Host " - Completed!" -ForegroundColor Green
                    }
                }
            }
            return $UpdatesInstalled
        }
        if ($ComputerName -ne $env:COMPUTERNAME) {
            Write-Host "Establishing a remote session with $ComputerName..." -ForegroundColor DarkCyan
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
            Write-Host "Installing Windows updates on $ComputerName remotely..." -ForegroundColor DarkGreen
            $UpdatesInstalled = Invoke-Command -Session $Session -ScriptBlock $InstallScriptBlock -ArgumentList $IncludeHidden, $IncludeInstalled, $IncludeRebootRequired, $ShowProgress, $ShowUpdateDetails
            if ($UpdatesInstalled -gt 0) {
                Write-Host "$UpdatesInstalled updates installed successfully on $ComputerName." -ForegroundColor Green
            }
            else {
                Write-Host "No updates were installed on $ComputerName." -ForegroundColor Yellow
            }
            Write-Verbose -Message "Removing the remote session with $ComputerName..."
            Remove-PSSession -Session $Session -ErrorAction SilentlyContinue
            if ($Reboot) {
                Write-Host "Rebooting $ComputerName in $RebootDelay seconds..." -ForegroundColor DarkYellow
                Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                    param ($Delay)
                    Start-Sleep -Seconds $Delay
                    Restart-Computer -Force
                } -ArgumentList $RebootDelay
            }
        }
        else {
            Write-Host "Installing Windows updates locally..." -ForegroundColor Cyan
            $UpdatesInstalled = & $InstallScriptBlock -IncludeHidden $IncludeHidden -IncludeInstalled $IncludeInstalled -IncludeRebootRequired $IncludeRebootRequired -ShowProgress $ShowProgress -ShowUpdateDetails $ShowUpdateDetails
            if ($UpdatesInstalled -gt 0) {
                Write-Host "$UpdatesInstalled updates installed successfully on the local machine." -ForegroundColor Green
            }
            else {
                Write-Host "No updates were installed on the local machine." -ForegroundColor Yellow
            }
        }
        if ($Wait -gt 0) {
            Write-Host "Waiting for $Wait seconds before proceeding..." -ForegroundColor DarkCyan
            Start-Sleep -Seconds $Wait
        }
    }
    catch {
        Write-Error -Message "Failed to install Windows updates: $_"
    }
}
