Function Get-ServiceInfo {
    <#
    .SYNOPSIS
    Retrieves information about services on a specified computer.

    .DESCRIPTION
    Retrieves information about services on a local or remote computer, allows filtering by service name, provides options to include or exclude stopped and manually started services, and supports various output formats.

    .PARAMETER ComputerName
    NotMandatory - name of the computer on which to retrieve the service information. If not provided, the local computer is used by default.
    .PARAMETER ServiceName
    NotMandatory - name of the service to retrieve information for. If not provided, information for all services is returned.
    .PARAMETER UserName
    NotMandatory - username to use for authentication when retrieving service information from a remote computer.
    .PARAMETER Password
    NotMandatory - password to use for authentication when retrieving service information from a remote computer, should be provided as a SecureString object.
    .PARAMETER PingBefore
    NotMandatory - indicates whether to ping the specified computer before retrieving the services. This can be useful to verify the computer's availability before performing the operation.
    .PARAMETER IncludeStopped
    NotMandatory - includes stopped services in the retrieved information. By default, stopped services are excluded.
    .PARAMETER IncludeManualStart
    NotMandatory - includes services with a start type of "Manual" in the retrieved information. By default, services with a start type of "Manual" are excluded.
    .PARAMETER SortByStatus
    NotMandatory - sorts the retrieved services by their status.
    .PARAMETER ProcessAsJob
    NotMandatory - executes the retrieval of service information as a background job. This allows for parallel processing and asynchronous execution.
    .PARAMETER FormatAsTable
    NotMandatory - the output as a table, if specified, the output is displayed in a table format.
    .PARAMETER ExportCsvPath
    NotMandatory - specifies the path to export the retrieved service information as a CSV file.
    .PARAMETER FilterWildcard
    NotMandatory - a wildcard pattern used to filter services based on their display names, only services with display names matching the pattern will be included in the output.

    .EXAMPLE
    GetServiceInfo -ComputerName "Server01" -ServiceName "MyService"

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [string]$ComputerName = $env:COMPUTERNAME,

        [Parameter(Mandatory = $false)]
        [string]$ServiceName,

        [Parameter(Mandatory = $false)]
        [string]$UserName,

        [Parameter(Mandatory = $false)]
        [SecureString]$Password,

        [Parameter(Mandatory = $false)]
        [switch]$PingBefore,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeStopped,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeManualStart,

        [Parameter(Mandatory = $false)]
        [switch]$SortByStatus,

        [Parameter(Mandatory = $false)]
        [switch]$ProcessAsJob,

        [Parameter(Mandatory = $false)]
        [switch]$FormatAsTable,

        [Parameter(Mandatory = $false)]
        [string]$ExportCsvPath,

        [Parameter(Mandatory = $false)]
        [string]$FilterWildcard
    )
    BEGIN {
        $params = @{
            ComputerName = $ComputerName
        }
        if ($ServiceName) {
            $params.ServiceName = $ServiceName
        }
        if ($UserName) {
            $params.UserName = $UserName
        }
        if ($Password) {
            $params.Password = $Password
        }
        if ($PingBefore) {
            Write-Host "Pinging $ComputerName before retrieving services..."
            if (-not (Test-Connection -ComputerName $ComputerName -Quiet)) {
                Write-Error -Message "Failed to ping $ComputerName."
                return
            }
        }
    }
    PROCESS {
        try {
            $Services = Get-Service @params
        }
        catch {
            Write-Error "Failed to retrieve services: $($_.Exception.Message)"
            return
        }
        if ($FilterWildcard) {
            $Services = $Services | Where-Object { $_.DisplayName -like $FilterWildcard }
        }
        if (-not $IncludeStopped) {
            $Services = $Services | Where-Object { $_.Status -ne 'Stopped' }
        }
        if (-not $IncludeManualStart) {
            $Services = $Services | Where-Object { $_.StartType -ne 'Manual' }
        }
        if ($SortByStatus) {
            $Services = $Services | Sort-Object -Property Status
        }
        if ($FormatAsTable) {
            $Services | Format-Table -AutoSize
        }
        else {
            foreach ($Service in $Services) {
                $ServiceInfo = [PSCustomObject]@{
                    Name        = $Service.Name
                    DisplayName = $Service.DisplayName
                    Status      = $Service.Status
                    StartType   = $Service.StartType
                    Description = $Service.Description
                    Path        = $Service.PathName
                    Account     = $Service.ServiceAccountName
                    StartName   = $Service.StartName
                }

                if ($ProcessAsJob) {
                    $Job = Start-Job -ScriptBlock {
                        param($Info)
                        Write-Output $Info
                    } -ArgumentList $ServiceInfo

                    $ServiceInfo.JobId = $Job.Id
                }
                Write-Output $ServiceInfo
            }
        }
        if ($ExportCsvPath) {
            $Services | Export-Csv -Path $ExportCsvPath -NoTypeInformation
        }
    }
    END {
        if ($Password) {
            $Password.Dispose()
        }
    }
}
