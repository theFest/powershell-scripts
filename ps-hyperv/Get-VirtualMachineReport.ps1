Function Get-VirtualMachineReport {
    <#
    .SYNOPSIS
    Retrieves memory-related information for specified virtual machines.

    .DESCRIPTION
    This function fetches memory details such as assigned, demanded, utilization, and settings for a specified virtual machine or a set of virtual machines.

    .PARAMETER VMName
    The name of the virtual machine to retrieve memory information for.
    .PARAMETER VM
    Specifies the virtual machines to retrieve memory information for.
    .PARAMETER Computername
    Specifies the target computer to query. Defaults to the local computer.
    .PARAMETER Low
    Indicates whether to filter and return only the virtual machines with low memory status.
    .PARAMETER ExportPath
    Specifies the file path to export the data.

    .EXAMPLE
    Get-VirtualMachineReport -VMName "your_vm_name" -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(DefaultParameterSetName = "Name")]
    param (
        [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Enter the name of a virtual machine",
            ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "Name")]
        [ValidateNotNullorEmpty()]
        [Alias("n")]
        [string]$VMName = "*",
    
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Enter the name of a virtual machine",
            ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true,
            ParameterSetName = "VM")]
        [ValidateNotNullorEmpty()]
        [Alias("v")]
        [Microsoft.HyperV.PowerShell.VirtualMachine[]]$VM,
    
        [Parameter(Mandatory = $false, ValueFromPipelinebyPropertyName = $true, HelpMessage = "Target computer to query")]
        [ValidateNotNullorEmpty()]
        [Alias("c")]
        [string]$Computername = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false, HelpMessage = "Filter virtual machines with low memory status")]
        [Alias("l")]
        [switch]$Low,

        [Parameter(Mandatory = $false, HelpMessage = "File path to export the data")]
        [Alias("e")]
        [string]$ExportPath
    ) 
    BEGIN {
        Write-Verbose -Message "Starting $($MyInvocation.Mycommand)"  
        $Data = @()
    }
    PROCESS { 
        if ($PSCmdlet.ParameterSetName -eq "Name") {
            try {
                $VirtualMachines = Get-VM -name $VMName -ComputerName $Computername -ErrorAction Stop
            }
            catch {
                Write-Warning -Message "Failed to find VM $VMName on $Computername"
                return
            }
        }
        else {
            $VirtualMachines = $VM
        }
        foreach ($VirtualMachine in $VirtualMachines) {
            try {
                Write-Verbose -Message "Querying memory for $($VirtualMachine.name) on $($Computername.ToUpper())"
                $MemorySettings = Get-VMMemory -VMName $VirtualMachine.name  -ComputerName $Computername -ErrorAction Stop
                if ($MemorySettings) {
                    if ($VirtualMachine.State -eq 'Running') {
                        $Util = [Math]::Round(($VirtualMachine.MemoryDemand / $VirtualMachine.MemoryAssigned) * 100, 2)
                    }
                    else {
                        $Util = 0
                    }    
                    $CpuUsage = try {
                        Get-CimInstance -ClassName Win32_PerfFormattedData_PerfProc_Process -ComputerName $Computername -Filter "Name='_Total'" |
                        Select-Object -ExpandProperty PercentProcessorTime
                    }
                    catch {
                        0
                    }          
                    $NetworkInfo = try {
                        Get-VMNetworkAdapter -VMName $VirtualMachine.Name -ComputerName $Computername -ErrorAction Stop |
                        Select-Object VMName, MacAddress, SwitchName, IPAddresses
                    }
                    catch {
                        [PSCustomObject]@{
                            VMName      = $VirtualMachine.Name
                            MacAddress  = "Not Available"
                            SwitchName  = "Not Available"
                            IPAddresses = @("Not Available")
                        }
                    }
                    $LastReboot = try {
                        Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $Computername |
                        Select-Object LastBootUpTime
                    }
                    catch {
                        [PSCustomObject]@{
                            LastBootUpTime = "Not Available"
                        }
                    }
                    $MemoryInfo = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computername -ErrorAction Stop
                    $TotalMemory = $MemoryInfo.TotalVisibleMemorySize / 1GB
                    $FreeMemory = $MemoryInfo.FreePhysicalMemory / 1GB
                    $UsedMemory = $TotalMemory - $FreeMemory
                    $MemoryAvailable = "$($FreeMemory) GB"
                    $MemoryUsage = "$($UsedMemory) GB"
                    $MemoryAvailablePer = [math]::Round(($FreeMemory / $TotalMemory) * 100, 2)
                    $MemoryUsagePer = [math]::Round(($UsedMemory / $TotalMemory) * 100, 2)
                    $Hash = [ordered]@{
                        Computername       = $VirtualMachine.ComputerName.ToUpper()
                        Name               = $VirtualMachine.Name
                        Status             = $VirtualMachine.MemoryStatus
                        Dynamic            = $VirtualMachine.DynamicMemoryEnabled
                        Assigned           = "$($VirtualMachine.MemoryAssigned / 1GB) GB"
                        Demand             = "$($VirtualMachine.MemoryDemand / 1GB) GB"
                        Utilization        = $Util
                        Startup            = "$($VirtualMachine.MemoryStartup / 1GB) GB"
                        Minimum            = "$($VirtualMachine.MemoryMinimum / 1GB) GB"
                        Maximum            = "$($VirtualMachine.MemoryMaximum / 1GB) GB"
                        Buffer             = $MemorySettings.Buffer
                        Priority           = $MemorySettings.Priority
                        MemoryAvailable    = $MemoryAvailable
                        MemoryUsage        = $MemoryUsage
                        MemoryAvailablePer = $MemoryAvailablePer
                        MemoryUsagePer     = $MemoryUsagePer
                        CPUUsage           = "$($CpuUsage) %"
                        NetworkInfo        = $NetworkInfo
                        LastReboot         = $LastReboot.LastBootUpTime
                    }
                    $Data += New-Object -TypeName PSObject -Property $Hash
                }
            }
            catch {
                throw $_
            }
        }
    }
    END {
        if ($Low) {
            Write-Verbose -Message "Writing Low memory status objects to the pipeline"
            $Data.Where({ $_.Status -eq 'Low' })
        }
        else {
            Write-Verbose -Message "Writing all objects to the pipeline"
            $Data
        }
        if ($ExportPath) {
            try {
                $Data | Export-Csv -Path $ExportPath -NoTypeInformation -Force
                Write-Host "Data exported to $ExportPath" -ForegroundColor Green
            }
            catch {
                Write-Warning -Message "Failed to export data to $ExportPath : $_"
            }
        }
        Write-Verbose -Message "Ending $($MyInvocation.Mycommand)"
    }
}
