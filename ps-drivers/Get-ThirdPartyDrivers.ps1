Function Get-ThirdPartyDrivers {
    <#
    .SYNOPSIS
    Gets a list of all installed third-party drivers.

    .DESCRIPTION
    This function retrieves a list of all third-party drivers installed on the system and displays detailed information about each driver. It provides options to filter based on various criteria and remove outdated drivers.

    .PARAMETER Operation
    NotMandatory - type of operation to perform on each driver. The options are: "Name", "FileName", "Entr", "ClassName", "Vendor", "Date", and "Version". Defaults to "Name".
    .PARAMETER Outdated
    NotMandatory - displays a list of all third-party drivers with different versions.
    .PARAMETER RemoveOutdated
    NotMandatory - if present, removes all outdated third-party drivers from the system.

    .EXAMPLE
    Get-ThirdPartyDrivers
    Get-ThirdPartyDrivers -Outdated
    Get-ThirdPartyDrivers -RemoveOutdated

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Name", "FileName", "Entr", "ClassName", "Vendor", "Date", "Version")]
        [string]$Operation = "Name",

        [Parameter(Mandatory = $false)]
        [switch]$Outdated,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveOutdated
    )
    try {
        $DismOut = dism /online /get-drivers
        $Lines = $DismOut | Select-Object -Skip 10
        $Drivers = foreach ($Line in $Lines) {
            $Tmp = $Line
            $Txt = $($Tmp.Split(':'))[1].Trim()
            switch ($Operation) {
                "Name" {
                    $Name = $Txt
                    $Operation = "FileName"
                    break
                }
                "FileName" {
                    $FileName = $Txt
                    $Operation = "Entr"
                    break
                }
                "Entr" {
                    $Entr = $txt
                    $Operation = "ClassName"
                    break
                }
                "ClassName" {
                    $ClassName = $Txt
                    $Operation = "Vendor"
                    break
                }
                "Vendor" {
                    $Vendor = $Txt
                    $Operation = "Date"
                    break
                }
                "Date" {
                    $Tmp = $Txt.split('.')
                    $Date = "$($Tmp[2]).$($Tmp[1]).$($Tmp[0].Trim())"
                    $Operation = 'Version'
                    break
                }
                "Version" {
                    $Version = $Txt
                    $Operation = "Null"
                    $Params = @{
                        'FileName'  = $FileName
                        'Vendor'    = $Vendor
                        'Date'      = $Date
                        'Name'      = $Name
                        'ClassName' = $ClassName
                        'Version'   = $Version
                        'Entr'      = $Entr
                    }
                    New-Object -TypeName PSObject -Property $Params
                    break
                }
                "Null" {
                    $Operation = "Name"
                    break
                }
            }
        }
        if ($Outdated) {
            Write-Host "Different versions" -ForegroundColor Yellow
            $UniqueDrivers = $Drivers | Select-Object -Unique FileName
            $UniqueDrivers | Sort-Object FileName | Format-Table
        }
        if ($RemoveOutdated) {
            Write-Host "Removing outdated drivers..." -ForegroundColor DarkYellow
            $UniqueFiles = $Drivers | Select-Object -Unique FileName
            $ToDel = foreach ($File in $UniqueFiles) {
                $sel = $Drivers | Where-Object { $_.FileName -eq $File.FileName } | Sort-Object Date -Descending | Select-Object -Skip 1
                $sel
            }
            $ToDel | ForEach-Object {
                $DriverName = $_.Name.Trim()
                Write-Host "Removing $DriverName..." -ForegroundColor Yellow
                pnputil.exe /delete-driver $DriverName /force
            }
        }
        else {
            Write-Host "All installed third-party drivers" -ForegroundColor Cyan
            $Drivers | Sort-Object FileName | Format-Table
        }
    }
    catch {
        Write-Error -Message "An error occurred: $_"
    }
}
