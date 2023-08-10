Function InstallWindowsUpdates {
    <#
    .SYNOPSIS
    Install available Windows updates on a remote computer.
    
    .DESCRIPTION
    This function connects to a remote computer and installs available Windows updates.
    It provides various options to control the installation process and display update details.
    
    .PARAMETER ComputerName
    NotMandatory - name of the remote computer where updates will be installed.
    .PARAMETER Username
    NotMandatory - username used to authenticate to the remote computer.
    .PARAMETER Pass
    NotMandatory - password for the provided username used to authenticate to the remote computer.
    .PARAMETER IncludeHidden
    NotMandatory - if specified, hidden updates will also be installed.
    .PARAMETER IncludeInstalled
    NotMandatory - if specified, already installed updates will be reinstalled.
    .PARAMETER IncludeRebootRequired
    NotMandatory - if specified, updates requiring a system reboot will also be installed.
    .PARAMETER Reboot
    NotMandatory - if specified, reboot the remote computer after updates are installed.
    .PARAMETER RebootDelay
    NotMandatory - specify the delay in seconds before initiating a reboot.
    .PARAMETER Wait
    NotMandatory - if specified, wait for the specified number of seconds before proceeding with installation.
    .PARAMETER ShowProgress
    NotMandatory - if specified, show progress of update installation.
    .PARAMETER ShowUpdateDetails
    NotMandatory - if specified, show details about available updates on the remote computer.
    
    .EXAMPLE
    InstallWindowsUpdates -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass" -IncludeRebootRequired -Reboot -RebootDelay 300 -Wait 60 -ShowProgress -ShowUpdateDetails -Verbose
    
    .NOTES
    v0.0.4
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify the remote computer name")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Provide the username for remote authentication")]
        [string]$Username,

        [Parameter(Mandatory = $false, HelpMessage = "Provide the password for the specified username")]
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "Install hidden updates")]
        [switch]$IncludeHidden,

        [Parameter(Mandatory = $false, HelpMessage = "Reinstall already installed updates")]
        [switch]$IncludeInstalled,

        [Parameter(Mandatory = $false, HelpMessage = "Install updates requiring a system reboot")]
        [switch]$IncludeRebootRequired,

        [Parameter(Mandatory = $false, HelpMessage = "Reboot the remote computer after updates are installed")]
        [switch]$Reboot,

        [Parameter(Mandatory = $false, HelpMessage = "Delay in seconds before initiating a reboot")]
        [int]$RebootDelay = 300,

        [Parameter(Mandatory = $false, HelpMessage = "Wait for the specified number of seconds before proceeding with installation")]
        [int]$Wait = 0,

        [Parameter(Mandatory = $false, HelpMessage = "Show progress of update installation")]
        [switch]$ShowProgress,

        [Parameter(Mandatory = $false, HelpMessage = "Show details about available updates on the remote computer")]
        [switch]$ShowUpdateDetails
    )
    try {
        $Credential = $null
        if ($Username -and $Pass) {
            $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePassword
        }
        if ($ShowUpdateDetails) {
            $UpdateSession = New-Object -ComObject Microsoft.Update.Session
            $Searcher = $UpdateSession.CreateUpdateSearcher()
            $SearchResult = $Searcher.Search("IsInstalled=0")
            $SearchResult.Updates | Select-Object Title, Description, IsHidden, IsMandatory, RebootRequired, LastDeploymentChangeTime, MoreInfoUrls
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
                $Criteria = "IsInstalled=1"
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
            Write-Verbose -Message "Establishing a remote session with $ComputerName..."
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
            Write-Verbose -Message "Installing Windows updates remotely..."
            Invoke-Command -Session $Session -ScriptBlock $InstallScriptBlock -ArgumentList $IncludeHidden, $IncludeInstalled, $IncludeRebootRequired, $ShowProgress
            if ($Session) {
                Write-Verbose -Message "Removing the remote session with $ComputerName..."
                Remove-PSSession -Session $Session -ErrorAction SilentlyContinue
            }
        }
        else {
            Write-Verbose -Message "Installing Windows updates locally..."
            & $InstallScriptBlock -IncludeHidden $IncludeHidden -IncludeInstalled $IncludeInstalled -IncludeRebootRequired $IncludeRebootRequired -ShowProgress $ShowProgress
        }
        if ($Reboot) {
            Write-Verbose -Message "Rebooting the computer in $RebootDelay seconds..."
            Start-Sleep -Seconds $RebootDelay
            Restart-Computer -Force
        }
        if ($Wait -gt 0) {
            Write-Verbose -Message "Waiting for $Wait seconds..."
            Start-Sleep -Seconds $Wait
        }
    }
    catch {
        Write-Error -Message "Failed to install Windows updates: $_"
    }
}
