Function SecInteractivePsExec {
    <#
    .SYNOPSIS
    Function that allows the user to execute a process interactively on a remote computer using PsExec
    
    .DESCRIPTION
    This is a PowerShell function that facilitates running a process interactively on a remote computer. It uses PsExec, a tool from Sysinternals Suite, to achieve remote process execution. The function requires specifying the version of PsExec to use, the target remote computer's name, the remote user's name, the path of the executable to run on the remote computer, and an optional flag to wait for the process to complete before returning.
    
    .PARAMETER PsExecVersion
    Mandatory - version of PsExec to use. Valid options are "latest," "2.20," "2.1," or "2.0." Default value is "latest."
    .PARAMETER RemoteComputerName
    Mandatory - name of the remote computer where the process will be executed.
    .PARAMETER RemoteUserName
    Mandatory - username of the remote user under whose context the process will run on the remote computer.
    .PARAMETER RemoteExecutablePath
    Mandatory - path to the executable that will be run on the remote computer.
    .PARAMETER WaitForProcess
    NotMandatory - if specified, the function will wait for the remote process to complete before returning. If not specified, the function will return immediately after initiating the remote process.

    .EXAMPLE
    "remote_hostname" | SecInteractivePsExec -RemoteUserName "remote_user" -RemoteExecutablePath "C:\Windows\system32\notepad.exe"
    SecInteractivePsExec -PsExecVersion "2.20" -RemoteComputerName "remote_hostname" -RemoteUserName "remote_user" -RemoteExecutablePath "C:\Windows\system32\notepad.exe" -WaitForProcess
    
    .NOTES
    v0.0.1
    #>
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("latest", "2.20", "2.1", "2.0", IgnoreCase = $true)]
        [string]$PsExecVersion = "latest",

        [Parameter(Mandatory = $true, ValueFromPipeline)]
        [string]$RemoteComputerName,

        [Parameter(Mandatory = $true)]
        [string]$RemoteUserName,

        [Parameter(Mandatory = $true)]
        [string]$RemoteExecutablePath,

        [switch]$WaitForProcess
    )
    Function Get-SecureCredentials {
        $Credential = Get-Credential
        $Credential.Password.MakeReadOnly()
        return $Credential
    }
    $PsExecBaseUrl = "https://live.sysinternals.com/"
    switch ($PsExecVersion.ToLower()) {
        "latest" { $PsExecURL = $PsExecBaseUrl + "PsExec.exe"; break }
        "2.20" { $PsExecURL = "https://download.sysinternals.com/files/PSTools.zip"; break }
        "2.1" { $PsExecURL = "https://download.sysinternals.com/files/PsExec_v2.1.zip"; break }
        "2.0" { $PsExecURL = "https://download.sysinternals.com/files/PsExec_v2.0.zip"; break }
        default { throw "Invalid PsExec version specified. Please use 'latest', '2.20', '2.1', or '2.0'." }
    }
    $PsExecLocalPath = "$env:TEMP\PsExec.exe"
    Function DownloadPsExec {
        $ZipFilePath = "$env:TEMP\PsExec.zip"
        Invoke-WebRequest -Uri $PsExecURL -OutFile $ZipFilePath
        Expand-Archive -Path $ZipFilePath -DestinationPath $env:TEMP -Force
        Remove-Item -Path $ZipFilePath -Force
    }
    if ($PsExecVersion -ne "latest") {
        DownloadPsExec
    }
    else {
        Invoke-WebRequest -Uri $PsExecURL -OutFile $PsExecLocalPath -UseBasicParsing -Verbose
    }
    $SecureCredentials = Get-SecureCredentials
    $SecurePassword = $SecureCredentials.Password
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $PsexecCommand = "$PsExecLocalPath \\$RemoteComputerName -accepteula -u $RemoteUserName -p $Password -i 1 -d -s $RemoteExecutablePath"
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"$PsexecCommand`"" -Wait:$WaitForProcess
    if ($PsExecVersion -ne "latest") {
        Remove-Item -Path "$env:TEMP\PsExec.exe" -Force
    }
}
