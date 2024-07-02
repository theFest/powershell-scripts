function Get-MemoryPerProcess {
    <#
    .SYNOPSIS
    Retrieves memory usage statistics for specified processes on local or remote computers.
    
    .DESCRIPTION
    This function retrieves memory usage statistics (WorkingSet) for processes specified by Name parameter. It supports querying both local and remote computers, optionally using credentials for remote authentication.

    .EXAMPLE
    "brave" | Get-MemoryPerProcess -OutputPerProcess -Verbose
    Get-MemoryPerProcess -Name "brave" -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass"

    .NOTES
    v0.3.9
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, HelpMessage = "Name of the process(es) to query")]
        [Alias("n")]
        [string[]]$Name,
        
        [Parameter(Mandatory = $false, HelpMessage = "Name(s) of the remote computer(s) to query")]
        [Alias("c")]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        
        [Parameter(Mandatory = $false, HelpMessage = "Unit of memory to display: KB, MB, or GB")]
        [ValidateSet("KB", "MB", "GB")]
        [Alias("t")]
        [string]$Unit = "MB",
        
        [Parameter(Mandatory = $false, HelpMessage = "Username to authenticate for querying remote computers")]
        [Alias("u")]
        [string]$User,
        
        [Parameter(Mandatory = $false, HelpMessage = "Password to authenticate for querying remote computers")]
        [Alias("p")]
        [string]$Pass,
        
        [Parameter(Mandatory = $false, HelpMessage = "Output memory usage per process")]
        [Alias("op")]
        [switch]$OutputPerProcess
    )
    BEGIN {
        if ($User -or $Pass) {
            $SecurePass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $SecurePass
        }
    }
    PROCESS {
        foreach ($Computer in $ComputerName) {
            Write-Verbose "Querying processes $($Name -join ',') on $Computer"
            try {
                if ($Computer -eq $env:COMPUTERNAME) {
                    $Session = $null
                }
                else {
                    $Session = New-PSSession -ComputerName $Computer -Credential $Credential
                }
                $UnitMultiplier = @{
                    "KB" = 1KB
                    "MB" = 1MB
                    "GB" = 1GB
                }[$Unit]
                $ScriptBlock = {
                    param ($Name, $OutputPerProcess, $UnitMultiplier, $Computer)
                    $Processes = Get-Process -Name $Name | Group-Object -Property Name | ForEach-Object {
                        $MemoryInfo = $_.Group | Measure-Object -Property WorkingSet -Sum -Average
                        if ($OutputPerProcess -and $_.Count -gt 1) {
                            $_.Group | ForEach-Object {
                                [PSCustomObject]@{
                                    Name         = $_.Name
                                    Threads      = $_.Threads.Count
                                    Average      = [math]::Round($_.WorkingSet / $UnitMultiplier, 2)
                                    Sum          = $_.WorkingSet / $UnitMultiplier
                                    ComputerName = $Computer
                                }
                            }
                        }
                        else {
                            [PSCustomObject]@{
                                Name         = $_.Name
                                Threads      = $_.Group.Threads.Count
                                Average      = [math]::Round($MemoryInfo.Average / $UnitMultiplier, 2)
                                Sum          = $MemoryInfo.Sum / $UnitMultiplier
                                ComputerName = $Computer
                            }
                        }
                    }
                    $Processes | ForEach-Object {
                        $_.PSObject.TypeNames.Insert(0, "MyProcessMemory") | Out-Null
                        $_
                    }
                }
                if ($Session) {
                    $Processes = Invoke-Command -Session $Session -ScriptBlock $ScriptBlock -ArgumentList $Name, $OutputPerProcess, $UnitMultiplier, $Computer
                    Remove-PSSession -Session $Session -Verbose
                }
                else {
                    $Processes = & $ScriptBlock $Name $OutputPerProcess $UnitMultiplier $Computer
                }
                $Processes
            }
            catch {
                Write-Error -Message "Error querying processes on $Computer : $_"
            }
        }
    }
    END {
        if ($Pass) {
            Clear-Variable -Name Pass -Force -Verbose
        }
    }
}
