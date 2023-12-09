Function Remove-OutdatedDrivers {
    <#
    .SYNOPSIS
    Checks and removes outdated drivers.

    .DESCRIPTION
    This function checks for outdated drivers and can remove them forcefully if required, with the option to specify the output format.

    .PARAMETER OutputFormat
    NotMandatory - Specifies the output format as either 'Table' or 'List'.
    .PARAMETER RemoveOutdated
    NotMandatory - Use this switch if you want to remove outdated drivers.
    .PARAMETER Force
    NotMandatory - Use with RemoveOutdated to forcefully remove drivers without confirmation.

    .EXAMPLE
    Remove-OutdatedDrivers -RemoveOutdated -Force -Verbose

    .NOTES
    v0.0.2
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("Table", "List")]
        [string]$OutputFormat = "Table",

        [Parameter(Mandatory = $false)]
        [switch]$RemoveOutdated,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Administrator privileges are required to run this function."
    }
    Write-Verbose -Message "Getting a list of all drivers on the system..."
    $DriverList = dism /online /get-drivers
    $DriverLines = $DriverList | Select-Object -Skip 10
    Write-Verbose -Message "Creating an object for each driver with the filename and name properties..."
    $Drivers = foreach ($Line in $DriverLines) {
        $Fields = $Line.Split(':', 2) | ForEach-Object { $_.Trim() }
        [PSCustomObject] @{
            FileName = $Fields[0]
            Name     = $Fields[1]
        }
    }
    Write-Verbose -Message "Getting a list of outdated drivers..."
    $OutdatedDrivers = $Drivers | Group-Object FileName | Where-Object { $_.Count -gt 1 } `
    | ForEach-Object { $_.Group | Sort-Object Name | Select-Object -Last 1 }
    if ($OutdatedDrivers) {
        Write-Host "Outdated drivers:" -ForegroundColor DarkGray
        if ($OutputFormat -eq 'Table') {
            $OutdatedDrivers | Format-Table -AutoSize
        }
        else {
            $OutdatedDrivers | Format-List
        }
        if ($RemoveOutdated -and $Force) {
            Write-Verbose -Message "Removing outdated drivers without prompting for confirmation"
            $OutdatedDrivers | ForEach-Object {
                $Name = $_.Name
                Write-Warning -Message "Removing driver $Name"
                try {
                    pnputil.exe -d $Name | Out-Null
                }
                catch {
                    Write-Error -Message $_
                }
            }
        }
        elseif ($RemoveOutdated) {
            Write-Verbose -Message "Prompting user for confirmation before removing outdated drivers"
            if ($PSCmdlet.ShouldProcess("Remove outdated drivers?")) {
                $OutdatedDrivers | ForEach-Object {
                    $Name = $_.Name
                    Write-Host "Removing driver $Name" -ForegroundColor Yellow
                    pnputil.exe -d $Name | Out-Null
                }
            }
        }
    }
    else {
        Write-Host "No outdated drivers found." -ForegroundColor Green
    }
}
