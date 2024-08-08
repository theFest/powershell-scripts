function Search-WindowsUpdates {
    <#
    .SYNOPSIS
    Searches for installed Windows updates based on a specified keyword in the update descriptions on local or remote systems.

    .DESCRIPTION
    This function retrieves a list of installed hotfixes (Windows updates) using the Get-HotFix cmdlet and filters the updates based on the provided keyword in their descriptions. Supports local and remote systems through WinRM. If no keyword is provided, it returns all installed updates.

    .EXAMPLE
    Search-WindowsUpdates
    Search-WindowsUpdates -ComputerName "remote_host" -Username "remote_user" -Password "remote_pass" -Keyword "Critical"

    .NOTES
    v0.4.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Keyword to search for in the update descriptions, leave empty to list all updates")]
        [Alias("k")]
        [string]$Keyword,

        [Parameter(Mandatory = $false, HelpMessage = "Name of the remote computer. If not specified, the local computer is used")]
        [Alias("c")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, HelpMessage = "Username for remote authentication, required if ComputerName is specified")]
        [ValidateNotNullOrEmpty()]
        [Alias("u")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for remote authentication, required if ComputerName is specified")]
        [ValidateNotNullOrEmpty()]
        [Alias("p")]
        [string]$Pass
    )
    BEGIN {
        if ($ComputerName) {
            if (-not $User -or -not $Pass) {
                Write-Error "Both Username and Password are required for remote connections."
                return
            }
            $SecPass = ConvertTo-SecureString $Pass -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ($User, $SecPass)
        }
    }
    PROCESS {
        $ScriptBlock = {
            param ($Keyword)
            try {
                $Updates = Get-HotFix
                if ($Keyword) {
                    $Updates = $Updates | Where-Object { $_.Description -like "*$Keyword*" }
                }
                if ($Updates.Count -eq 0) {
                    Write-Host "No updates found matching the keyword '$Keyword'!" -ForegroundColor Yellow
                }
                else {
                    Write-Host "Updates matching the keyword '$Keyword':" -ForegroundColor DarkCyan
                    $Updates | Format-Table -Property HotFixID, Description, InstalledOn -AutoSize
                }
            }
            catch {
                Write-Error "An error occurred while searching for updates: $_"
            }
        }
        if ($ComputerName) {
            Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock $ScriptBlock -ArgumentList $Keyword
        }
        else {
            & $ScriptBlock -ArgumentList $Keyword
        }
    }
}
