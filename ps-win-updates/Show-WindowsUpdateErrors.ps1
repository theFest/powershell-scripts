function Show-WindowsUpdateErrors {
    <#
    .SYNOPSIS
    Retrieves and displays Windows Update errors from the specified event log, either locally or on a remote computer.

    .DESCRIPTION
    This function retrieves and displays Windows Update errors from the specified event log on either a local or remote computer. It supports querying remote computers by specifying a ComputerName, and optionally, Username and Password for authentication.

    .EXAMPLE
    Show-WindowsUpdateErrors
    Show-WindowsUpdateErrors -ComputerName "remote_pass" -User "remote_pass" -Pass (ConvertTo-SecureString "remote_pass" -AsPlainText -Force)

    .NOTES
    v0.2.7
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Name of the event log to search for Windows Update errors")]
        [ValidateSet("System", "Application", "Security")]
        [string]$LogName = "System",

        [Parameter(Mandatory = $false, HelpMessage = "Target computer to retrieve the Windows Update errors from. If not specified, the local computer is used")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Username to use for remote authentication")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password to use for remote authentication")]
        [System.Security.SecureString]$Pass
    )
    BEGIN {
        $FilterXPath = "*[System[Provider[@Name='Microsoft-Windows-WindowsUpdateClient']]]"
        if ($ComputerName -ne $env:COMPUTERNAME) {
            if ($User -and $Pass) {
                $Credential = New-Object System.Management.Automation.PSCredential($User, $Pass)
            }
            elseif ($User -and -not $Pass) {
                Write-Error -Message "Password must be provided if Username is specified!"
                return
            }
        }
    }
    PROCESS {
        try {
            if ($ComputerName -eq $env:COMPUTERNAME) {
                $ErrorLog = Get-WinEvent -LogName $LogName -FilterXPath $FilterXPath -ErrorAction SilentlyContinue
            }
            else {
                $ErrorLog = Get-WinEvent -ComputerName $ComputerName -Credential $Credential -LogName $LogName -FilterXPath $FilterXPath -ErrorAction SilentlyContinue
            }
            if ($ErrorLog.Count -eq 0) {
                Write-Warning -Message "No Windows Update errors found in the $LogName event log on $ComputerName!"
            }
            else {
                Write-Host "Windows Update Errors on $ComputerName :" -ForegroundColor DarkCyan
                $ErrorLog | ForEach-Object {
                    $Properties = $_.Properties
                    $UpdateDetails = @{
                        "Message"     = $Properties[1].Value
                        "EventID"     = $_.Id
                        "TimeCreated" = $_.TimeCreated
                        "Provider"    = $Properties[0].Value
                        "Level"       = $_.LevelDisplayName
                    }
                    $UpdateDetails
                } | Format-Table -AutoSize
            }
        }
        catch {
            Write-Error -Message "An error occurred while retrieving Windows Update errors: $_"
        }
    }
}
