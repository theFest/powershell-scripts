Function InteractivePsExec {
    <#
    .SYNOPSIS
    InteractivePsExec is a function to securely execute a process remotely on a target computer using PsExec.

    .DESCRIPTION
    InteractivePsExec is a PowerShell function that allows you to securely execute a process on a remote computer using PsExec tool from Sysinternals.
    It handles the download of PsExec if not available locally and provides options to execute the process in the background as a job or wait for the process to complete.

    .PARAMETER Computer
    The name or IP address of the remote computer on which the process will be executed.

    .PARAMETER User
    Mandatory - username to be used for authentication on the remote computer.

    .PARAMETER Pass
    Mandatory - password corresponding to the specified user for authentication on the remote computer.

    .PARAMETER RemoteExecPath
    Mandatory - path of the executable (process) to be run on the remote computer.

    .PARAMETER AdditionalArgs
    NotMandatory - additional arguments to be passed to the executable.

    .PARAMETER LocalPsExecPath
    NotMandatory - local path where the PsExec executable will be downloaded. If not specified, it will be downloaded to the temporary folder.

    .PARAMETER Wait
    NotMandatory - if provided, the function will wait for the process to complete before returning.

    .PARAMETER NoEula
    NotMandatory - if provided, the function will suppress the PsExec EULA banner.

    .PARAMETER AsJob
    NotMandatory - if provided, the process will be executed in the background as a PowerShell job.

    .PARAMETER SessionId
    NotMandatory - session ID to specify the session in which the process should run.

    .EXAMPLE
    InteractivePsExec -Computer "panelxx2" -User "panel" -Pass "5678" -RemoteExecPath "C:\Windows\system32\notepad.exe" -AsJob -SessionId 1
    Description:
    This example executes Notepad.exe on the remote computer "panelxx2" with the provided credentials and runs it in the background as a PowerShell job.

    .EXAMPLE
    InteractivePsExec -Computer "remote_hostname" -User "remote_user" -Pass "remote_pass" -RemoteExecPath "C:\Windows\system32\notepad.exe" -AsJob -SessionId 1
    "remote_hostname" | InteractivePsExec -User "remote_user" -Pass "remote_pass" -RemoteExecPath "C:\Windows\system32\notepad.exe" -Wait -SessionId 1

    .NOTES
    General notes or additional information about the function.
    #>
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Computer,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$User,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Pass,

        [Parameter(Mandatory = $true, Position = 3)]
        [string]$RemoteExecPath,

        [Parameter(Mandatory = $false, Position = 4)]
        [string]$AdditionalArgs,

        [Parameter(Mandatory = $false, Position = 5)]
        [string]$LocalPsExecPath,

        [Parameter(Mandatory = $false)]
        [switch]$Wait,

        [Parameter(Mandatory = $false)]
        [switch]$NoEula,

        [Parameter(Mandatory = $false)]
        [switch]$AsJob,

        [Parameter(Mandatory = $false)]
        [int]$SessionId
    )
    if (-not $LocalPsExecPath) {
        $LocalPsExecPath = Join-Path $env:TEMP "PsExec.exe"
    }
    $PsExecBaseUrl = "https://live.sysinternals.com/"
    $PsExecURL = $PsExecBaseUrl + "PsExec.exe"
    if ($NoEula) {
        $PsExecURL += "?nobanner"
    }
    Write-Verbose -Message "Downloading PsExec from $PsExecURL to $LocalPsExecPath..."
    try {
        Invoke-RestMethod -Uri $PsExecURL -OutFile $LocalPsExecPath -ErrorAction Stop -Verbose
    }
    catch {
        Write-Error "Failed to download PsExec. Make sure you have internet access and try again."
        return
    }
    $PsexecCommand = "$LocalPsExecPath \\$Computer -accepteula -u $User -p $Pass -i $SessionId -d -s $RemoteExecPath"
    if ($AdditionalArgs) {
        $PsexecCommand += " $AdditionalArgs"
    }
    if ($AsJob) {
        $JobScriptBlock = {
            param($PsexecCommand)
            Invoke-Expression $PsexecCommand
        }
        $Job = Start-Job -ScriptBlock $JobScriptBlock -ArgumentList $PsexecCommand
        Write-Verbose "Background job started."
        if ($Wait) {
            $Job | Wait-Job | Out-Null
            Receive-Job $Job
            Write-Verbose "Background job completed."
            Remove-Job $Job -ErrorAction SilentlyContinue
        }
        else {
            $Job
        }
    }
    else {
        try {
            #Invoke-Expression $PsexecCommand
            Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$PsexecCommand`"" -Wait:$WaitForProcess
        }
        catch {
            Write-Error "Failed to execute PsExec command on $Computer. Error: $_"
        }
    }
}
