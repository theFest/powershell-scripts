Function RunAsOtherUser {
    <#
    .SYNOPSIS
    Execute commands as a specified user account on a local or remote computer.

    .DESCRIPTION
    This function allows a user to execute commands as another user account on a local or remote computer using either PsExec or PaExec tools.
    It provides options to specify the type of execution, the communication type, the switches, the command, the arguments, the username, the password, the computer name, the domain, the working directory, and whether to restart the computer.

    .PARAMETER RunType
    NotMandatory - tool to use for execution, PsExec or PaExec can be used. By default, the value is set to PsExec.
    .PARAMETER CommExecType
    NotMandatory - specifies the communication type to use. PsSession or PsCommand can be used. By default, the value is set to PsCommand.
    .PARAMETER Switches
    NotMandatory - switches to use with the command. Interactive, Elevate, or System can be used. By default, no switch is used.
    .PARAMETER Command
    Mandatory - specifies the command to execute.
    .PARAMETER Arguments
    NotMandatory - arguments to use with the command.
    .PARAMETER Username
    NotMandatory - username of the account to use for execution.
    .PARAMETER Pass
    NotMandatory - password of the Username account to use for execution.
    .PARAMETER ComputerName
    NotMandatory - name of the computer on which to execute the command.
    .PARAMETER Domain
    NotMandatory - domain of the account to use for execution, by default, it is set to the current user domain.
    .PARAMETER WorkingDirectory
    NotMandatory - specifies the working directory for the command.
    .PARAMETER Restart
    NotMandatory - Specifies whether to restart the computer after execution.

    .EXAMPLE
    $Command = "Stop-Service -Name Spooler -Force"
    RunAsOtherUser -Switches System -Command $Command -CommExecType PsCommand -Username "your_user" -Pass "your_pass" -ComputerName "your_computer"

    .NOTES
    v0.1.0
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("PsExec", "PaExec")]
        [string]$RunType = "PsExec",

        [Parameter(Mandatory = $false)]
        [ValidateSet("PsCommand", "PsSession")]
        [string]$CommExecType = "PsCommand",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Interactive", "Elevate", "System", IgnoreCase = $true)]
        [string[]]$Switches,

        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [string]$Arguments,

        [Parameter(Mandatory = $false)]
        [string]$Username,

        [Parameter(Mandatory = $false)]
        [string]$Pass,

        [Parameter(Mandatory = $false)]
        [string]$ComputerName,

        [Parameter(Mandatory = $false)]
        [string]$Domain = $env:USERDOMAIN,

        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory,

        [Parameter()]
        [switch]$Restart
    )
    BEGIN {
        $StartTime = Get-Date
        $ExecFolder = Join-Path -Path $env:TEMP -ChildPath "RunAsOtherUser"
        New-Item -Path $ExecFolder -ItemType Directory -Force -Verbose | Out-Null
        switch ($RunType) {
            "PsExec" {
                $ExecUri = "https://download.sysinternals.com/files/PSTools.zip"
                $ExecZipPath = Join-Path -Path $ExecFolder -ChildPath "PSTools.zip"
                $ExecFileName = "PsExec64.exe"
            }
            "PaExec" {
                $ExecUri = "https://www.poweradmin.com/paexec/paexec.exe"
                $ExecFileName = "paexec.exe"
            }
        }
        $ExecPath = Join-Path -Path $ExecFolder -ChildPath $ExecFileName
        if (!(Test-Path -Path "$ExecFolder\$ExecFileName")) {
            Invoke-WebRequest -Uri $ExecUri -OutFile $ExecZipPath -Verbose
            if ($RunType -eq 'PsExec') {
                Expand-Archive -Path $ExecZipPath -DestinationPath $ExecFolder -Force
                Copy-Item -Path (Join-Path -Path $ExecFolder -ChildPath $ExecFileName) -Destination $ExecPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
    PROCESS {
        $ExecArgs = @{
            accepteula   = $true
            u            = $Username
            p            = $Password
            d            = "NonInteractive" -in $Switches
            i            = "Interactive" -in $Switches
            h            = "Elevate" -in $Switches
            s            = "System" -in $Switches
            w            = $WorkingDirectory
            ComputerName = $ComputerName
        } | Where-Object { $_.Value } | ForEach-Object { "-$($_.Name) '$($_.Value)'" -join " " }
        if ($ComputerName) {
            if (!(Get-Item WSMan:\localhost\Client\TrustedHosts | Select-String $ComputerName)) {
                Write-Verbose "Adding $ComputerName to TrustedHosts..."
                Set-Item WSMan:\localhost\Client\TrustedHosts -Value "$(Get-Item WSMan:\localhost\Client\TrustedHosts),$ComputerName" -Force
            }
            $Credential = New-Object System.Management.Automation.PSCredential("$Domain\$Username", (ConvertTo-SecureString $Pass -AsPlainText -Force))
            if ($CommExecType -eq "PsSession") {
                Write-Verbose -Message "Running command on remote computer $ComputerName"
                $ScriptBlock = {
                    param($Command, $Arguments)
                    Invoke-Expression "$Command $Arguments"
                }
                $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential
                Invoke-Command -Session $Session -ScriptBlock $ScriptBlock -ArgumentList $Command, $Arguments
                Remove-PSSession -Session $Session
            }
            elseif ($CommExecType -eq "PsCommand") {
                $ProcessArgs = "$ExecArgs $Command $Arguments"
                $ScriptBlock = {
                    param($Arguments)
                    Invoke-Expression $Arguments
                }
                $ArgumentList = @($ProcessArgs)
                Invoke-Command -ComputerName $ComputerName -Credential $Credential -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
            }
        }
        else {
            $StartPath = Join-Path -Path $ExecFolder -ChildPath $ExecFileName
            $ProcessArgs = "$ExecArgs $Command $Arguments"
            Write-Verbose -Message "Running command on local computer"
            $Process = Start-Process -FilePath $StartPath -ArgumentList $ProcessArgs -Wait -WindowStyle Normal -PassThru
            if ($Process.ExitCode -ne 0) {
                Write-Host "Command exited with code $($Process.ExitCode)." -ForegroundColor DarkCyan
            }
        }
    }
    END {
        try {
            $null = Get-Process -Name $ExecFileName -ErrorAction Stop
            Write-Verbose "Waiting for $ExecFileName process to exit..."
            do {
                Start-Sleep -Milliseconds 600
            }
            while (Get-Process -Name $ExecFileName -ErrorAction SilentlyContinue)
        }
        catch {
            Write-Warning -Message "Run As Other User has completed, exiting process..." ## ignore any errors if the process is not running
        }
        finally {
            Write-Verbose "Removing $ExecFileName and its parent folder..."
            Remove-Item -Path $ExecFolder -Recurse -Force -ErrorAction SilentlyContinue
        }
        if ($ComputerName) {
            try {
                if (Get-Item WSMan:\localhost\Client\TrustedHosts | Select-String $ComputerName) {
                    Write-Verbose "Removing $ComputerName from TrustedHosts..."
                    Set-Item WSMan:\localhost\Client\TrustedHosts -Value (Get-Item WSMan:\localhost\Client\TrustedHosts | Select-String -NotMatch $ComputerName).ToString() -Force
                }
            }
            catch {
                Write-Warning -Message "Failed to clear trusted hosts for $($ComputerName). Error: $($Error[0].Exception.Message)"
            }
        }
        if ("Interactive" -in $Switches) {
            Write-Output "Press any key to exit..." ## if the switches array contains "Interactive", we need to wait for user input before closing the console window
            $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        }
        $MsgBoxTitle = "RunAsOtherUser" ; $MsgBoxMessage = "The RunAsOtherUser function has completed."
        [System.Windows.Forms.MessageBox]::Show($MsgBoxMessage, $MsgBoxTitle, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        Remove-Variable -Name Arguments, ArgumentList, TrustedHosts, ExecPath, ExecUri, ExecZipPath, ExecFolder, ExecFile, Session, ScriptBlock, Credential -ErrorAction SilentlyContinue
        Write-Output "`nRunAsOtherUser function completed in [$((Get-Date).Subtract($StartTime).Duration() -replace ".{8}$")]"
        if ($Restart) {
            Write-Output "Restarting the machine..."
            Restart-Computer -Force
        }
    }
}
