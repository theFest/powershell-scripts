function Get-WindowsUpdateDriverInfo {
    <#
    .SYNOPSIS
    Retrieves information about available Windows driver updates.

    .DESCRIPTION
    This function connects to Windows Update to search for driver updates that are not currently installed, providing a summary or detailed information about the available updates.

    .EXAMPLE
    Get-WindowsUpdateDriverInfo -ShowDetails -Verbose
    Get-WindowsUpdateDriverInfo -ShowDetails -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Display detailed information about each driver update")]
        [switch]$ShowDetails,

        [Parameter(Mandatory = $false, HelpMessage = "Name of the remote computer, if not specified, the local computer will be used")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Password for the specified username, if required")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Username to use for remote connection, if required")]
        [string]$Pass
    )
    if ($User -and $Pass) {
        $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
        $Credential = New-Object System.Management.Automation.PSCredential($User, $SecurePassword)
    }
    $ScriptBlock = {
        param ($ShowDetails)
        try {
            $DriverUpdateSession = New-Object -ComObject Microsoft.Update.Session
            $DriverUpdateSearcher = $DriverUpdateSession.CreateUpdateSearcher()
            $DriverUpdates = $DriverUpdateSearcher.Search("IsInstalled=0 AND Type='Driver'")
            if ($DriverUpdates.Updates.Count -eq 0) {
                Write-Host "No driver updates found!" -ForegroundColor DarkCyan
            }
            else {
                Write-Host "Driver updates available:"
                $DriverUpdates.Updates | ForEach-Object {
                    if ($ShowDetails) {
                        Write-Host "  Title: $($_.Title)"
                        Write-Host "  Description: $($_.Description)"
                        Write-Host "  Support URL: $($_.SupportUrl)"
                        Write-Host "  Update ID: $($_.Identity.UpdateID)"
                        Write-Host "  --------------------"
                    }
                    else {
                        Write-Host "  $($_.Title)"
                    }
                }
            }
        }
        catch {
            Write-Error -Message "Error: $_"
        }
    }
    if ($ComputerName -eq $env:COMPUTERNAME) {
        & $ScriptBlock -ShowDetails $ShowDetails
    }
    else {
        Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock $ScriptBlock -ArgumentList $ShowDetails
    }
}
