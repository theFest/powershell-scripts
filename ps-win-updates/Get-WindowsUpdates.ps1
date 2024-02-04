Function Get-WindowsUpdates {
    <#
    .SYNOPSIS
    Retrieves Windows updates information from a local or remote machine.

    .DESCRIPTION
    This function queries Windows updates on a local or remote machine, providing information about available updates based on specified criteria.

    .PARAMETER ComputerName
    Specifies the remote computer name, default is the local machine.
    .PARAMETER User
    Provides the username for remote authentication.
    .PARAMETER Pass
    Provides the password for the specified username.
    .PARAMETER MaxUpdates
    Maximum number of updates to be returned, default is 100.
    .PARAMETER IncludeHidden
    Include hidden updates in the results.
    .PARAMETER IncludeInstalled
    Include installed updates in the results.
    .PARAMETER IncludeRebootRequired
    Include updates requiring a system reboot in the results.
    .PARAMETER OutputFile
    File path where the updates information will be saved.

    .EXAMPLE
    Get-WindowsUpdates -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -MaxUpdates 50 -IncludeHidden -IncludeInstalled -OutputFile "C:\UpdatesInfo.txt"

    .NOTES
    v0.3.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "Specifies the remote computer name. Default is the local machine")]
        [string]$ComputerName = $env:COMPUTERNAME,
    
        [Parameter(Position = 1, HelpMessage = "Provides the username for remote authentication")]
        [string]$User,
    
        [Parameter(Position = 2, HelpMessage = "Provides the password for the specified username")]
        [string]$Pass,
    
        [Parameter(Position = 3, HelpMessage = "Specifies the maximum number of updates to be returned")]
        [int]$MaxUpdates = 100,
    
        [Parameter(Position = 4, HelpMessage = "Switch to include hidden updates in the results")]
        [switch]$IncludeHidden,
    
        [Parameter(Position = 5, HelpMessage = "Switch to include installed updates in the results")]
        [switch]$IncludeInstalled,
    
        [Parameter(Position = 6, HelpMessage = "Switch to include updates requiring a system reboot in the results")]
        [switch]$IncludeRebootRequired,
    
        [Parameter(Position = 7, HelpMessage = "Specifies the file path where the updates information will be saved")]
        [string]$OutputFile
    )
    try {
        $UsingCred = $null
        if ($ComputerName -ne $env:COMPUTERNAME -and $User -and $Pass) {
            Write-Verbose -Message "Creating PSCredential object..."
            $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $UsingCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecurePassword
        }
        $ScriptBlock = {
            param (
                $IncludeHidden,
                $IncludeInstalled,
                $IncludeRebootRequired,
                $MaxUpdates
            )
            $UpdateSession = New-Object -ComObject Microsoft.Update.Session
            $Searcher = $UpdateSession.CreateUpdateSearcher()
            $Criteria = "IsInstalled=0"
            if (-not $IncludeHidden) {
                $Criteria += " and IsHidden=0"
            }
            if (-not $IncludeInstalled) {
                $Criteria += " and IsInstalled=0"
            }
            if (-not $IncludeRebootRequired) {
                $Criteria += " and RebootRequired=0"
            }
            $SearchResult = $Searcher.Search($Criteria)
            $SearchResult.Updates | Select-Object -First $MaxUpdates Title, Description, IsHidden, IsMandatory, RebootRequired
        }
        if ($UsingCred) {
            Write-Verbose -Message "Establishing a remote session with $ComputerName..."
            $Session = New-PSSession -ComputerName $ComputerName -Credential $UsingCred -ErrorAction Stop
            Write-Verbose -Message "Querying Windows updates remotely..."
            $Updates = Invoke-Command -Session $Session -ScriptBlock $ScriptBlock -ArgumentList $IncludeHidden, $IncludeInstalled, $IncludeRebootRequired, $MaxUpdates
            if ($Session) {
                Write-Verbose -Message "Removing the remote session with $ComputerName..."
                Remove-PSSession -Session $Session -ErrorAction SilentlyContinue -Verbose
            }
        }
        else {
            Write-Verbose -Message "Querying Windows updates locally..."
            $Updates = & $ScriptBlock -IncludeHidden $IncludeHidden -IncludeInstalled $IncludeInstalled -IncludeRebootRequired $IncludeRebootRequired -MaxUpdates $MaxUpdates
        }
        if ($OutputFile) {
            Write-Verbose -Message "Writing updates information to the file: $OutputFile..."
            $Updates | Out-File -FilePath $OutputFile -Force
        }
        return $Updates
    }
    catch {
        Write-Error -Message "Failed to retrieve Windows updates: $_"
    }
}
