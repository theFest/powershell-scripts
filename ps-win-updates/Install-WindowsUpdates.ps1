Function Install-WindowsUpdates {
    <#
    .SYNOPSIS
    Install available Windows updates on a remote computer.
    
    .DESCRIPTION
    This function connects to a remote computer and installs available Windows updates, it provides various options to control the installation process and display update details.
    
    .PARAMETER ComputerName
    NotMandatory - name of the remote computer where updates will be installed.
    .PARAMETER Username
    NotMandatory - username used to authenticate to the remote computer.
    .PARAMETER Pass
    NotMandatory - password for the provided username used to authenticate to the remote computer.
    .PARAMETER IncludeHidden
    NotMandatory - hidden updates will also be installed.
    .PARAMETER IncludeInstalled
    NotMandatory - already installed updates will be reinstalled.
    .PARAMETER IncludeRebootRequired
    NotMandatory - updates requiring a system reboot will also be installed.
    .PARAMETER Reboot
    NotMandatory - reboot the remote computer after updates are installed.
    .PARAMETER RebootDelay
    NotMandatory - specify the delay in seconds before initiating a reboot.
    .PARAMETER Wait
    NotMandatory - wait for the specified number of seconds before proceeding with installation.
    .PARAMETER ShowProgress
    NotMandatory - show progress of update installation.
    .PARAMETER ShowUpdateDetails
    NotMandatory - show details about available updates on the remote computer.
    
    .EXAMPLE
    Install-WindowsUpdates -ShowUpdateDetails -Verbose
    Install-WindowsUpdates -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass" -IncludeRebootRequired -Reboot -RebootDelay 300 -Wait 60 -ShowProgress -ShowUpdateDetails
    
    .NOTES
    v0.0.5
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
            Write-Verbose -Message "Establishing a remote session with $ComputerName..."
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
            Write-Verbose -Message "Installing Windows updates remotely..."
            Invoke-Command -Session $Session -ScriptBlock $InstallScriptBlock -ArgumentList $IncludeHidden, $IncludeInstalled, $IncludeRebootRequired, $ShowProgress
            if ($Session) {
                Write-Verbose -Message "Removing the remote session with $ComputerName..."
                Remove-PSSession -Session $Session -ErrorAction SilentlyContinue
            }
            if ($Reboot) {
                Write-Verbose -Message "Rebooting the remote computer in $RebootDelay seconds..."
                Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock {
                    param ($Delay)
                    Start-Sleep -Seconds $Delay
                    Restart-Computer -Force
                } -ArgumentList $RebootDelay
            }
        }
        else {
            Write-Verbose -Message "Installing Windows updates locally..."
            & $InstallScriptBlock -IncludeHidden $IncludeHidden -IncludeInstalled $IncludeInstalled -IncludeRebootRequired $IncludeRebootRequired -ShowProgress $ShowProgress
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
