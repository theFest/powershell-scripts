Function RunScriptAsOtherUser {
    <#
    .SYNOPSIS
    Simple function that allows a script block to be executed as a different user.

    .DESCRIPTION
    This can be useful in situations where a script needs to be run with elevated privileges or in a different user context.
    The function takes in the script block to be executed, the username and password of the user that the script will be run as, and an optional argument list.

    .PARAMETER ScriptBlock
    Mandatory - script block to be executed as a different user.
    .PARAMETER Username
    Mandatory - username of the user that the script will be run as.
    .PARAMETER Pass
    Parameter - the password of the user that the script will be run as.
    .PARAMETER ArgumentList
    NotParameter - optional list of arguments to pass to the script block.
    .PARAMETER WorkingDirectory
    NotParameter - directory in which to run the script block. Defaults to the path of the current PowerShell command.
    .PARAMETER Wait
    NotParameter - specifies whether to wait for the script to complete before returning output.

    .EXAMPLE
    $Script = { Write-Host "Hello" ; pause } #powershell.exe
    $Username = "Administrator"
    $Pass = "!Password1234"
    #$ArgumentList = "-NoExit"
    RunScriptAsOtherUser -Script $Script -Username $Username -Pass $Pass -ArgumentList $ArgumentList -Wait

    .NOTES
    v0.1.0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptBlock,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Username,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Pass,

        [Parameter(Mandatory = $false)]
        [string]$ArgumentList,

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = $PSCommandPath,

        [Parameter(Mandatory = $false)]
        [switch]$Wait
    )
    $SecPass = ConvertTo-SecureString $Pass -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential ($Username, $SecPass)
    $EncScript = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($ScriptBlock))
    $ProcessStartInfo = @{
        FileName               = 'powershell.exe'
        Arguments              = "-NoProfile -NonInteractive -EncodedCommand $EncScript $ArgumentList"
        UseShellExecute        = $false
        RedirectStandardOutput = $true
        RedirectStandardError  = $true
        UserName               = $Cred.UserName
        Password               = $Cred.Password
        WorkingDirectory       = $WorkingDirectory
    }
    $PSVersionMajor = $PSVersionTable.PSVersion.Major
    switch ($PSVersionMajor) {
        5 {
            if ($ArgumentList -and $ArgumentList -notlike '-*') {
                $ProcessStartInfo.Arguments += " $ArgumentList"
            }
            if ($NoProfile) {
                $ProcessStartInfo.Arguments += " -NoProfile"
            }
        }
        7 {
            if ($ArgumentList) {
                $Arguments = $ArgumentList.Split(' ', [StringSplitOptions]::RemoveEmptyEntries)
                if ($NoProfile) {
                    $Arguments += '-NoProfile'
                }
                $ProcessStartInfo.ArgumentList = $Arguments
            }
            else {
                $ProcessStartInfo.ArgumentList = @()
                if ($NoProfile) {
                    $ProcessStartInfo.ArgumentList += '-NoProfile'
                }
            }
        }
        default {
            throw "PowerShell version: $($PSVersionTable.PSVersion) is not supported."
        }
    }
    $Process = [Diagnostics.Process]::new()
    foreach ($Key in $ProcessStartInfo.Keys) {
        $Process.StartInfo.$Key = $ProcessStartInfo[$Key]
    }
    $Process.Start() | Out-Null
    if ($Wait) {
        $Process.WaitForExit()
        return $Process.ExitCode
    }
    $Output = "" ; $ErrorOutput = ""
    $OutputTask = $Process.StandardOutput.ReadToEndAsync()
    $ErrorTask = $Process.StandardError.ReadToEndAsync()
    [Threading.Tasks.Task]::WaitAll($OutputTask, $ErrorTask)
    $Output = $OutputTask.Result
    $ErrorOutput = $ErrorTask.Result
    return $Output, $ErrorOutput
}

# Example 1: Run a script block as a different user and wait for it to complete

