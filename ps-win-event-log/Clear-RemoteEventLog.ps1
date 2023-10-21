Function Clear-RemoteEventLog {
    <#
    .SYNOPSIS
    Clears event logs on a remote computer.

    .DESCRIPTION
    This function clears event logs on a remote computer. It supports clearing the Application, Security, and System logs.

    .PARAMETER LogName
    Mandatory - name of the event log to clear. Valid values are "Application", "Security", and "System". The default value is "Application".
    .PARAMETER ComputerName
    NotMandatory - name of the remote computer on which to clear the event logs. If not specified, the local computer will be used.
    .PARAMETER Username
    NotMandatory - username to use for authentication on the remote computer.
    .PARAMETER Pass
    NotMandatory - password to use for authentication on the remote computer.

    .EXAMPLE
    Clear-RemoteEventLog -LogName Application -Verbose
    Clear-RemoteEventLog -LogName System -ComputerName "remote_hostname" -Username "remote_user" -Pass "remote_pass" -Verbose

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet("Application", "Security", "System")]
        [string]$LogName,

        [Parameter(Position = 1, Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Position = 2, Mandatory = $false)]
        [string]$Username = $env:USERNAME,

        [Parameter(Position = 3, Mandatory = $false)]
        [string]$Pass
    )
    try {
        $Cred = $null
        if ($Username -and $Pass) {
            $SecString = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecString
        }
        if ($LogName -eq 'Security' -and !([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
            Write-Warning -Message "You must run this command as an administrator to clear the 'Security' log!"
            return
        }
        if ($ComputerName -eq $env:COMPUTERNAME) {
            if ($LogName -eq "All") {
                $LogNames = Get-WinEvent -ListLog * | Select-Object -ExpandProperty LogName
            }
            else {
                $LogNames = $LogName
            }
            foreach ($Log in $LogNames) {
                Clear-EventLog -LogName $Log -ErrorAction SilentlyContinue
                Write-Host "Successfully cleared the '$Log' log on the local computer" -ForegroundColor Green
            }
        }
        else {
            $Session = New-PSSession -ComputerName $ComputerName -Credential $Cred -ErrorAction Stop
            if ($LogName -eq "All") {
                $LogNames = Invoke-Command -Session $Session -ScriptBlock { 
                    Get-WinEvent -ListLog * -ErrorAction SilentlyContinue | Select-Object -ExpandProperty LogName 
                }
            }
            else {
                $LogNames = $LogName
            }
            foreach ($Log in $LogNames) {
                Invoke-Command -Session $Session -ScriptBlock { Clear-EventLog -LogName $Using:Log -ErrorAction Stop }
                Write-Host "Successfully cleared the '$Log' log on the computer '$ComputerName'" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Error -Message "Failed to clear the '$LogName' log on the computer '$ComputerName'. $($Error[0].Exception.Message)"
    }
    finally {
        if ($Session) {
            Write-Verbose -Message "Finished, closing PS Session and exiting..."
            Remove-PSSession -Session $Session -Verbose -ErrorAction SilentlyContinue
        }
    }
}
