Function RemoteUserState {
    <#
    .SYNOPSIS
    Retrieves user status and additional information on a remote computer.

    .DESCRIPTION
    This function retrieves the user status, running processes, active sessions, hardware information, and network information on a remote computer, it requires the computer name, username, and password for authentication. It can also generate a secure password if specified.

    .PARAMETER ComputerName
    Mandatory - name of the remote computer.
    .PARAMETER UserName
    Mandatory - username for authentication.
    .PARAMETER Pass
    Mandatory - password for authentication.
    .PARAMETER GenerateSecurePassword
    NotMandatory - whether to generate a secure password. If specified, a secure password will be generated using the Membership.GeneratePassword method.
    .PARAMETER IncludeProcesses
    NotMandatory - running processes on the remote computer.
    .PARAMETER IncludeSessions
    NotMandatory - the active sessions on the remote computer.
    .PARAMETER IncludeHardware
    NotMandatory - hardware information, including manufacturer, model, and total physical memory.
    .PARAMETER IncludeNetwork
    NotMandatory - retrieves network information, including description and IP addresses.

    .EXAMPLE
    RemoteUserState -ComputerName "" -UserName "" -Pass "" -IncludeSessions
    RemoteUserState -ComputerName "" -UserName "" -Pass "" -IncludeProcesses
    RemoteUserState -ComputerName "" -UserName "" -Pass "" -IncludeHardware -Verbose
    RemoteUserState -ComputerName "" -UserName "" -Pass "" -IncludeNetwork -Verbose

    .NOTES
    This function requires administrative privileges on the remote computer for retrieving certain information.

    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string]$ComputerName,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$UserName,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Pass,

        [Parameter(Mandatory = $false, Position = 2)]
        [switch]$GenerateSecurePassword,

        [Parameter(Mandatory = $false, Position = 3)]
        [switch]$IncludeProcesses,

        [Parameter(Mandatory = $false, Position = 3)]
        [switch]$IncludeSessions,

        [Parameter(Mandatory = $false, Position = 3)]
        [switch]$IncludeHardware,

        [Parameter(Mandatory = $false, Position = 3)]
        [switch]$IncludeNetwork
    )
    BEGIN {
        Write-Verbose -Message "Checking and setting Executing Policy..."
        if ((Get-ExecutionPolicy -Scope CurrentUser) -ne "Unrestricted") {
            Write-Host "Setting Executing Policy to 'Unrestricted'" -ForegroundColor Yellow
            Set-ExecutionPolicy Unrestricted -Scope CurrentUser -Verbose
        }
        Write-Verbose -Message "Elevating script as admin..."
        $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
        $AdminRole = [Security.Principal.WindowsBuiltInRole]::Administrator
        if (-Not $CurrentPrincipal.IsInRole($AdminRole)) {
            Start-Process powershell.exe "-File `"$PSCommandPath`"" -Verb RunAs
            exit
        }
        if ($GenerateSecurePassword) {
            $Password = [System.Web.Security.Membership]::GeneratePassword(12, 4)
            $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        }
        else {
            $SecurePassword = ConvertTo-SecureString $Pass -AsPlainText -Force
        }
        $Credential = New-Object System.Management.Automation.PSCredential ($UserName, $SecurePassword)
    }
    PROCESS {
        try {
            $Result = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName -Credential $Credential `
            | Select-Object -ExpandProperty UserName
            $UsrPrep = $Result -split '\\' | Select-Object -Last 1
            if ($UsrPrep -eq $UserName) {
                Write-Host "$UserName is logged on to $ComputerName" -ForegroundColor Green
                if ($IncludeProcesses) {
                    $Processes = Get-WmiObject -Class Win32_Process -ComputerName $ComputerName -Credential $Credential `
                    | Select-Object -ExpandProperty Name
                    Write-Output "Running processes:"
                    $Processes | ForEach-Object { Write-Output $_ }
                }
                if ($IncludeSessions) {
                    $SessionOutput = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                        quser | Select-Object -Skip 1
                    } -Credential $Credential 
                    if ($SessionOutput) {
                        Write-Output "Active sessions:"
                        $SessionOutput | ForEach-Object {
                            $SessionInfo = $_ -split '\s+'
                            $SessionUser = $SessionInfo[0]
                            $SessionId = $SessionInfo[1]
                            $SessionState = $SessionInfo[2]
                            $SessionIdleTime = $SessionInfo[3]
                            $SessionLogonTime = $SessionInfo[4..($SessionInfo.Length - 1)] -join ' '
                            Write-Output "User: $SessionUser"
                            Write-Output "Session ID: $SessionId"
                            Write-Output "Session State: $SessionState"
                            Write-Output "Idle Time: $SessionIdleTime"
                            Write-Output "Logon Time: $SessionLogonTime"
                        }
                    }
                    else {
                        Write-Warning -Message "No active sessions found."
                    }
                }
                if ($IncludeHardware) {
                    $Hardware = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName -Credential $Credential `
                    | Select-Object -Property Manufacturer, Model, TotalPhysicalMemory
                    Write-Output "Hardware information:"
                    $Hardware | ForEach-Object {
                        Write-Output "Manufacturer: $($_.Manufacturer)"
                        Write-Output "Model: $($_.Model)"
                        Write-Output "Total Physical Memory: $($_.TotalPhysicalMemory) bytes"
                    }
                }
                if ($IncludeNetwork) {
                    $Network = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $ComputerName -Credential $Credential `
                    | Where-Object { $_.IPEnabled } | Select-Object -Property Description, IPAddress
                    Write-Output "Network information:"
                    $Network | ForEach-Object {
                        Write-Output "Description: $($_.Description)"
                        Write-Output "IP Address(es): $($_.IPAddress -join ', ')"
                    }
                }
            }
            else {
                Write-Warning -Message "$UserName is not logged on to $ComputerName"
            }
        }
        catch {
            Write-Error -Message "An error occurred while retrieving user status: $_"
        }
    }
    END {
        Clear-History -ErrorAction SilentlyContinue
        Clear-Variable -Name Credential, Username, Pass -Force -ErrorAction SilentlyContinue
        Remove-Variable -Name Credential, Username, Pass -Force -ErrorAction SilentlyContinue
    }
}
