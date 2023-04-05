Function ManageThirdPartyDrivers {
    <#
    .SYNOPSIS
    Gets a list of all installed third-party drivers.

    .DESCRIPTION
    This function gets a list of all third-party drivers installed on the system and displays the name, filename, class name, vendor, date, and version of each driver.
    It also provides the ability to filter the list to show only outdated drivers, remove outdated drivers, or resume a previously interrupted removal process.

    .PARAMETER Operation
    NotMandatory - specifies the type of operation to perform on each driver. The options are: "theName", "theFileName", "theEntr", "theClassName", "theVendor", "theDate", and "theVersion". Defaults to "theName".
    .PARAMETER Outdated
    NotMandatory - displays a list of all third-party drivers that have different versions.
    .PARAMETER RemoveOutdated
    NotMandatory - if present, removes all outdated third-party drivers from the system.
    .PARAMETER Resume
    NotMandatory - if present, resumes a previously interrupted removal process.

    .EXAMPLE
    ManageThirdPartyDrivers
    ManageThirdPartyDrivers -Outdated
    ManageThirdPartyDrivers -RemoveOutdated
    ManageThirdPartyDrivers -Resume

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Operation = "theName",
        [switch]$Outdated,
        [switch]$RemoveOutdated,
        [switch]$Resume
    )
    $DismOut = dism /online /get-drivers
    $Lines = $DismOut | Select-Object -Skip 10
    $Drivers = foreach ($Line in $Lines) {
        $tmp = $Line
        $txt = $($tmp.Split(':'))[1]
        switch ($Operation) {
            "theName" {
                $Name = $txt
                $Operation = "theFileName"
                break
            }
            "theFileName" {
                $FileName = $txt.Trim()
                $Operation = "theEntr"
                break
            }
            "theEntr" {
                $Entr = $txt.Trim()
                $Operation = "theClassName"
                break
            }
            "theClassName" {
                $ClassName = $txt.Trim()
                $Operation = "theVendor"
                break
            }
            "theVendor" {
                $Vendor = $txt.Trim()
                $Operation = "theDate"
                break
            }
            "theDate" {
                $tmp = $txt.split('.')
                $txt = "$($tmp[2]).$($tmp[1]).$($tmp[0].Trim())"
                $Date = $txt
                $Operation = 'theVersion'
                break
            }
            "theVersion" {
                $Version = $txt.Trim()
                $Operation = "theNull"
                $Params = [ordered]@{
                    'FileName'  = $FileName
                    'Vendor'    = $Vendor
                    'Date'      = $Date
                    'Name'      = $Name
                    'ClassName' = $ClassName
                    'Version'   = $Version
                    'Entr'      = $Entr
                }
                $Obj = New-Object -TypeName PSObject -Property $Params
                $Obj
                break
            }
            "theNull" {
                $Operation = "theName"
                break
            }
        }
    }
    if ($Outdated) {
        Write-Host "Different versions"
        $Last = ''
        $NotUnique = foreach ($Dr in $($Drivers | Sort-Object FileName)) {
            if ($Dr.FileName -eq $Last) {
                $Dr
            }
            $Last = $Dr.FileName
        }
        $NotUnique | Sort-Object FileName | Format-Table
    }
    if ($RemoveOutdated) {
        Write-Verbose -Message "Removing outdated drivers..."
        $List = $($Drivers | Select-Object -ExpandProperty FileName -Unique)
        $ToDel = foreach ($Dr in $List) {
            Write-Host "Checking for duplicates of $Dr..." -ForegroundColor Yellow
            $sel = $Drivers | Where-Object { $_.FileName -eq $Dr } | Sort-Object Date -Descending | Select-Object -Skip 1
            $sel
        }
        $ToDel | ForEach-Object {
            $Name = $($_.Name).Trim()
            Write-Verbose -Message "Removing $Name..."
            pnputil.exe /delete-driver $Name /force
        }
    }
    else {
        Write-Output "All installed third-party drivers"
        $Drivers | Sort-Object FileName | Format-Table
    }
}
