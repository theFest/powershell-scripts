Function Read-ServicePrincipalName {
    <#
    .SYNOPSIS
    Retrieves objects with Service Principal Names (SPNs) from Active Directory.

    .DESCRIPTION
    This function retrieves objects with Service Principal Names (SPNs) from Active Directory, including users and computers.

    .PARAMETER Credential
    Credentials to use when connecting to Active Directory. If not specified, the function uses the current user's credentials.
    .PARAMETER Filter
    Filter to use when retrieving objects, default filter retrieves objects with Service Principal Names (SPNs).
    .PARAMETER Properties
    Specifies the properties to retrieve for each object.

    .EXAMPLE
    Read-ServicePrincipalName -Verbose
    Read-ServicePrincipalName -Credential (Get-Credential)
    Read-ServicePrincipalName -Filter "(Name -like '*john*')"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [Alias("c")]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [Alias("f")]
        [string]$Filter = "(objectClass -eq 'user') -or (objectClass -eq 'computer') -and (servicePrincipalName -like '*')",

        [Parameter(Mandatory = $false)]
        [Alias("p")]
        [string[]]$Properties = @('Name', 'servicePrincipalName', 'DistinguishedName', 'ObjectClass', 'DNSHostName', 'whenCreated')
    )
    BEGIN {
        try {
            Write-Verbose -Message "Checking if Active Directory module is available..."
            if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
                Write-Verbose -Message "Importing Active Directory module..."
                Import-Module ActiveDirectory -ErrorAction Stop -Verbose
            }
        }
        catch {
            Write-Error -Message "Failed to import Active Directory module: $_"
            return
        }
        $AllObject = @()
    }
    PROCESS {
        try {
            $AllServicePrincipalNames = Get-ADObject -Filter $Filter -Properties $Properties 
            foreach ($SingleServicePrincipalName in $AllServicePrincipalNames) {
                Write-Verbose -Message "Get the values for the Service Principal Name"
                $ObjectClass = $SingleServicePrincipalName.ObjectClass
                $DistinguishedName = $SingleServicePrincipalName.DistinguishedName
                $Name = $SingleServicePrincipalName.Name
                $WhenCreated = $SingleServicePrincipalName.WhenCreated
                $DNSHostName = $SingleServicePrincipalName.DNSHostName
                Write-Verbose -Message "Loop over all SPN's, there could be more then one SPN value per record"
                foreach ($ServicePrincipalName in $SingleServicePrincipalName.ServicePrincipalName) {
                    $SingleObject = (New-Object -TypeName PSObject -Property @{
                            Name              = $Name
                            SPN               = $ServicePrincipalName
                            ObjectClass       = $ObjectClass
                            DistinguishedName = $DistinguishedName
                            WhenCreated       = $WhenCreated
                            DNSHostName       = $DNSHostName
                        })
                    $AllObject += $SingleObject
                    $SingleObject = $null
                }
            }
        }
        catch {
            Write-Error $_.Exception.Message
            return
        }
    }
    END {
        Write-Output -InputObject $AllObject
        $AllObject = $null
    }
}
