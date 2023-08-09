Function InstallWindowsUpdates {
    <#
    .SYNOPSIS
    Install available Windows updates on a remote computer.
    
    .DESCRIPTION
    This function connects to a remote computer and installs available Windows updates.
    
    .PARAMETER ComputerName
    NotMandatory - name of the remote computer where updates will be installed.
    .PARAMETER Username
    NotMandatory - username used to authenticate to the remote computer.
    .PARAMETER Pass
    NotMandatory - password for the provided username used to authenticate to the remote computer.
    
    .EXAMPLE
    InstallWindowsUpdates -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass" -Verbose
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify the remote computer name")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Provide the username for remote authentication")]
        [string]$Username,

        [Parameter(Mandatory = $false, HelpMessage = "Provide the password for the specified username")]
        [string]$Pass
    )
    try {
        $UsingCred = $null
        if ($ComputerName -ne $env:COMPUTERNAME) {
            Write-Verbose -Message "Creating PSCredential object..."
            if ($Username -and $Pass) {
                $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
                $UsingCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePassword
            }
        }
        $ScriptBlock = {
            $UpdateSession = New-Object -ComObject Microsoft.Update.Session
            $Searcher = $UpdateSession.CreateUpdateSearcher()
            $Criteria = "IsInstalled=0"
            $SearchResult = $Searcher.Search($Criteria)
            $Updates = $SearchResult.Updates | Where-Object { $_.IsDownloaded -eq $true }
            if ($Updates.Count -gt 0) {
                $Installer = $UpdateSession.CreateUpdateInstaller()
                $Installer.Updates = $Updates
                $Installer.Install()
            }
        }
        if ($UsingCred) {
            Write-Verbose -Message "Establishing a remote session with $ComputerName..."
            $Session = New-PSSession -ComputerName $ComputerName -Credential $UsingCred -ErrorAction Stop
            Write-Verbose -Message "Installing Windows updates remotely..."
            Invoke-Command -Session $Session -ScriptBlock $ScriptBlock
            if ($Session) {
                Write-Verbose -Message "Removing the remote session with $ComputerName..."
                Remove-PSSession -Session $Session -ErrorAction SilentlyContinue
            }
        }
        else {
            Write-Verbose -Message "Installing Windows updates locally..."
            & $ScriptBlock
        }
    }
    catch {
        Write-Error -Message "Failed to install Windows updates: $_"
    }
}
