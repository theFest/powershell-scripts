Function Update-TrustedHosts {
    <#
    .SYNOPSIS
    Updates the Trusted Hosts list on the local or remote machine.

    .DESCRIPTION
    This function allows adding, removing, or listing Trusted Hosts on the local machine or a remote machine.  Trusted Hosts are required for remote PowerShell sessions to work without requiring explicit authentication.

    .PARAMETER Hostname
    One or more hostnames or IP addresses to add or remove from the Trusted Hosts list.
    .PARAMETER Action
    Action to perform, accepted values are "Add", "Remove", or "List".
    .PARAMETER ComputerName
    Name of the remote computer on which to perform the operation, if not specified, the operation is performed on the local computer.
    .PARAMETER User
    Specifies the user account to use for the remote session.
    .PARAMETER Pass
    Specifies the password for the user account.

    .EXAMPLE
    Update-TrustedHosts -Action List
    Update-TrustedHosts -Action Add -Hostname "host1", "host2"
    Update-TrustedHosts -Action Remove -Hostname "host1", "host2"
    Update-TrustedHosts -Action List -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"
    Update-TrustedHosts -Action Add -Hostname "host1", "host2" -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"
    Update-TrustedHosts -Action Remove -Hostname "host1", "host2" -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Hostname,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet("Add", "Remove", "List")]
        [string]$Action,

        [Parameter(Mandatory = $false, Position = 2)]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, Position = 3)]
        [string]$User,

        [Parameter(Mandatory = $false, Position = 4)]
        [string]$Pass
    )
    BEGIN {
        if ($Action -eq "List" -and -not $ComputerName) {
            Write-Warning -Message "ComputerName parameter is required for List action!"
            return
        }
        if (($Action -eq "Add" -or $Action -eq "Remove") -and -not $ComputerName) {
            Write-Warning -Message "ComputerName parameter is required for Add and Remove actions!"
            return
        }
        if ($User -and $Pass) {
            $Credential = New-Object System.Management.Automation.PSCredential -ArgumentList @($User, (ConvertTo-SecureString -String $Pass -AsPlainText -Force))
        }
    }
    PROCESS {
        try {
            if ($ComputerName) {
                $Session = New-PSSession -ComputerName $ComputerName -Credential $Credential -ErrorAction Stop
            }
            switch ($Action) {
                "Add" {
                    if ($ComputerName) {
                        $ExistingTrustedHosts = Invoke-Command -Session $Session -ScriptBlock {
                            $CurrentTrustedHosts = Get-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction SilentlyContinue
                            if ($null -eq $CurrentTrustedHosts) {
                                New-Item WSMan:\localhost\Client\TrustedHosts -Force | Out-Null
                                $CurrentTrustedHosts = Get-Item WSMan:\localhost\Client\TrustedHosts
                            }
                            return $CurrentTrustedHosts.Value
                        } -ErrorAction Stop
                    }
                    else {
                        $ExistingTrustedHosts = Get-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction SilentlyContinue
                        if ($null -eq $ExistingTrustedHosts) {
                            New-Item WSMan:\localhost\Client\TrustedHosts -Force | Out-Null
                            $ExistingTrustedHosts = Get-Item WSMan:\localhost\Client\TrustedHosts
                        }
                        $ExistingTrustedHosts = $ExistingTrustedHosts.Value
                    }
                    $NewTrustedHosts = $ExistingTrustedHosts.Split(',') + $Hostname
                    $NewTrustedHosts = $NewTrustedHosts | ForEach-Object { $_.Trim() }
                    $NewTrustedHosts = $NewTrustedHosts | Select-Object -Unique
                    $NewTrustedHostsString = $NewTrustedHosts -join ','
                    if ($ComputerName) {
                        Invoke-Command -Session $Session -ScriptBlock {
                            param($NewTrustedHostsString)
                            Set-Item WSMan:\localhost\Client\TrustedHosts -Value $using:NewTrustedHostsString
                        } -ArgumentList $NewTrustedHostsString -ErrorAction Stop
                    }
                    else {
                        Set-Item WSMan:\localhost\Client\TrustedHosts -Value $NewTrustedHostsString -ErrorAction Stop
                    }
                    Write-Host "Added $($Hostname -join ', ') to Trusted Hosts" -ForegroundColor Green
                }
                "Remove" {
                    if ($ComputerName) {
                        $ExistingTrustedHosts = Invoke-Command -Session $Session -ScriptBlock {
                            $CurrentTrustedHosts = Get-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction SilentlyContinue
                            return $CurrentTrustedHosts.Value
                        } -ErrorAction Stop
                    }
                    else {
                        $ExistingTrustedHosts = Get-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction SilentlyContinue
                        if ($null -eq $ExistingTrustedHosts) {
                            Write-Warning -Message "Trusted Hosts is empty!"
                            return
                        }
                        $ExistingTrustedHosts = $ExistingTrustedHosts.Value
                    }
                    $NewTrustedHosts = $ExistingTrustedHosts.Split(',') | Where-Object { $_ -notin $Hostname }
                    $NewTrustedHostsString = $NewTrustedHosts -join ','
                    if ($ComputerName) {
                        Invoke-Command -Session $Session -ScriptBlock {
                            param($NewTrustedHostsString)
                            Set-Item WSMan:\localhost\Client\TrustedHosts -Value $using:NewTrustedHostsString
                        } -ArgumentList $NewTrustedHostsString -ErrorAction Stop
                    }
                    else {
                        Set-Item WSMan:\localhost\Client\TrustedHosts -Value $NewTrustedHostsString -ErrorAction Stop
                    }
                    Write-Host "Removed $($Hostname -join ', ') from Trusted Hosts." -ForegroundColor Green
                }
                "List" {
                    if ($ComputerName) {
                        $CurrentTrustedHosts = Invoke-Command -Session $Session -ScriptBlock {
                            $CurrentTrustedHosts = Get-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction SilentlyContinue
                            if ($null -ne $CurrentTrustedHosts) {
                                $CurrentTrustedHosts.Value.Split(',') | ForEach-Object { $_.Trim() }
                            }
                            else {
                                Write-Host "Trusted Hosts is empty!" -ForegroundColor Yellow
                            }
                        } -ErrorAction Stop
                    }
                    else {
                        $CurrentTrustedHosts = Get-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction SilentlyContinue
                        if ($null -ne $CurrentTrustedHosts) {
                            $CurrentTrustedHosts.Value.Split(',') | ForEach-Object { $_.Trim() }
                        }
                        else {
                            Write-Host "Trusted Hosts is empty!" -ForegroundColor Yellow
                        }
                    }
                }
            }
        }
        catch {
            Write-Host "Error: $_" -ForegroundColor Red
        }
        finally {
            if ($Session) {
                Remove-PSSession -Session $Session -Verbose
            }
        }
    }
    END {
        if ($Action -eq "List" -and $ComputerName) {
            if ($CurrentTrustedHosts) {
                $CurrentTrustedHosts
            }
            else {
                Write-Host "Trusted Hosts is empty!" -ForegroundColor Yellow
            }
        }
    }
}
