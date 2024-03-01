Function Update-WindowsDefender {
    <#
    .SYNOPSIS
    Updates Windows Defender on a local or remote computer.

    .DESCRIPTION
    This function checks for and installs Windows Defender updates on a specified computer, if remote credentials are provided, it will attempt to execute the update remotely.

    .PARAMETER ComputerName
    Target computer for updating Windows Defender, defaults to the local machine.
    .PARAMETER User
    Username for remote authentication, if not provided, the function runs locally without remote credentials.
    .PARAMETER Pass
    Password for remote authentication, if not provided, the function runs locally without remote credentials.

    .EXAMPLE
    Update-WindowsDefender
    Update-WindowsDefender -ComputerName "fwvmhv" -User "fwv" -Pass "1234"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Pass
    )
    try {
        if (-not $User -or -not $Pass) {
            Write-Host "Running locally without remote credentials" -ForegroundColor DarkCyan
            $DefenderUpdates = $null
        }
        else {
            $SessionOption = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
            $Credential = New-Object PSCredential $User, (ConvertTo-SecureString $Pass -AsPlainText -Force)
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -SessionOption $SessionOption
            $DefenderUpdates = Invoke-Command -Session $Session -ScriptBlock {
                $UpdateSession = New-Object -ComObject Microsoft.Update.Session
                $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
                $SearchResult = $UpdateSearcher.Search("IsInstalled=0 And Type='Software'")
                $SearchResult.Updates
            }
        }
        if ($DefenderUpdates -and $DefenderUpdates.Count -gt 0) {
            if ($Session) {
                Invoke-Command -Session $Session -ArgumentList $DefenderUpdates -ScriptBlock {
                    param($Updates)
                    $UpdateInstaller = (New-Object -ComObject Microsoft.Update.UpdateInstaller)
                    $UpdateInstaller.Updates = $Updates
                    $UpdateInstaller.Install()
                }
            }
            Write-Host "Windows Defender updates installed successfully on $ComputerName" -ForegroundColor Green
        }
        else {
            return "No Windows Defender updates found on $ComputerName."
        }
    }
    catch {
        return "Error updating Windows Defender on ${ComputerName}: $_"
    }
}
