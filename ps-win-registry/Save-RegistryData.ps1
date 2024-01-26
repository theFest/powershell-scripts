Function Save-RegistryData {
    <#
    .SYNOPSIS
    Export registry data to CSV, Excel, or XML formats.

    .DESCRIPTION
    This function retrieves registry data from a specified path, processes it, and exports the results to a file in either CSV, Excel, or XML format.

    .PARAMETER Path
    Specifies the registry path from which to retrieve data.
    .PARAMETER Extension
    Desired output file format, valid values are '.csv', '.xlsx', or '.xml'.
    .PARAMETER Outfile
    Path and base name for the output file, the appropriate file extension is added based on the chosen format.
    .PARAMETER Force
    Force the creation of the output file, overwriting it if it already exists.
    .PARAMETER AutoFilter
    Indicates whether to apply autofilter when exporting to Excel.

    .EXAMPLE
    Save-RegistryData -Path "HKLM:\SOFTWARE\Adobe" -Extension '.csv' -Outfile "$env:USERPROFILE\Desktop\ExportedRegistry"
    Save-RegistryData -Path "HKLM:\SOFTWARE\Adobe" -Extension '.xlsx' -Outfile "$env:USERPROFILE\Desktop\ExportedRegistry"
    Save-RegistryData -Path "HKLM:\SOFTWARE\Adobe" -Extension '.xml' -Outfile "$env:USERPROFILE\Desktop\ExportedRegistry"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({
                if (-not (Test-Path -Path $_ -ErrorAction SilentlyContinue)) {
                    throw "Path $_ does not exist."
                }
                $true
            })]
        [string]$Path,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateSet(".csv", ".xlsx", ".xml")]
        [string]$Extension,

        [Parameter(Mandatory = $true, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$Outfile,

        [Parameter(Mandatory = $false, Position = 3)]
        [switch]$Force,

        [Parameter(Mandatory = $false, Position = 4)]
        [switch]$AutoFilter
    )
    BEGIN {
        if ($Extension -eq ".xlsx" -and -not (Get-Module -ListAvailable | Where-Object Name -eq "ImportExcel")) {
            Write-Warning -Message "ImportExcel module not found. Installing..."
            Install-Module ImportExcel -Scope CurrentUser -Force:$true -Verbose
            Import-Module ImportExcel -Force -Verbose
        }
        $Keys = Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue
        $Results = @()
    }
    PROCESS {
        foreach ($Key in $Keys) {
            foreach ($Property in $Key.PSObject.Properties) {
                Write-Host "Processing $($Property.Name)" -ForegroundColor Green
                foreach ($Name in $Key.Property) {
                    try {
                        $Value = Get-ItemPropertyValue -Path $Key.PSPath -Name $Name
                        $Type = $Key.GetValueKind($Name)
                        $Result = [PSCustomObject]@{
                            Name     = $Property.Name
                            Property = $Name
                            Value    = $Value
                            Type     = $Type
                        }
                        $Results += $Result
                    }
                    catch {
                        Write-Warning -Message "Error processing $Property in $($Key.Name)"
                    }
                }
            }
        }
    }
    END {
        $OutfilePath = $Outfile
        switch -exact ($Extension) {
            ".csv" {
                $OutfilePath += ".csv"
                $Results | Sort-Object Name, Property | Export-Csv -Path $OutfilePath -Encoding UTF8 -Delimiter ';' -NoTypeInformation
            }
            ".xlsx" {
                $OutfilePath += ".xlsx"
                $Results | Sort-Object Name, Property | Export-Excel -AutoSize -BoldTopRow -FreezeTopRow -AutoFilter:$AutoFilter -Path $OutfilePath
            }
            ".xml" {
                $OutfilePath += ".xml"
                $Results | Export-Clixml -Path $OutfilePath
            }
            default {
                Write-Warning -Message "Invalid extension: $Extension!"
                return
            }
        }
        Write-Host "`nExported results to $OutfilePath" -ForegroundColor Green
    }
}
