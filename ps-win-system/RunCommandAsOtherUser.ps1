Function RunCommandAsOtherUser {
    <#
    .SYNOPSIS
    Run a command as other user.

    .DESCRIPTION
    This function allows running a command as a different user by providing the username and password.

    .PARAMETER Command
    Mandatory - command to be executed.
    .PARAMETER Username
    Mandatory - username of the user to run the command as.
    .PARAMETER Pass
    Mandatory - password of the user to run the command as user.
    .PARAMETER Arguments
    NotMandatory - Optional arguments to be passed to the command.
    .PARAMETER Wait
    NotMandatory - specifies whether to wait for the command to complete or not.

    .EXAMPLE
    $Command = "PowerShell"
    $Arguments = "-noExit"
    $Username = "Administrator"
    $Pass = "_Pass1234!"
    $ExecXc = RunCommandAsOtherUser -Command $Command -Arguments $Arguments -Username $Username -Pass $Pass -Wait
    if ($ExecXc -eq 0) {
        Write-Host "Command executed successfully." -ForegroundColor Green
    }
    else {
        Write-Host "Command failed with exit code $($ExecXc)." -ForegroundColor DarkRed
    }

    .NOTES
    v0.1.0
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Command,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Username,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Pass,

        [Parameter(Mandatory = $false)]
        [string]$Arguments,

        [switch]$Wait
    )
    $SecPass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username, $SecPass
    $ProcStartInfo = [System.Diagnostics.ProcessStartInfo] @{
        FileName               = $Command
        Arguments              = $Arguments
        UseShellExecute        = $false
        RedirectStandardOutput = $true
        RedirectStandardError  = $true
        UserName               = $Cred.UserName
        Password               = $Cred.Password
    }
    $Proc = [System.Diagnostics.Process]::new()
    $Proc.StartInfo = $ProcStartInfo
    if ($Wait) {
        $Proc.Start() | Out-Null
        $Proc.WaitForExit()
        return $Proc.ExitCode
    }
    else {
        return $Proc.Start()
    }
}
