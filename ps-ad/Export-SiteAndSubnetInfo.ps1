Function Export-SiteAndSubnetInfo {
    <#
    .SYNOPSIS
    Retrieves information about Active Directory sites and their associated subnets.

    .DESCRIPTION
    This function retrieves information about Active Directory sites and their associated subnets. It queries the current forest for site and subnet details and provides an option to export the information to a CSV file.

    .PARAMETER ForestPath
    The LDAP path to the forest. By default, it uses the LDAP path of the RootDSE.
    .PARAMETER ExportPath
    Export the output to a CSV file. If this switch is provided, the function exports the output to the specified file path.

    .EXAMPLE
    Export-SiteAndSubnetInfo -ExportToCsv "C:\ADSiteInventory.csv"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()] #ConfirmImpact = "None"
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false, Position = 1)]
        [string]$ForestPath = "LDAP://RootDSE",

        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true)]
        [string]$ExportPath
    )
    BEGIN {
        Write-Verbose -Message "Starting Script..."
        $OutputData = @()
    }
    PROCESS {
        try {
            $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
            $SiteInfo = $Forest.Sites
            $Configuration = ([ADSI]$ForestPath).configurationNamingContext
            $SubnetsContainer = [ADSI]('LDAP://CN=Subnets,CN=Sites,{0}' -f $Configuration)
            $SubnetsContainerchildren = $SubnetsContainer.Children
            foreach ($Item in $SiteInfo) {
                Write-Verbose -Message ('Site: {0}' -f $Item.Name)
                foreach ($I in $Item.Subnets.Name) {
                    Write-Verbose -Message ('Subnet: {0}' -f $I)
                    $Output = [PSCustomObject]@{
                        SiteName = $Item.Name
                        Subnet   = $I
                    }
                    $SubnetAdditionalInfo = $SubnetsContainerchildren | Where-Object { $_.Name -match $I }
                    if ($SubnetAdditionalInfo) {
                        Write-Verbose -Message ("Subnet: {0} - Description: {1}" -f $I, $SubnetAdditionalInfo.Description)
                        $Output | Add-Member -MemberType NoteProperty -Name Description -Value $SubnetAdditionalInfo.Description
                    }
                    $OutputData += $Output
                }
            }
        }
        catch {
            Write-Warning -Message $Error[0]
        }
    }
    END {
        Write-Verbose -Message "Script Completed"
        if ($ExportPath) {
            $OutputData | Export-Csv -Path $ExportPath -NoTypeInformation
            Write-Verbose -Message "Output exported to $ExportPath"
        }
        return $OutputData
    }
}
