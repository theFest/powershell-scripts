function Update-WindowsDefender {
    <#
    .SYNOPSIS
    Updates Windows Defender definitions on a local or remote computer using Windows Update.

    .DESCRIPTION
    This function checks for and installs Windows Defender definition updates through Windows Update on the specified computer.
    If remote credentials are provided, it will attempt to execute the update on a remote machine. The function will prompt for confirmation before initiating a restart if required.

    .EXAMPLE
    Update-WindowsDefender -Verbose
    Update-WindowsDefender -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -ConfirmRestart

    .NOTES
    v1.1.0
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Target computer name for updating Windows Defender definitions, defaults to the local computer if not specified")]
        [Alias("c")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Provide the username for remote authentication, required if updating a remote computer")]
        [Alias("u")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Provide the password for remote authentication, required if updating a remote computer")]
        [Alias("p")]
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "Prompt for confirmation before restarting the computer if required")]
        [Alias("r")]
        [switch]$ConfirmRestart
    )
    try {
        $IsRemote = $User -and $Pass
        if ($IsRemote) {
            Write-Verbose -Message "Establishing remote session to $ComputerName..."
            $SessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
            $Credential = New-Object PSCredential -ArgumentList $User, (ConvertTo-SecureString $Pass -AsPlainText -Force)
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -SessionOption $SessionOption
            Write-Verbose -Message "Updating Windows Defender definitions on remote computer $ComputerName..."
            Invoke-Command -Session $Session -ScriptBlock {
                Import-Module PSWindowsUpdate -Verbose      
                Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot | Out-Null
                Write-Host "Update process initiated on $env:COMPUTERNAME" -ForegroundColor DarkCyan
            }
            Write-Host "Windows Defender updates initiated successfully on $ComputerName" -ForegroundColor Green
            Write-Verbose -Message "Removing remote session..."
            Remove-PSSession -Session $Session
        }
        else {
            Write-Verbose -Message "Running locally on $ComputerName..."
            if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
                Write-Verbose -Message "PSWindowsUpdate module not found. Installing..."
                Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
            }
            Import-Module PSWindowsUpdate -Verbose
            Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -IgnoreReboot | Out-Null
            Write-Host "Windows Defender updates initiated successfully on $ComputerName" -ForegroundColor Green
        }
        $RestartNeeded = (Get-WindowsUpdateLog | Select-String -Pattern "requires restart")
        if ($RestartNeeded) {
            Write-Verbose -Message "A restart is required after updating Windows Defender."
            if ($ConfirmRestart) {
                $Confirmation = Read-Host "A restart is required. Do you want to restart now? (Y/N)"
                if ($Confirmation -match "^[yY]") {
                    Write-Verbose -Message "Restarting computer $ComputerName..."
                    Restart-Computer -ComputerName $ComputerName -Force
                }
                else {
                    Write-Warning -Message "Restart canceled. Please restart the computer manually to complete the update."
                }
            }
            else {
                Write-Host "A restart is required. Please restart the computer manually to complete the update." -ForegroundColor Yellow
            }
        }
        else {
            Write-Verbose -Message "No restart is required."
        }
    }
    catch {
        Write-Error -Message "Error updating Windows Defender on ${ComputerName}: $_"
    }
}
