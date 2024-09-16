function Save-RegistryData {
    <#
    .SYNOPSIS
    Exports data from the Windows registry to a specified file format.

    .DESCRIPTION
    This function exports registry keys and their properties from a specified path into a CSV, XLSX, or XML file.
    Allows recursive searching through the registry and handles different file formats, also includes the option to overwrite existing files, apply AutoFilter for Excel exports and more.

    .EXAMPLE
    Save-RegistryData -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\ProfileList" -Extension '.csv' -Outfile "$env:USERPROFILE\Desktop\ExportedRegistry" -Verbose
    Save-RegistryData -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\ProfileList" -Extension '.xlsx' -Outfile "$env:USERPROFILE\Desktop\ExportedRegistry" -AutoFilter -Force
    Save-RegistryData -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\ProfileList" -Extension '.xml' -Outfile "$env:USERPROFILE\Desktop\ExportedRegistry" -Verbose

    .NOTES
    v0.2.8
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Full registry path from which to export data (e.g., 'HKLM:\SOFTWARE\Adobe')")]
        [ValidateScript({
                if (-not (Test-Path -Path $_ -ErrorAction SilentlyContinue)) {
                    throw "The registry path '$($_)' does not exist!"
                }
                $true
            })]
        [Alias("p")]
        [string]$Path,

        [Parameter(Mandatory = $true, HelpMessage = "Choose the output file format: '.csv', '.xlsx', or '.xml'")]
        [ValidateSet(".csv", ".xlsx", ".xml", IgnoreCase = $true)]
        [Alias("e")]
        [string]$Extension,

        [Parameter(Mandatory = $true, HelpMessage = "Name of the output file (without the extension)")]
        [ValidateNotNullOrEmpty()]
        [Alias("o")]
        [string]$Outfile,

        [Parameter(Mandatory = $false, HelpMessage = "Overwrite the output file if it already exists")]
        [Alias("fo")]
        [switch]$Force,

        [Parameter(Mandatory = $false, HelpMessage = "Enable AutoFilter in the XLSX export (only applicable for '.xlsx' format)")]
        [Alias("af")]
        [switch]$AutoFilter
    )
    BEGIN {
        Write-Verbose -Message "Starting Save-RegistryData with the following parameters:"
        Write-Verbose -Message "`tRegistry Path: $Path"
        Write-Verbose -Message "`tOutput Extension: $Extension"
        Write-Verbose -Message "`tOutput File (without extension): $Outfile"
        Write-Verbose -Message "`tForce overwrite: $Force"
        Write-Verbose -Message "`tEnable AutoFilter (for .xlsx): $AutoFilter"
        if ($Extension -eq ".xlsx" -and -not (Get-Module -ListAvailable | Where-Object Name -eq "ImportExcel")) {
            Write-Verbose -Message "ImportExcel module not found. Attempting to install..."
            try {
                Install-Module -Name ImportExcel -Scope CurrentUser -Force -Verbose
                Import-Module -Name ImportExcel -Force -Verbose
                Write-Verbose -Message "ImportExcel module successfully installed and loaded."
            }
            catch {
                throw "Failed to install or import the ImportExcel module. Please install it manually."
            }
        }
        $Results = @()
        Write-Verbose -Message "Attempting to retrieve registry keys from path: $Path"
        try {
            $Keys = Get-ChildItem -Path $Path -Recurse -ErrorAction Stop
            Write-Verbose -Message "Successfully retrieved registry keys."
        }
        catch {
            throw "Error retrieving registry keys from path: '$Path'."
        }
    }
    PROCESS {
        foreach ($Key in $Keys) {
            Write-Verbose -Message "Processing key: $($Key.PSPath)"
            foreach ($Property in $Key.PSObject.Properties) {
                foreach ($Name in $Key.Property) {
                    try {
                        $Value = Get-ItemPropertyValue -Path $Key.PSPath -Name $Name
                        $Type = $Key.GetValueKind($Name)
                        Write-Verbose -Message "`tProcessing property: $Name, Value: $Value, Type: $Type"
                        $Results += [PSCustomObject]@{
                            Key      = $Key.PSPath
                            Name     = $Property.Name
                            Property = $Name
                            Value    = $Value
                            Type     = $Type
                        }
                    }
                    catch {
                        Write-Warning -Message "Error processing property '$Name' in key '$($Key.PSPath)': $_"
                    }
                }
            }
        }
    }
    END {
        $OutfilePath = "$Outfile$Extension"
        if (Test-Path -Path $OutfilePath -ErrorAction SilentlyContinue) {
            if (-not $Force) {
                throw "The file '$OutfilePath' already exists. Use the -Force parameter to overwrite."
            }
            Write-Verbose -Message "Overwriting existing file: $OutfilePath"
        }
        Write-Verbose -Message "Exporting registry data to '$OutfilePath' using extension '$Extension'."
        try {
            switch ($Extension.ToLower()) {
                ".csv" {
                    Write-Verbose -Message "Exporting to CSV format..."
                    $Results | Sort-Object Key, Name, Property | Export-Csv -Path $OutfilePath -Encoding UTF8 -Delimiter ';' -NoTypeInformation
                }
                ".xlsx" {
                    Write-Verbose -Message "Exporting to XLSX format..."
                    $Results | Sort-Object Key, Name, Property | Export-Excel -Path $OutfilePath -AutoSize -BoldTopRow -FreezeTopRow -AutoFilter:$AutoFilter
                }
                ".xml" {
                    Write-Verbose -Message "Exporting to XML format..."
                    $Results | Sort-Object Key, Name, Property | Export-Clixml -Path $OutfilePath
                }
                default {
                    throw "Unsupported file extension: '$Extension'."
                }
            }
            Write-Host "`nSuccessfully exported registry data to '$OutfilePath'." -ForegroundColor Green
        }
        catch {
            throw "Failed to export data to '$OutfilePath': $_"
        }
    }
}
