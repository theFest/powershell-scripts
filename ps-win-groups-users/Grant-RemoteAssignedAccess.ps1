Function Grant-RemoteAssignedAccess {
    <#
    .SYNOPSIS
    Grants assigned access to a specified user on a remote computer for a selected application.

    .DESCRIPTION
    This function allows granting assigned access to a specified user on a remote computer for a selected application. Retrieves the App User Model IDs for available applications on the remote computer and prompts the user to select one.
    Then, it retrieves user accounts on the remote computer (excluding the built-in Administrator account) and prompts the user to select one. Finally, it configures assigned access for the selected user to use the selected application.

    .PARAMETER ComputerName
    Specifies the name of the remote computer.
    .PARAMETER User
    Username used for authentication on the remote computer.
    .PARAMETER Pass
    Password used for authentication on the remote computer.

    .EXAMPLE
    Grant-RemoteAssignedAccess -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true)]
        [string]$User,

        [Parameter(Mandatory = $true)]
        [string]$Pass
    )
    try {
        Write-Verbose -Message "Retrieve the App User Model IDs..."
        $AppUserModelIds = Invoke-Command -ComputerName $ComputerName -Credential (New-Object PSCredential -ArgumentList $User, (ConvertTo-SecureString $Pass -AsPlainText -Force)) -ScriptBlock {
            Get-StartApps | ForEach-Object { $_.AppId }
        } -ErrorAction Stop
        if ($AppUserModelIds.Count -eq 0) {
            Write-Warning -Message "No apps found. Exiting!"
            return
        }
        $AppChoice = Invoke-Command -ScriptBlock {
            $i = 0
            $AppUserModelIds | ForEach-Object {
                Write-Host "$i. $_" -ForegroundColor Cyan
                $i++
            }
            $Choice = Read-Host "Enter the number for your choice"
            return $AppUserModelIds[$Choice]
        }
        Write-Verbose -Message "Retrieve user accounts..."
        $UserAccounts = Invoke-Command -ComputerName $ComputerName -Credential (New-Object PSCredential -ArgumentList $User, (ConvertTo-SecureString $Pass -AsPlainText -Force)) -ScriptBlock {
            Get-WmiObject Win32_UserAccount | Where-Object { $_.Name -ne 'Administrator' } | Select-Object Name, Caption
        } -ErrorAction Stop
        if ($UserAccounts.Count -eq 0) {
            Write-Warning -Message "No user accounts found. Exiting!"
            return
        }
        $UserChoice = Invoke-Command -ScriptBlock {
            $i = 0
            $UserAccounts | ForEach-Object {
                Write-Host "$i. $($_.Caption -replace '.*\\')"
                $i++
            }
            $Choice = Read-Host "Enter the number for your choice"
            return $UserAccounts[$Choice].Caption -replace '.*\\'
        }
        Write-Host "Selected App: $AppChoice"
        Write-Host "Selected User: $UserChoice"
        Write-Verbose -Message "Removing prefixes when adding access..."
        $ScriptBlock = {
            param ($AppChoice, $UserChoice)
            try {
                Set-AssignedAccess -UserName $UserChoice -AppName $AppChoice
                Write-Host "Assigned access configured for $UserChoice to use $AppChoice" -ForegroundColor DarkGreen
            }
            catch {
                Write-Host "Error: $_" -ForegroundColor DarkRed
            }
        }
        Invoke-Command -ComputerName $ComputerName -Credential (New-Object PSCredential -ArgumentList $User, (ConvertTo-SecureString $Pass -AsPlainText -Force)) -ScriptBlock $ScriptBlock -ArgumentList $appChoice, $userChoice
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor DarkRed
    }
}
