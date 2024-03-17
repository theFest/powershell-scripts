Function Get-LDAPInformation {
    <#
    .SYNOPSIS
    Retrieves information from Active Directory using LDAP queries.

    .DESCRIPTION
    This function allows querying Active Directory to retrieve various types of information, including users, groups, computers, organizational units, and more, using LDAP queries. It supports a wide range of filters and options to tailor the query results to specific needs.

    .PARAMETER Domain
    Specifies the domain from which to retrieve Active Directory information.
    .PARAMETER Credential
    Credentials to authenticate with the specified domain. If not provided, the function uses the current user's credentials.
    .PARAMETER Detailed
    Indicates whether to include detailed information in the query results.
    .PARAMETER LDAPS
    Specifies whether to use LDAP over SSL (LDAPS) for the connection.
    .PARAMETER DomainControllers
    Retrieves information about domain controllers in the specified domain.
    .PARAMETER AllServers
    Retrieves information about all servers in the specified domain.
    .PARAMETER AllMemberServers
    Retrieves information about all member servers in the specified domain.
    .PARAMETER DomainTrusts
    Retrieves information about domain trusts in the specified domain.
    .PARAMETER DomainAdmins
    Retrieves information about domain administrators.
    .PARAMETER UACTrusted
    Retrieves information about trusted users with User Account Control enabled.
    .PARAMETER NotUACTrusted
    Retrieves information about trusted users with User Account Control disabled.
    .PARAMETER SPNNamedObjects
    Retrieves information about objects with Service Principal Names (SPN).
    .PARAMETER EnabledUsers
    Retrieves information about enabled users in the specified domain.
    .PARAMETER PossibleExecutives
    Retrieves information about users who are potential executives but have no manager assigned.
    .PARAMETER LogonScript
    Retrieves information about users with logon scripts configured.
    .PARAMETER ListAllOU
    Lists all organizational units (OUs) in the specified domain.
    .PARAMETER ListComputers
    Lists all computer objects in the specified domain.
    .PARAMETER ListContacts
    Lists all contact objects in the specified domain.
    .PARAMETER ListGroups
    Lists all group objects in the specified domain.
    .PARAMETER ListUsers
    Lists all user objects in the specified domain.
    .PARAMETER ListContainers
    Lists all containers in the specified domain.
    .PARAMETER ListDomainObjects
    Lists all domain objects in the specified domain.
    .PARAMETER ListBuiltInContainers
    Lists all built-in containers in the specified domain.
    .PARAMETER ChangePasswordAtNextLogon
    Retrieves users who must change their password at next logon.
    .PARAMETER PasswordNeverExpires
    Retrieves users with passwords set to never expire.
    .PARAMETER NoPasswordRequired
    Retrieves users with no password required.
    .PARAMETER NoKerberosPreAuthRequired
    Retrieves users with no Kerberos pre-authentication required.
    .PARAMETER PasswordsThatHaveNotChangedInYears
    Retrieves users whose passwords haven't changed in years.
    .PARAMETER DistributionGroups
    Retrieves distribution groups in the specified domain.
    .PARAMETER SecurityGroups
    Retrieves security groups in the specified domain.
    .PARAMETER BuiltInGroups
    Retrieves built-in groups in the specified domain.
    .PARAMETER AllGlobalGroups
    Retrieves all global groups in the specified domain.
    .PARAMETER DomainLocalGroups
    Retrieves domain local groups in the specified domain.
    .PARAMETER UniversalGroups
    Retrieves universal groups in the specified domain.
    .PARAMETER GlobalSecurityGroups
    Retrieves global security groups in the specified domain.
    .PARAMETER UniversalSecurityGroups
    Retrieves universal security groups in the specified domain.
    .PARAMETER DomainLocalSecurityGroups
    Retrieves domain local security groups in the specified domain.
    .PARAMETER GlobalDistributionGroups
    Retrieves global distribution groups in the specified domain.

    .EXAMPLE
    Get-LDAPInformation -Detailed
    Get-LDAPInformation -Domain "example.com" -Credential (Get-Credential) -ListUsers

    .NOTES
    v0.3.4
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $false, ParameterSetName = "Domain", HelpMessage = "AD Domain")]
        [string]$Domain,
    
        [Parameter(Mandatory = $false, ParameterSetName = "Domain", HelpMessage = "Admin credentials")]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential = [System.Management.Automation.PSCredential]::Empty,
    
        [Parameter(Mandatory = $false, HelpMessage = "Specifies whether to retrieve detailed information")]
        [switch]$Detailed,
    
        [Parameter(Mandatory = $false, HelpMessage = "Use LDAPS (LDAP over SSL)")]
        [switch]$LDAPS,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve domain controllers")]
        [switch]$DomainControllers,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve all servers")]
        [switch]$AllServers,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve all member servers")]
        [switch]$AllMemberServers,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve domain trusts")]
        [switch]$DomainTrusts,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve domain administrators")]
        [switch]$DomainAdmins,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve trusted users with User Account Control enabled")]
        [switch]$UACTrusted,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve trusted users with User Account Control disabled")]
        [switch]$NotUACTrusted,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve SPN (Service Principal Name) named objects")]
        [switch]$SPNNamedObjects,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve enabled users")]
        [switch]$EnabledUsers,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve possible executives")]
        [switch]$PossibleExecutives,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve users with logon scripts")]
        [switch]$LogonScript,
    
        [Parameter(Mandatory = $false, HelpMessage = "List all organizational units")]
        [switch]$ListAllOU,
    
        [Parameter(Mandatory = $false, HelpMessage = "List all computers")]
        [switch]$ListComputers,
    
        [Parameter(Mandatory = $false, HelpMessage = "List all contacts")]
        [switch]$ListContacts,
    
        [Parameter(Mandatory = $false, HelpMessage = "List all groups")]
        [switch]$ListGroups,
    
        [Parameter(Mandatory = $false, HelpMessage = "List all users")]
        [switch]$ListUsers,
    
        [Parameter(Mandatory = $false, HelpMessage = "List all containers")]
        [switch]$ListContainers,
    
        [Parameter(Mandatory = $false, HelpMessage = "List all domain objects")]
        [switch]$ListDomainObjects,
    
        [Parameter(Mandatory = $false, HelpMessage = "List all built-in containers")]
        [switch]$ListBuiltInContainers,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve users who must change password at next logon")]
        [switch]$ChangePasswordAtNextLogon,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve users with passwords set to never expire")]
        [switch]$PasswordNeverExpires,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve users with no password required")]
        [switch]$NoPasswordRequired,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve users with no Kerberos pre-authentication required")]
        [switch]$NoKerberosPreAuthRequired,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve users whose passwords haven't changed in years")]
        [switch]$PasswordsThatHaveNotChangedInYears,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve distribution groups")]
        [switch]$DistributionGroups,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve security groups")]
        [switch]$SecurityGroups,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve built-in groups")]
        [switch]$BuiltInGroups,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve all global groups")]
        [switch]$AllGlobalGroups,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve domain local groups")]
        [switch]$DomainLocalGroups,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve universal groups")]
        [switch]$UniversalGroups,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve global security groups")]
        [switch]$GlobalSecurityGroups,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve universal security groups")]
        [switch]$UniversalSecurityGroups,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve domain local security groups")]
        [switch]$DomainLocalSecurityGroups,
    
        [Parameter(Mandatory = $false, HelpMessage = "Retrieve global distribution groups")]
        [switch]$GlobalDistributionGroups
    )
    BEGIN {
        $Output = @()
        $StartTime = Get-Date
        Write-Host "Generating LDAP query..." -ForegroundColor Cyan
        switch ($true) {
            { $DomainControllers } { $LdapFilter = "(primaryGroupID=516)" }
            { $AllServers } { $LdapFilter = '(&(objectCategory=computer)(operatingSystem=*server*))' }
            { $AllMemberServers } { $LdapFilter = '(&(objectCategory=computer)(operatingSystem=*server*)(!(userAccountControl:1.2.840.113556.1.4.803:=8192)))' }
            { $DomainTrusts } { $LdapFilter = '(objectClass=trustedDomain)' }
            { $DomainAdmins } { $LdapFilter = "(&(objectCategory=person)(objectClass=user)((memberOf=CN=Domain Admins,OU=Admin Accounts,DC=usav,DC=org)))" }
            { $UACTrusted } { $LdapFilter = "(userAccountControl:1.2.840.113556.1.4.803:=524288)" }
            { $NotUACTrusted } { $LdapFilter = '(userAccountControl:1.2.840.113556.1.4.803:=1048576)' }
            { $SPNNamedObjects } { $LdapFilter = '(servicePrincipalName=*)' }
            { $EnabledUsers } { $LdapFilter = '(&(objectCategory=person)(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))' }
            { $PossibleExecutives } { $LdapFilter = '(&(objectCategory=person)(objectClass=user)(directReports=*)(!(manager=*)))' }
            { $LogonScript } { $LdapFilter = '(&(objectCategory=person)(objectClass=user)(scriptPath=*))' }
            { $ListAllOU } { $LdapFilter = '(objectCategory=organizationalUnit)' }
            { $ListComputers } { $LdapFilter = '(objectCategory=computer)' }
            { $ListContacts } { $LdapFilter = '(objectClass=contact)' }
            { $ListUsers } { $LdapFilter = 'samAccountType=805306368' }
            { $ListGroups } { $LdapFilter = '(objectCategory=group)' }
            { $ListContainers } { $LdapFilter = '(objectCategory=container)' }
            { $ListDomainObjects } { $LdapFilter = '(objectCategory=domain)' }
            { $ListBuiltInContainers } { $LdapFilter = '(objectCategory=builtinDomain)' }
            { $ChangePasswordAtNextLogon } { $LdapFilter = '(&(objectCategory=person)(objectClass=user)(pwdLastSet=0))' }
            { $PasswordNeverExpires } { $LdapFilter = '(&(objectCategory=person)(objectClass=user) (userAccountControl:1.2.840.113556.1.4.803:=65536))' }
            { $NoPasswordRequired } { $LdapFilter = '(&(objectCategory=person)(objectClass=user) (userAccountControl:1.2.840.113556.1.4.803:=32))' }
            { $NoKerberosPreAuthRequired } { $LdapFilter = '(&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=4194304))' }
            { $PasswordsThatHaveNotChangedInYears } { $LdapFilter = '(&(objectCategory=person)(objectClass=user) (pwdLastSet>=129473172000000000))' }
            { $DistributionGroups } { $LdapFilter = '(&(objectCategory=group)(!(groupType:1.2.840.113556.1.4.803:=2147483648)))' }
            { $SecurityGroups } { $LdapFilter = '(groupType:1.2.840.113556.1.4.803:=2147483648)' }
            { $BuiltInGroups } { $LdapFilter = '(groupType:1.2.840.113556.1.4.803:=1)' }
            { $AllGlobalGroups } { $LdapFilter = '(groupType:1.2.840.113556.1.4.803:=2)' }
            { $DomainLocalGroups } { $LdapFilter = '(groupType:1.2.840.113556.1.4.803:=4)' }
            { $UniversalGroups } { $LdapFilter = '(groupType:1.2.840.113556.1.4.803:=8)' }
            { $GlobalSecurityGroups } { $LdapFilter = '(groupType=-2147483646)' }
            { $UniversalSecurityGroups } { $LdapFilter = '(groupType=-2147483640)' }
            { $DomainLocalSecurityGroups } { $LdapFilter = '(groupType=-2147483644)' }
            { $GlobalDistributionGroups } { $LdapFilter = '(groupType=2)' }
        }
        try {
            if ($Domain) {
                $DirectoryContext = [System.DirectoryServices.ActiveDirectory.DirectoryContext]::new("Domain", $Domain, $Credential.UserName, $Credential.GetNetworkCredential().Password)
                $DomainObj = [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DirectoryContext)
                $PrimaryDC = ($DomainObj.PdcRoleOwner).Name
                $ObjDomain = New-Object -TypeName System.DirectoryServices.DirectoryEntry "LDAP://$($PrimaryDC)", $Credential.UserName, $Credential.GetNetworkCredential().Password
            }
            else {
                $DomainObj = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
                $PrimaryDC = ($DomainObj.PdcRoleOwner).Name
                $ObjDomain = New-Object -TypeName System.DirectoryServices.DirectoryEntry
            }
            $DistinguishedName = "DC=$($DomainObj.Name.Replace('.',',DC='))"
            $SearchString = "LDAP://$PrimaryDC`:$Port/$DistinguishedName"
            $Port = "389"
            if ($LDAPS) {
                $Port = "636"
                Write-Verbose -Message "LDAP over SSL has been specified, utilizing port: $Port"
            }
            $Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher([ADSI]$SearchString)
            $Searcher.SearchRoot = $ObjDomain
            $Searcher.Filter = $LdapFilter
            $Searcher.SearchScope = "Subtree"
        }
        catch {
            Write-Error -Message "Failed to initialize LDAP search $_"
            return
        }
    } 
    PROCESS {
        $Results = $Searcher.FindAll()
        Write-Verbose -Message "Retrieving results, please wait..."
        if ($Detailed) {
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
        Write-Host "LDAP search is now complete" -ForegroundColor Cyan
        $EndTime = Get-Date
        $ElapsedTime = New-TimeSpan -Start $StartTime -End $EndTime
        Write-Verbose -Message "Time taken: $($ElapsedTime.TotalSeconds) seconds"
        return $Output
    }
}
