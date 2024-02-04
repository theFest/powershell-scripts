Function Get-MemoryPerProcess {
    <#
    .SYNOPSIS
    Retrieves memory information for specified processes.

    .DESCRIPTION
    This function gets memory information (sum and average) for the specified processes running on the local or remote computer.

    .PARAMETER Name
    Specifies the name(s) of the process(es) to query.
    .PARAMETER ComputerName
    The target computer(s) to query, default is the local computer.
    .PARAMETER Unit
    Memory unit for the output, valid values: "KB", "MB", "GB", default is "MB".
    .PARAMETER Username
    Username for authentication to access remote computers.
    .PARAMETER Pass
    Password for authentication to access remote computers.
    .PARAMETER OutputPerProcess
    Provides memory information for each instance of a process.

    .EXAMPLE
    "brave" | Get-MemoryPerProcess -OutputPerProcess -Verbose
    Get-MemoryPerProcess -Name "brave" -ComputerName "remote_host" -Username "remote_user" -Pass "remote_pass"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string[]]$Name,
        
        [Parameter(Mandatory = $false, Position = 1)]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("KB", "MB", "GB")]
        [string]$Unit = "MB",
        
        [Parameter(Mandatory = $false)]
        [string]$Username,
        
        [Parameter(Mandatory = $false)]
        [string]$Pass,

        [Parameter(Mandatory = $false)]
        [switch]$OutputPerProcess
    )
    BEGIN {
        Write-Verbose -Message "Starting $($MyInvocation.MyCommand)"
        if ($Username -or $Pass) {
            $SecurePass = ConvertTo-SecureString -String $Pass -AsPlainText -Force
            $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username, $SecurePass
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
        Clear-Variable -Name Pass -Force -Verbose
        Write-Verbose -Message "Ending $($MyInvocation.MyCommand)"
    }
}
