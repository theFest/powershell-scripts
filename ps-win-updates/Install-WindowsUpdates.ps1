Function Install-WindowsUpdates {
    <#
    .SYNOPSIS
    Installs Windows updates on a local or remote computer.

    .DESCRIPTION
    This function installs Windows updates on either the local machine or a specified remote computer.
    Provides options to include hidden updates, reinstall already installed updates, and install updates requiring a system reboot. It also initiates a reboot after updates are installed, with an optional delay. Progress and update details can be displayed.

    .PARAMETER ComputerName
    Remote computer name, defaults to the local machine.
    .PARAMETER User
    Username for remote authentication.
    .PARAMETER Pass
    Password for the specified username.
    .PARAMETER IncludeHidden
    Installs hidden updates in addition to regular updates.
    .PARAMETER IncludeInstalled
    Reinstalls already installed updates.
    .PARAMETER IncludeRebootRequired
    Installs updates requiring a system reboot.
    .PARAMETER Reboot
    Initiates a reboot on the remote computer after updates are installed.
    .PARAMETER RebootDelay
    Delay in seconds before initiating a reboot, default is 300 seconds.
    .PARAMETER Wait
    Number of seconds to wait before proceeding with the installation.
    .PARAMETER ShowProgress
    Displays progress of the update installation.
    .PARAMETER ShowUpdateDetails
    Shows details about available updates on the remote computer.

    .EXAMPLE
    Install-WindowsUpdates -Verbose
    Install-WindowsUpdates -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -IncludeHidden -Reboot -RebootDelay 600 -ShowProgress

    .NOTES
    0.5.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Specify the remote computer name")]
        [Alias("c")]
        [string]$ComputerName = $env:COMPUTERNAME,
    
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Provide the username for remote authentication")]
        [Alias("u")]
        [string]$User,
    
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Provide the password for the specified username")]
        [Alias("p")]
        [string]$Pass,
    
        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Install hidden updates")]
        [Alias("ih")]
        [switch]$IncludeHidden,
    
        [Parameter(Mandatory = $false, Position = 4, HelpMessage = "Reinstall already installed updates")]
        [Alias("ii")]
        [switch]$IncludeInstalled,
    
        [Parameter(Mandatory = $false, Position = 5, HelpMessage = "Install updates requiring a system reboot")]
        [Alias("ir")]
        [switch]$IncludeRebootRequired,
    
        [Parameter(Mandatory = $false, Position = 6, HelpMessage = "Reboot the remote computer after updates are installed")]
        [Alias("rb")]
        [switch]$Reboot,
    
        [Parameter(Mandatory = $false, Position = 7, HelpMessage = "Delay in seconds before initiating a reboot")]
        [Alias("d")]
        [int]$RebootDelay = 300,
    
        [Parameter(Mandatory = $false, Position = 8, HelpMessage = "Wait for the specified number of seconds before proceeding with installation")]
        [Alias("w")]
        [int]$Wait = 0,
    
        [Parameter(Mandatory = $false, Position = 9, HelpMessage = "Show progress of update installation")]
        [Alias("sp")]
        [switch]$ShowProgress,
    
        [Parameter(Mandatory = $false, Position = 10, HelpMessage = "Show details about available updates on the remote computer")]
        [Alias("ud")]
        [switch]$ShowUpdateDetails
    )
    try {
        Write-Host "Checking for available updates..."
        $Credential = $null
        if ($User -and $Pass) {
            $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecurePassword
        }
        $InstallScriptBlock = {
            param (
                $IncludeHidden,
                $IncludeInstalled,
                $IncludeRebootRequired,
                $ShowProgress
            )
            $UpdateSession = New-Object -ComObject Microsoft.Update.Session
            $Searcher = $UpdateSession.CreateUpdateSearcher()
            $Criteria = "IsInstalled=0"
            if ($IncludeHidden) {
                $Criteria += " or IsHidden=1"
            }
            if ($IncludeInstalled) {
                $Criteria += " or IsInstalled=1"
            }
            if ($IncludeRebootRequired) {
                $Criteria += " or RebootRequired=1"
            }
            $SearchResult = $Searcher.Search($Criteria)
            $TotalUpdates = $SearchResult.Updates.Count
            $UpdatesInstalled = 0
            foreach ($Update in $SearchResult.Updates) {
                if (-not $Update.IsInstalled) {
                    if ($ShowProgress) {
                        $ProgressStatus = "Installing update: $($Update.Title)"
                        $PercentComplete = ($UpdatesInstalled / $TotalUpdates) * 100
                        Write-Host -NoNewline "$ProgressStatus [$PercentComplete%] "
                    }
                    if ($Update.PSObject.Methods -match 'GetInstaller') {
                        $Installer = $Update.GetInstaller()
                        $Installer.Install()
                    }
                    $UpdatesInstalled++
                }
            }
        }
        if ($ComputerName -ne $env:COMPUTERNAME) {
            Write-Host "Establishing a remote session with $ComputerName..." -ForegroundColor DarkCyan
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
            Write-Host "Installing Windows updates on $ComputerName remotely..." -ForegroundColor DarkGreen
            Invoke-Command -Session $Session -ScriptBlock $InstallScriptBlock -ArgumentList $IncludeHidden, $IncludeInstalled, $IncludeRebootRequired, $ShowProgress
            if ($Session) {
                Write-Verbose -Message "Removing the remote session with $ComputerName..."
                Remove-PSSession -Session $Session -ErrorAction SilentlyContinue -Verbose
            }
            if ($Reboot) {
                Write-Host "Rebooting $ComputerName in $RebootDelay seconds..."
                Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                    param ($Delay)
                    Start-Sleep -Seconds $Delay
                    Restart-Computer -Force
                } -ArgumentList $RebootDelay
            }
        }
        else {
            Write-Host "Installing Windows updates locally..." -ForegroundColor Cyan
            & $InstallScriptBlock -IncludeHidden $IncludeHidden -IncludeInstalled $IncludeInstalled -IncludeRebootRequired $IncludeRebootRequired -ShowProgress $ShowProgress
        }
        if ($Wait -gt 0) {
            Write-Host "Waiting for $Wait seconds..." -ForegroundColor DarkCyan
            Start-Sleep -Seconds $Wait
        }
        Write-Host "All updates installed successfully." -ForegroundColor Green
    }
    catch {
        Write-Error -Message "Failed to install Windows updates: $_"
    }
}
