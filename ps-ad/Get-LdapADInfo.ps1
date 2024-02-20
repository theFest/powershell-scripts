Function Get-LdapADInfo {
    <#
    .SYNOPSIS
    Retrieves information from Active Directory using LDAP queries.

    .DESCRIPTION
    This function allows you to query Active Directory for various information using LDAP filters, supports a wide range of parameters to customize your queries.

    .PARAMETER Domain
    Specifies the domain to query, if not provided, the function will use the current domain.
    .PARAMETER Credential
    Credentials to use for the LDAP query, if not provided, it uses the current user's credentials.
    .PARAMETER Detailed
    When present, returns detailed information including all properties.
    .PARAMETER LDAPS
    Specifies LDAP over SSL. If present, the function uses port 636.
    .PARAMETER DomainControllers
    Retrieves information about domain controllers.
    .PARAMETER AllServers
    Retrieves information about all servers.
    .PARAMETER AllMemberServers
    Retrieves information about all member servers.
    .PARAMETER DomainTrusts
    Retrieves information about domain trusts.
    .PARAMETER DomainAdmins
    Retrieves information about domain administrators.
    .PARAMETER UACTrusted
    Retrieves information about accounts with trusted for delegation enabled.
    .PARAMETER NotUACTrusted
    Retrieves information about accounts without trusted for delegation.
    .PARAMETER SPNNamedObjects
    Retrieves information about objects with servicePrincipalName set.
    .PARAMETER EnabledUsers
    Retrieves information about enabled user accounts.
    .PARAMETER PossibleExecutives
    Retrieves information about user accounts with direct reports but no manager.
    .PARAMETER LogonScript
    Retrieves information about user accounts with logon scripts.
    .PARAMETER ListAllOU
    Retrieves information about all Organizational Units (OUs) in the domain.
    .PARAMETER ListComputers
    Retrieves information about all computer objects in the domain.
    .PARAMETER ListContacts
    Retrieves information about all contact objects in the domain.
    .PARAMETER ListGroups
    Retrieves information about all group objects in the domain.
    .PARAMETER ListUsers
    Retrieves information about all user accounts in the domain.
    .PARAMETER ListContainers
    Retrieves information about all container objects in the domain.
    .PARAMETER ListDomainObjects
    Retrieves information about all domain objects in the domain.
    .PARAMETER ListBuiltInContainers
    Retrieves information about all built-in containers in the domain.
    .PARAMETER ChangePasswordAtNextLogon
    Retrieves information about user accounts with the requirement to change password at next logon.
    .PARAMETER PasswordNeverExpires
    Retrieves information about user accounts with passwords set to never expire.
    .PARAMETER NoPasswordRequired
    Retrieves information about user accounts with no password requirement.
    .PARAMETER NoKerberosPreAuthRequired
    Retrieves information about user accounts with no Kerberos pre-authentication requirement.
    .PARAMETER PasswordsThatHaveNotChangedInYears
    Retrieves information about user accounts with passwords unchanged for a specified period.
    .PARAMETER DistributionGroups
    Retrieves information about distribution groups in the domain.
    .PARAMETER SecurityGroups
    Retrieves information about security groups in the domain.
    .PARAMETER BuiltInGroups
    Retrieves information about built-in groups in the domain.
    .PARAMETER AllGLobalGroups
    Retrieves information about all global groups in the domain.
    .PARAMETER DomainLocalGroups
    Retrieves information about domain local groups in the domain.
    .PARAMETER UniversalGroups
    Retrieves information about universal groups in the domain.
    .PARAMETER GlobalSecurityGroups
    Retrieves information about global security groups in the domain.
    .PARAMETER UniversalSecurityGroups
    Retrieves information about universal security groups in the domain.
    .PARAMETER DomainLocalSecurityGroups
    Retrieves information about domain local security groups in the domain.
    .PARAMETER GlobalDistributionGroups
    Retrieves information about global distribution groups in the domain.

    .EXAMPLE
    Get-LdapADInfo -ListUsers -Detailed

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $false, ParameterSetName = "Domain")]
        [string]$Domain,
                
        [Parameter(Mandatory = $false, ParameterSetName = "Domain")]
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,
                
        [Parameter(Mandatory = $false)]
        [switch][bool]$Detailed,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$LDAPS,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$DomainControllers,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$AllServers,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$AllMemberServers,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$DomainTrusts,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$DomainAdmins,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$UACTrusted,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$NotUACTrusted,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$SPNNamedObjects,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$EnabledUsers,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$PossibleExecutives,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$LogonScript,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$ListAllOU,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$ListComputers,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$ListContacts,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$ListGroups,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$ListUsers,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$ListContainers,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$ListDomainObjects,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$ListBuiltInContainers,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$ChangePasswordAtNextLogon,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$PasswordNeverExpires,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$NoPasswordRequired,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$NoKerberosPreAuthRequired,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$PasswordsThatHaveNotChangedInYears,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$DistributionGroups,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$SecurityGroups,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$BuiltInGroups,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$AllGLobalGroups,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$DomainLocalGroups,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$UniversalGroups,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$GlobalSecurityGroups,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$UniversalSecurityGroups,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$DomainLocalSecurityGroups,
    
        [Parameter(Mandatory = $false)]
        [switch][bool]$GlobalDistributionGroups
    
    )
    BEGIN {
        $Output = @()
        Write-Verbose -Message "Creating LDAP query..."
        if ($DomainControllers.IsPresent) { $LdapFilter = "(primaryGroupID=516)" }
        elseif ($AllServers.IsPresent) { $LdapFilter = '(&(objectCategory=computer)(operatingSystem=*server*))' }
        elseif ($AllMemberServers.IsPresent) { $LdapFilter = '(&(objectCategory=computer)(operatingSystem=*server*)(!(userAccountControl:1.2.840.113556.1.4.803:=8192)))' }
        elseif ($DomainTrusts.IsPresent) { $LdapFilter = '(objectClass=trustedDomain)' }
        elseif ($DomainAdmins.IsPresent) { $LdapFilter = "(&(objectCategory=person)(objectClass=user)((memberOf=CN=Domain Admins,OU=Admin Accounts,DC=usav,DC=org)))" }
        elseif ($UACTrusted.IsPresent) { $LdapFilter = "(userAccountControl:1.2.840.113556.1.4.803:=524288)" }
        elseif ($NotUACTrusted.IsPresent) { $LdapFilter = '(userAccountControl:1.2.840.113556.1.4.803:=1048576)' }
        elseif ($SPNNamedObjects.IsPresent) { $LdapFilter = '(servicePrincipalName=*)' }
        elseif ($EnabledUsers.IsPresent) { $LdapFilter = '(&(objectCategory=person)(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))' }
        elseif ($PossibleExecutives.IsPresent) { $LdapFilter = '(&(objectCategory=person)(objectClass=user)(directReports=*)(!(manager=*)))' }
        elseif ($LogonScript.IsPresent) { $LdapFilter = '(&(objectCategory=person)(objectClass=user)(scriptPath=*))' }
        elseif ($ListAllOU.IsPresent) { $LdapFilter = '(objectCategory=organizationalUnit)' }
        elseif ($ListComputers.IsPresent) { $LdapFilter = '(objectCategory=computer)' }
        elseif ($ListContacts.IsPresent) { $LdapFilter = '(objectClass=contact)' }
        elseif ($ListUsers.IsPresent) { $LdapFilter = 'samAccountType=805306368' }
        elseif ($ListGroups.IsPresent) { $LdapFilter = '(objectCategory=group)' }
        elseif ($ListContainers.IsPresent) { $LdapFilter = '(objectCategory=container)' }
        elseif ($ListDomainObjects.IsPresent) { $LdapFilter = '(objectCategory=domain)' }
        elseif ($ListBuiltInContainers.IsPresent) { $LdapFilter = '(objectCategory=builtinDomain)' }
        elseif ($ChangePasswordAtNextLogon.IsPresent) { $LdapFilter = '(&(objectCategory=person)(objectClass=user)(pwdLastSet=0))' }
        elseif ($PasswordNeverExpires.IsPresent) { $LdapFilter = '(&(objectCategory=person)(objectClass=user) (userAccountControl:1.2.840.113556.1.4.803:=65536))' }
        elseif ($NoPasswordRequired.IsPresent) { $LdapFilter = '(&(objectCategory=person)(objectClass=user) (userAccountControl:1.2.840.113556.1.4.803:=32))' }
        elseif ($NoKerberosPreAuthRequired.IsPresent) { '(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))' }
        elseif ($PasswordsThatHaveNotChangedInYears.IsPresent) { $LdapFilter = '(&(objectCategory=person)(objectClass=user) (pwdLastSet>=129473172000000000))' }
        elseif ($DistributionGroups.IsPresent) { $LdapFilter = '(&(objectCategory=group)(!(groupType:1.2.840.113556.1.4.803:=2147483648)))' }
        elseif ($SecurityGroups.IsPresent) { $LdapFilter = '(groupType:1.2.840.113556.1.4.803:=2147483648)' }
        elseif ($BuiltInGroups.IsPresent) { $LdapFilter = '(groupType:1.2.840.113556.1.4.803:=1)' }
        elseif ($AllGlobalGroups.IsPresent) { $LdapFilter = '(groupType:1.2.840.113556.1.4.803:=2)' }
        elseif ($DomainLocalGroups.IsPresent) { $LdapFilter = '(groupType:1.2.840.113556.1.4.803:=4)' }
        elseif ($UniversalGroups.IsPresent) { $LdapFilter = '(groupType:1.2.840.113556.1.4.803:=8)' }
        elseif ($GlobalSecurityGroups.IsPresent) { $LdapFilter = '(groupType=-2147483646)' }
        elseif ($UniversalSecurityGroups.IsPresent) { $LdapFilter = '(groupType=-2147483640)' }
        elseif ($DomainLocalSecurityGroups.IsPresent) { $LdapFilter = '(groupType=-2147483644)' }
        elseif ($GlobalDistributionGroups.IsPresent) { $LdapFilter = '(groupType=2)' }
        $Port = "389"
        if ($LDAPS.IsPresent) {
            $Port = "636"
            Write-Verbose -Message "[*] LDAP over SSL was specified. Using port $Port"
        }
        if ($Domain) {
            $DirectoryContext = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new("Domain", $Domain, $Credential.UserName, $Credential.GetNetworkCredential().Password)
            $DomainObj = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DirectoryContext)
            $PrimaryDC = ($DomainObj.PdcRoleOwner).Name
            $ObjDomain = New-Object -TypeName System.DirectoryServices.DirectoryEntry "LDAP://$($PrimaryDC)" , $Credential.UserName, $($Credential.GetNetworkCredential().Password)
        }
        else {
            $DomainObj = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
            $PrimaryDC = ($DomainObj.PdcRoleOwner).Name
            $ObjDomain = New-Object -TypeName System.DirectoryServices.DirectoryEntry
        }
        $DistinguishedName = "DC=$($DomainObj.Name.Replace('.',',DC='))"
        $SearchString = "LDAP://$PrimaryDC`:$Port/$DistinguishedName"
        $Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher([ADSI]$SearchString)
        $Searcher.SearchRoot = $ObjDomain
        $Searcher.Filter = $LdapFilter
        $Searcher.SearchScope = "Subtree"
    } 
    PROCESS {
        $Results = $Searcher.FindAll()
        Write-Verbose -Message "[*] Getting results"
        if ($Detailed.IsPresent) {
            if ($Results.Properties) {
                foreach ($Result in $Results) {
                    $ObjProperties = @()
                    foreach ($Property in $Result.Properties) {
                        $ObjProperties += $Property
                    }
                    $Output += $ObjProperties
                }
            }
            else {
                foreach ($Result in $Results) {
                    $Output += $Result.GetDirectoryEntry()
                }
            }
        }
        else {
            foreach ($Result in $Results) {
                $Output += $Result.GetDirectoryEntry()
            }
        }
    } 
    END {
        Write-Verbose -Message "[*] LDAP Query complete"
        return $Output
    }
}
