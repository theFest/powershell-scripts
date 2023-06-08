Function OutdatedDriversAudit {
    <#
    .SYNOPSIS
    Check and remove outdated drivers.
    
    .DESCRIPTION
    This function can check and forcefully remove outdated drivers, it has outputformat and admin check.
    
    .PARAMETER OutputFormat
    NotMandatory - format out either in Table or List.
    .PARAMETER RemoveOutdated
    NotMandatory - use if want to remove outdated.
    .PARAMETER Force
    NotMandatory - use with RemoveOutdated to forcefully remove drivers.
    
    .EXAMPLE
    OutdatedDriversAudit -Verbose
    OutdatedDriversAudit -RemoveOutdated -Force
    
    .NOTES
    v0.0.1
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
    Write-Verbose -Message "Getting list of outdated drivers..."
    $OutdatedDrivers = $drivers |
    Group-Object FileName |
    Where-Object { $_.Count -gt 1 } |
    ForEach-Object { $_.Group | Sort-Object Name | Select-Object -Last 1 }
    if ($OutdatedDrivers) {
        Write-Host "Outdated drivers:"
        if ($OutputFormat -eq 'Table') {
            $OutdatedDrivers | Format-Table -AutoSize
        }
        else {
            $OutdatedDrivers | Format-List
        }
        if ($RemoveOutdated -and $Force) {
            Write-Verbose -Message "Remove outdated drivers without prompting for confirmation"
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
            Write-Verbose -Message "Prompt user for confirmation before removing outdated drivers"
            if ($PSCmdlet.ShouldProcess("Remove outdated drivers?")) {
                $OutdatedDrivers | ForEach-Object {
                    $Name = $_.Name
                    Write-Host "Removing driver $Name"
                    pnputil.exe -d $Name | Out-Null
                }
            }
        }
    }
    else {
        Write-Host "No outdated drivers found." -ForegroundColor Green
    }
}