function Export-SiteAndSubnetInfo {
    <#
    .SYNOPSIS
    Export Active Directory site and subnet information to a CSV file.

    .DESCRIPTION
    This function retrieves information about Active Directory sites and their associated subnets. It exports this information to a CSV file if the `ExportPath` parameter is provided.
    Function can optionally include additional descriptions of subnets if the `IncludeDescriptions` switch is used. This script is useful for auditing or reporting on the AD site and subnet configuration.

    .EXAMPLE
    Export-SiteAndSubnetInfo -ExportPath "$env:USERPROFILE\Desktop\ADSiteInventory.csv" -IncludeDescriptions

    .NOTES
    v0.1.1
    #>
    [CmdletBinding(ConfirmImpact = "None")]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Specifies the LDAP path to the Active Directory forest, default is 'LDAP://RootDSE'")]
        [string]$ForestPath = "LDAP://RootDSE",
    
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, HelpMessage = "Path to which the CSV file should be exported. If not specified, data will not be exported to a file")]
        [string]$ExportPath,
    
        [Parameter(Mandatory = $false, HelpMessage = "Include this switch to add descriptions of subnets to the output. If not used, only site and subnet names will be included")]
        [switch]$IncludeDescriptions
    )
    BEGIN {
        $OutputData = @()
    }
    PROCESS {
        try {
            $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            $SiteInfo = $Forest.Sites
            $Configuration = ([ADSI]$ForestPath).configurationNamingContext
            $SubnetsContainer = [ADSI]("LDAP://CN=Subnets,CN=Sites,$Configuration")
            $SubnetsContainerChildren = $SubnetsContainer.Children
            foreach ($Site in $SiteInfo) {
                Write-Verbose -Message ("Processing Site: {0}" -f $Site.Name)
                foreach ($SubnetName in $Site.Subnets.Name) {
                    Write-Verbose -Message ("Processing Subnet: {0}" -f $SubnetName)
                    $Output = [PSCustomObject]@{
                        SiteName = $Site.Name
                        Subnet   = $SubnetName
                    }
                    if ($IncludeDescriptions) {
                        $SubnetInfo = $SubnetsContainerChildren | Where-Object { $_.Name -eq $SubnetName }
                        if ($SubnetInfo) {
                            Write-Verbose -Message ("Adding Description for Subnet: {0}" -f $SubnetName)
                            $Output | Add-Member -MemberType NoteProperty -Name Description -Value $SubnetInfo.Description -Force
                        }
                        else {
                            Write-Warning -Message ("No additional information found for Subnet: {0}" -f $SubnetName)
                        }
                    }
                    $OutputData += $Output
                }
            }
        }
        catch {
            Write-Warning -Message ("Error encountered: {0}" -f $_.Exception.Message)
        }
    }
    END {
        if ($ExportPath) {
            try {
                if ($OutputData.Count -gt 0) {
                    $OutputData | Export-Csv -Path $ExportPath -NoTypeInformation -Force
                    Write-Verbose -Message ("Output successfully exported to {0}" -f $ExportPath)
                }
                else {
                    Write-Warning -Message ("No data to export. The output file will not be created.")
                }
            }
            catch {
                Write-Warning -Message ("Failed to export data to $ExportPath : {0}" -f $_.Exception.Message)
            }
        }
        return $OutputData
    }
}
