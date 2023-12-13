Function Invoke-RemotePsExecCommand {
    <#
    .SYNOPSIS
    Executes a remote command on a target computer using PsExec.

    .DESCRIPTION
    This function allows the execution of a command on a remote computer using PsExec. It downloads PsExec if not available locally and executes the specified command remotely.

    .PARAMETER Computer
    Mandatory - the target computer's name or IP address.
    .PARAMETER User
    Mandatory - username for authentication on the target computer.
    .PARAMETER Pass
    Mandatory - password for authentication on the target computer.
    .PARAMETER RemoteExecutablePath
    Mandatory - the path of the executable or script to be executed remotely.
    .PARAMETER AdditionalArgs
    NotMandatory - specifies additional arguments or parameters for the remote command.
    .PARAMETER LocalExecutablePath
    NotMandatory - local path where PsExec is stored. If not provided, it defaults to the system's temporary directory.
    .PARAMETER Wait
    NotMandatory - whether the script should wait for the remote command execution to finish before continuing.
    .PARAMETER NoEula
    NotMandatory - whether to suppress the PsExec EULA agreement banner.
    .PARAMETER AsJob
    NotMandatory - runs the remote command as a background job.
    .PARAMETER SessionId
    NotMandatory - specifies the session ID for the remote execution, either 1(interactive) or 0.

    .EXAMPLE
    Invoke-RemotePsExecCommand -Computer "RemoteComputer" -User "Admin" -Pass "Password" -RemoteExecutablePath "C:\path\to\executable.exe" -Wait

    .NOTES
    v0.0.2
    #>
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Computer,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$User,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Pass,

        [Parameter(Mandatory = $true, Position = 3)]
        [string]$RemoteExecutablePath,

        [Parameter(Mandatory = $false, Position = 4)]
        [string]$AdditionalArgs,

        [Parameter(Mandatory = $false, Position = 5)]
        [string]$LocalExecutablePath,

        [Parameter(Mandatory = $false)]
        [switch]$Wait,

        [Parameter(Mandatory = $false)]
        [switch]$NoEula,

        [Parameter(Mandatory = $false)]
        [switch]$AsJob,

        [Parameter(Mandatory = $false)]
        [int]$SessionId
    )
    if (-not $LocalExecutablePath) {
        $LocalExecutablePath = Join-Path $env:TEMP "PsExec.exe"
    }
    $PsExecBaseUrl = "https://live.sysinternals.com/"
    $PsExecURL = $PsExecBaseUrl + "PsExec.exe"
    if ($NoEula) {
        $PsExecURL += "?nobanner"
    }
    Write-Verbose -Message "Downloading PsExec from $PsExecURL to $LocalExecutablePath..."
    try {
        Invoke-RestMethod -Uri $PsExecURL -OutFile $LocalExecutablePath -ErrorAction Stop -Verbose
    }
    catch {
        Write-Error -Message "Failed to download PsExec. Make sure you have internet access and try again!"
        return
    }
    $PsexecCommand = "$LocalExecutablePath \\$Computer -accepteula -u $User -p $Pass -i $SessionId -d -s $RemoteExecutablePath"
    if ($AdditionalArgs) {
        $PsexecCommand += " $AdditionalArgs"
    }
    if ($AsJob) {
        $JobScriptBlock = {
            param($PsexecCommand)
            Invoke-Expression $PsexecCommand
        }
        $Job = Start-Job -ScriptBlock $JobScriptBlock -ArgumentList $PsexecCommand
        Write-Verbose -Message "Background job started."
        if ($Wait) {
            $Job | Wait-Job | Out-Null
            Receive-Job -Job $Job
            Write-Verbose -Message "Background job completed."
            Remove-Job -Job $Job -ErrorAction SilentlyContinue
        }
        else {
            $Job
        }
    }
    else {
        try {
            Start-Process -FilePath $LocalExecutablePath -ArgumentList "\\$Computer -accepteula -u $User -p $Pass -i $SessionId -d -s $RemoteExecutablePath $AdditionalArgs" -Wait:$Wait
        }
        catch {
            Write-Error -Message "Failed to execute PsExec command on $Computer. Error: $_"
        }
    }
}
