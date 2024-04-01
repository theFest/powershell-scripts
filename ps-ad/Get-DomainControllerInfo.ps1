Function Get-DomainControllerInfo {
    <#
    .SYNOPSIS
    Retrieves information about domain controllers in the current domain.
    
    .DESCRIPTION
    This function retrieves information about domain controllers in the current Active Directory domain. It can either return information about all domain controllers or find information about a specific domain controller by name. Additionally, it can force rediscovery of domain controllers if needed.
    
    .PARAMETER ComputerName
    Name of the domain controller to retrieve information about. If this parameter is not provided, information about all domain controllers in the domain is retrieved.
    .PARAMETER Discover
    Forces rediscovery of domain controllers, if used, will ignore any cached information and retrieve fresh data about domain controllers.
    
    .EXAMPLE
    Get-DomainControllerInfo
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding(DefaultParameterSetName = "All")]
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "DC")]
        [Alias("c")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, ParameterSetName = "All")]
        [Alias("d")]
        [switch]$Discover
    )
    BEGIN {
        $DirectoryContext = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::New("Domain")
        $SelectProperties = "Name", "Forest", "Domain", "IPAddress", "SiteName", "Roles", "CurrentTime", "HighestCommittedUsn", "OSVersion"
    }
    PROCESS {
        if ($Discover) {
            $LocatorFlag = [System.DirectoryServices.ActiveDirectory.LocatorOptions]::ForceRediscovery
            $Info = ([System.DirectoryServices.ActiveDirectory.DomainController]::FindOne($DirectoryContext, $LocatorFlag) | Select-Object -Property $SelectProperties)
        }
        elseif ($ComputerName) {
            $Info = ([System.DirectoryServices.ActiveDirectory.DomainController]::FindAll($DirectoryContext) | Where-Object -Property Name -Match -Value $ComputerName | Select-Object -Property $SelectProperties)
        }
        else {
            $Info = ([System.DirectoryServices.ActiveDirectory.DomainController]::FindAll($DirectoryContext) | Select-Object -Property $SelectProperties)
        }
    }
    END {
        Write-Output -InputObject $Info
    }
}
