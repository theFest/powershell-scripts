function Update-TrustedHosts {
    <#
    .SYNOPSIS
    Updates the WSMan Trusted Hosts list on a local or remote computer.

    .DESCRIPTION
    This cmdlet allows you to add, remove, list, or clear entries in the WSMan Trusted Hosts list.
    This can be done on the local computer or on a specified remote computer. The cmdlet supports providing credentials for remote sessions and includes safety checks to ensure required parameters are provided for each action.

    .EXAMPLE
    Update-TrustedHosts -Action List
    Update-TrustedHosts -Action Add -Hostname "host1", "host2"
    Update-TrustedHosts -Action Remove -Hostname "host1", "host2"
    Update-TrustedHosts -Action List -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"
    Update-TrustedHosts -Action Add -Hostname "host1", "host2" -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"
    Update-TrustedHosts -Action Remove -Hostname "host1", "host2" -ComputerName "remote_host" -User "remote_user" -Pass "remote_pass"

    .NOTES
    v0.3.8
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Hostnames to be added to or removed from the trusted hosts list")]
        [string[]]$Hostname,

        [Parameter(Mandatory = $true, HelpMessage = "Specify the action to perform: 'Add', 'Remove', or 'List'")]
        [ValidateSet("Add", "Remove", "List")]
        [string]$Action,

        [Parameter(Mandatory = $false, HelpMessage = "Remote computer name, if omitted, the action is performed on the local computer")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, HelpMessage = "Username for remote session credentials")]
        [string]$User,

        [Parameter(Mandatory = $false, HelpMessage = "Password for remote session credentials")]
        [string]$Pass,

        [Parameter(Mandatory = $false, HelpMessage = "Clear all trusted hosts entries")]
        [switch]$ClearAll
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
            if ($ClearAll) {
                if ($Session) {
                    Invoke-Command -Session $Session -ScriptBlock {
                        Clear-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction Stop
                    } -ErrorAction Stop
                }
                else {
                    Clear-Item WSMan:\localhost\Client\TrustedHosts -ErrorAction Stop
                }
                Write-Host "Cleared all entries from Trusted Hosts" -ForegroundColor Green
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
