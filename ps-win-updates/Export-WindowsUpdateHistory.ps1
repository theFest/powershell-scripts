function Export-WindowsUpdateHistory {
    <#
    .SYNOPSIS
    Exports Windows Update history to a CSV file.

    .DESCRIPTION
    This function retrieves information about installed updates using the Get-HotFix cmdlet and exports the data to a CSV file, exported file includes details such as HotFixID, Description, and InstalledOn.

    .EXAMPLE
    Export-WindowsUpdateHistory -Verbose
    Export-WindowsUpdateHistory -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.3.0
    #>
    param (
        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Specify the remote computer name")]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Provide the username for remote authentication")]
        [string]$User,

        [Parameter(Mandatory = $false, Position = 4, HelpMessage = "Provide the password for the specified username")]
        [string]$Pass,

        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Specify the output path for the CSV file")]
        [string]$OutputPath = "$env:USERPROFILE\Desktop\win_update_history.csv",

        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Specify the number of update entries to export")]
        [int]$NumberOfEntries = 100
    )
    try {
        Write-Host "Retrieving Windows Update history from $ComputerName..." -ForegroundColor Cyan
        $Credential = $null
        if ($User -and $Pass) {
            $SecurePassword = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecurePassword
        }
        $ScriptBlock = {
            param (
                [int]$NumberOfEntries
            )
            Get-HotFix | Select-Object -First $NumberOfEntries
        }
        if ($ComputerName -ne $env:COMPUTERNAME) {
            Write-Host "Establishing a remote session with $ComputerName..." -ForegroundColor DarkCyan
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
            $UpdateHistory = Invoke-Command -Session $Session -ScriptBlock $ScriptBlock -ArgumentList $NumberOfEntries
            Remove-PSSession -Session $Session -Verbose -ErrorAction SilentlyContinue
        }
        else {
            $UpdateHistory = & $ScriptBlock -NumberOfEntries $NumberOfEntries
        }
        if ($null -eq $UpdateHistory -or $UpdateHistory.Count -eq 0) {
            throw "No update history data available!"
        }
        $UpdateHistory | Export-Csv -Path $OutputPath -NoTypeInformation -Force
        Write-Host "Windows Update history exported to $OutputPath" -ForegroundColor Green
    }
    catch {
        Write-Error -Message "Error: $_"
    }
}
