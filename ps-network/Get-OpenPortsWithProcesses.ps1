Function Get-OpenPortsWithProcesses {
    <#
    .SYNOPSIS
    Retrieves open ports along with associated processes.

    .DESCRIPTION
    This function retrieves information about open TCP or UDP ports and associated processes. It allows filtering by protocol type and process name.

    .PARAMETER Protocol
    NotMandatory - protocol for which open ports are to be retrieved. Valid values are "TCP" or "UDP". Default is "TCP".
    .PARAMETER ProcessName
    NotMandatory - filters the open ports by the specified process name. If provided, it retrieves open ports associated with the specified process.
    .PARAMETER OutputPath
    NotMandatory - specifies the path for exporting the result to a CSV file.

    .EXAMPLE
    Get-OpenPortsWithProcesses -Protocol "TCP"

    .NOTES
    v0.0.1
    #>
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("TCP", "UDP")]
        [string]$Protocol = "TCP",

        [Parameter(Mandatory = $false)]
        [string]$ProcessName = "",

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )
    $OpenPorts = Get-NetTCPConnection | Where-Object { $_.State -eq 'Listen' }
    if ($Protocol -eq "UDP") {
        $OpenPorts = Get-NetUDPEndpoint | Where-Object { $_.State -eq 'Open' }
    }
    $Result = foreach ($Port in $OpenPorts) {
        $ProcessId = $port.OwningProcess
        $Process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
        $MatchProcessName = if ($ProcessName -ne "") {
            if ($Process) {
                $Process.ProcessName -like $ProcessName
            }
            else {
                $false
            }
        }
        else {
            $true
        }
        if ($MatchProcessName) {
            $PortInfo = [PSCustomObject]@{
                Protocol     = if ($Protocol -eq "UDP") { "UDP" } else { "TCP" }
                LocalAddress = $port.LocalAddress
                LocalPort    = $port.LocalPort
                ProcessName  = if ($process) { $process.ProcessName } else { "N/A" }
                ProcessId    = $processId
            }
            $PortInfo
        }
    }
    if ($OutputPath -ne "") {
        $Result | Export-Csv -Path $OutputPath -NoTypeInformation
    }
    else {
        $Result
    }
}
