function Get-UpdateInformation {
    <#
    .SYNOPSIS
    Retrieves information about available Windows updates from a local or remote machine.

    .DESCRIPTION
    This function queries the Windows Update service for available updates. It can filter updates based on installation status, reboot requirements, and whether they are hidden. Results can be saved to a specified file. This function supports remote execution with authentication.

    .EXAMPLE
    Get-UpdateInformation -MaxUpdates 10 -IncludeHidden -OutputFile "C:\Temp\Updates.txt"
    Get-UpdateInformation -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass" -MaxUpdates 5 -IncludeRebootRequired

    .NOTES
    v0.4.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Remote computer name, default is the local machine")]
        [string]$ComputerName = $env:COMPUTERNAME,
    
        [Parameter(Mandatory = $false, HelpMessage = "Provides the username for remote authentication")]
        [string]$User,
    
        [Parameter(Mandatory = $false, HelpMessage = "Provides the password for the specified username")]
        [string]$Pass,
    
        [Parameter(Mandatory = $false, HelpMessage = "Maximum number of updates to be returned")]
        [int]$MaxUpdates = 100,
    
        [Parameter(Mandatory = $false, HelpMessage = "Include hidden updates in the results")]
        [switch]$IncludeHidden,
    
        [Parameter(Mandatory = $false, HelpMessage = "Include installed updates in the results")]
        [switch]$IncludeInstalled,
    
        [Parameter(Mandatory = $false, HelpMessage = "Include updates requiring a system reboot in the results")]
        [switch]$IncludeRebootRequired,
    
        [Parameter(Mandatory = $false, HelpMessage = "File path where the updates information will be saved")]
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
                [switch]$IncludeHidden,
                [switch]$IncludeInstalled,
                [switch]$IncludeRebootRequired,
                [int]$MaxUpdates
            )
            $UpdateSession = New-Object -ComObject Microsoft.Update.Session
            $Searcher = $UpdateSession.CreateUpdateSearcher()
            $Criteria = "IsInstalled=0"
            if (-not $IncludeHidden) {
                $Criteria += " and IsHidden=0"
            }
            if ($IncludeInstalled) {
                $Criteria = $Criteria -replace "IsInstalled=0", "IsInstalled=1"
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
