Function GetWindowsUpdates {
    <#
    .SYNOPSIS
    Retrieve information about available Windows updates on a remote computer.
    
    .DESCRIPTION
    This function connects to a remote computer and retrieves information about available Windows updates.
    It provides various options to filter and control the number of updates returned.
    
    .PARAMETER ComputerName
    NotMandatory - name of the remote computer where updates will be checked.
    .PARAMETER Username
    NotMandatory - username used to authenticate to the remote computer.
    .PARAMETER Pass
    NotMandatory - password for the provided username used to authenticate to the remote computer.
    .PARAMETER MaxUpdates
    NotMandatory - maximum number of updates to be returned. Default is 100.
    .PARAMETER IncludeHidden
    NotMandatory - if specified, hidden updates will be included in the results.
    .PARAMETER IncludeInstalled
    NotMandatory - if specified, installed updates will also be included in the results.
    .PARAMETER IncludeRebootRequired
    NotMandatory - if specified, updates requiring a system reboot will also be included in the results.
    .PARAMETER OutputFile
    NotMandatory - if specified, the updates information will be saved to the specified file.
    
    .EXAMPLE
    Get-WindowsUpdates -ComputerName $env:COMPUTERNAME -Verbose
    GetWindowsUpdates -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass" -OutputFile "$env:USERPROFILE\Desktop\Updates.txt" -Verbose
    
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
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the maximum number of updates to be returned")]
        [int]$MaxUpdates = 100,

        [Parameter(Mandatory = $false, HelpMessage = "Include hidden updates in the results")]
        [switch]$IncludeHidden,

        [Parameter(Mandatory = $false, HelpMessage = "Include installed updates in the results")]
        [switch]$IncludeInstalled,

        [Parameter(Mandatory = $false, HelpMessage = "Include updates requiring a system reboot in the results")]
        [switch]$IncludeRebootRequired,

        [Parameter(Mandatory = $false, HelpMessage = "Specify the file path where the updates information will be saved")]
        [string]$OutputFile
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
                Remove-PSSession -Session $Session -ErrorAction SilentlyContinue
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
        $Updates
    }
    catch {
        Write-Error -Message "Failed to retrieve Windows updates: $_"
    }
}
