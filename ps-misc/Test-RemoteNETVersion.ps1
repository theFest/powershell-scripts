Function Test-RemoteNETVersion {
    <#
    .SYNOPSIS
    Checks for installed versions of the .NET Framework on a remote computer and identifies the version currently in use.

    .DESCRIPTION
    This function allows you to check for installed versions of the .NET Framework on a specified remote computer, it also identifies the version that is currently in use on the remote machine. 

    .PARAMETER ComputerName
    Specifies the name of the remote computer, if not provided, the local computer is used by default.
    .PARAMETER User
    Specifies the username for connecting to the remote computer, if not provided, the current user's credentials are used.
    .PARAMETER Pass
    Specifies the password for the specified username, if not provided, the script prompts for the password.
    .PARAMETER RegistryHive
    Specifies the registry hive path where .NET Framework information is stored on the remote computer, default is 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP'.

    .EXAMPLE
    Test-RemoteNETVersion -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$User,

        [Parameter(Mandatory = $false)]
        [string]$Pass,

        [Parameter(Mandatory = $false)]
        [string]$RegistryHive = 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP'
    )
    BEGIN {
        if (-not $Pass) {
            $Credential = Get-Credential -UserName $User -Message "Enter password for user $User"
            $SecPass = $Credential.Password
        }
        else {
            $SecPass = ConvertTo-SecureString $Pass -AsPlainText -Force
        }
        $PSSession = $null
    }
    PROCESS {
        try {
            if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
                Write-Host "Connection to $ComputerName successful." -ForegroundColor Green
                $ScriptBlock = {
                    param ($Hive)
                    Get-ChildItem -Path $Hive -Recurse |
                    Get-ItemProperty -Name Version -ErrorAction SilentlyContinue |
                    Where-Object { $_.Version } | 
                    Select-Object PSComputerName, Version, @{Name = 'InUse'; Expression = { $_.PSComputerName -eq $env:COMPUTERNAME } }
                }
                $SessionParams = @{
                    ScriptBlock = $ScriptBlock
                }
                if ($ComputerName) {
                    $PSSession = New-PSSession -ComputerName $ComputerName -Credential (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecPass)
                    $SessionParams += @{
                        Session = $PSSession
                    }
                }
                $InstalledVersions = Invoke-Command @SessionParams -ArgumentList $RegistryHive
                if ($InstalledVersions) {
                    $InstalledVersions | ForEach-Object {
                        $Status = if ($_.InUse) { " (In Use)" } else { "" }
                        Write-Host ".NET Framework version $($_.Version) is installed on $($_.PSComputerName)$Status." -ForegroundColor Green
                    }
                }
                else {
                    Write-Warning -Message ".NET Framework is not installed on $ComputerName!"
                }
            }
            else {
                throw "Failed to connect to $ComputerName. Please check the connection!"
            }
        }
        catch {
            Write-Error -Message $_.Exception.Message
        }
    }
    END {
        if ($PSSession) {
            Write-Host "Closing remote session..." -ForegroundColor DarkCyan
            Remove-PSSession -Session $PSSession -ErrorAction SilentlyContinue -Verbose
        }
        Write-Verbose -Message "Check completed, exiting!"
    }
}
