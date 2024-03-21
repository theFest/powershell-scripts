Function Export-ADObjects {
    <#
    .SYNOPSIS
    Retrieves Active Directory objects and exports them to a CSV file.

    .DESCRIPTION
    This function retrieves Active Directory objects based on specified filters and exports them to a CSV file. It provides an option to include detailed information about the objects.

    .PARAMETER ADObjectFilter
    Array of filters to apply when retrieving Active Directory objects.
    .PARAMETER ExportPath
    Path where the CSV file containing the Active Directory objects will be exported. Defaults to the user's desktop if not specified.
    .PARAMETER DetailedReport
    Indicates whether to include detailed information about the Active Directory objects.

    .EXAMPLE
    Export-ADObjects -DetailedReport

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(ConfirmImpact = "None")]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string[]]$ADObjectFilter,

        [Parameter(Mandatory = $false)]
        [string]$ExportPath = "$env:USERPROFILE\Desktop\ADObjects.csv",

        [Parameter(Mandatory = $false)]
        [switch]$DetailedReport
    )
    BEGIN {
        if ($DetailedReport) {
            $Selectproperties = @(
                'DisplayName', 'UserPrincipalName', 'mail', 'CN', 'mailNickname', 'Name', 'GivenName', 'Surname', 'StreetAddress'
                'City', 'State', 'Country', 'PostalCode', 'Company', 'Title', 'Department', 'Description', 'OfficePhone'
                'MobilePhone', 'HomePhone', 'Fax', 'SamAccountName', 'DistinguishedName', 'Office', 'Enabled'
                'whenChanged', 'whenCreated', 'adminCount', 'AccountNotDelegated', 'AllowReversiblePasswordEncryption'
                'CannotChangePassword', 'Deleted', 'DoesNotRequirePreAuth', 'HomedirRequired', 'isDeleted', 'LockedOut'
                'mAPIRecipient', 'mDBUseDefaults', 'MNSLogonAccount', 'msExchHideFromAddressLists'
                'msNPAllowDialin', 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'ProtectedFromAccidentalDeletion'
                'SmartcardLogonRequired', 'TrustedForDelegation', 'TrustedToAuthForDelegation', 'UseDESKeyOnly', 'logonHours'
                'msExchMailboxGuid', 'replicationSignature', 'AccountExpirationDate', 'AccountLockoutTime', 'Created', 'createTimeStamp'
                'LastBadPasswordAttempt', 'LastLogonDate', 'Modified', 'modifyTimeStamp', 'msTSExpireDate', 'PasswordLastSet'
                'msExchMailboxSecurityDescriptor', 'nTSecurityDescriptor', 'BadLogonCount', 'codePage', 'countryCode'
                'deletedItemFlags', 'dLMemDefault', 'garbageCollPeriod', 'instanceType', 'msDS-SupportedEncryptionTypes'
                'msDS-User-Account-Control-Computed', 'msExchALObjectVersion', 'msExchMobileMailboxFlags', 'msExchRecipientDisplayType'
                'msExchUserAccountControl', 'primaryGroupID', 'replicatedObjectVersion', 'sAMAccountType', 'sDRightsEffective'
                'userAccountControl', 'accountExpires', 'lastLogonTimestamp', 'lockoutTime', 'msExchRecipientTypeDetails', 'msExchVersion'
                'pwdLastSet', 'uSNChanged', 'uSNCreated', 'ObjectGUID', 'objectSid', 'SID', 'autoReplyMessage', 'CanonicalName'
                'displayNamePrintable', 'Division', 'EmployeeID', 'EmployeeNumber', 'HomeDirectory', 'HomeDrive', 'homeMDB', 'homeMTA'
                'HomePage', 'Initials', 'LastKnownParent', 'legacyExchangeDN', 'LogonWorkstations'
                'Manager', 'msExchHomeServerName', 'msExchUserCulture', 'msTSLicenseVersion', 'msTSManagingLS'
                'ObjectCategory', 'ObjectClass', 'Organization', 'OtherName', 'POBox', 'PrimaryGroup'
                'ProfilePath', 'ScriptPath', 'sn', 'textEncodedORAddress', 'userParameters'
            )
            $CalculatedProps = @(
                @{
                    n = 'OU'
                    e = {
                        $PSItem.DistinguishedName -replace '^.+?,(?=(OU|CN)=)'
                    }
                },
                @{
                    n = 'proxyAddresses'
                    e = {
                  ($PSItem.proxyAddresses | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join '|'
                    }
                },
                @{
                    n = 'altRecipientBL'
                    e = {
                  ($PSItem.altRecipientBL | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'AuthenticationPolicy'
                    e = {
                  ($PSItem.AuthenticationPolicy | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'AuthenticationPolicySilo'
                    e = {
                  ($PSItem.AuthenticationPolicySilo | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'Certificates'
                    e = {
                  ($PSItem.Certificates | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'CompoundIdentitySupported'
                    e = {
                  ($PSItem.CompoundIdentitySupported | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'dSCorePropagationData'
                    e = {
                  ($PSItem.dSCorePropagationData | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'KerberosEncryptionType'
                    e = {
                  ($PSItem.KerberosEncryptionType | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'managedObjects'
                    e = {
                  ($PSItem.managedObjects | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'MemberOf'
                    e = {
                  ($PSItem.MemberOf | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'msExchADCGlobalNames'
                    e = {
                  ($PSItem.msExchADCGlobalNames | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'msExchPoliciesExcluded'
                    e = {
                  ($PSItem.msExchPoliciesExcluded | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'PrincipalsAllowedToDelegateToAccount'
                    e = {
                  ($PSItem.PrincipalsAllowedToDelegateToAccount | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'protocolSettings'
                    e = {
                  ($PSItem.protocolSettings | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'publicDelegatesBL'
                    e = {
                  ($PSItem.publicDelegatesBL | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'securityProtocol'
                    e = {
                  ($PSItem.securityProtocol | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'ServicePrincipalNames'
                    e = {
                  ($PSItem.ServicePrincipalNames | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'showInAddressBook'
                    e = {
                  ($PSItem.showInAddressBook | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'SIDHistory'
                    e = {
                  ($PSItem.SIDHistory | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'userCertificate'
                    e = {
                  ($PSItem.userCertificate | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                }
            )
            $ExtensionAttribute = @(
                'extensionAttribute1', 'extensionAttribute2', 'extensionAttribute3', 'extensionAttribute4', 'extensionAttribute5'
                'extensionAttribute6', 'extensionAttribute7', 'extensionAttribute8', 'extensionAttribute9', 'extensionAttribute10'
                'extensionAttribute11', 'extensionAttribute12', 'extensionAttribute13', 'extensionAttribute14', 'extensionAttribute15'
            )
        }
        else {
            $Props = @(
                'DisplayName', 'UserPrincipalName', 'mail', 'CN', 'mailNickname', 'Name', 'GivenName', 'Surname', 'StreetAddress',
                'City', 'State', 'Country', 'PostalCode', 'Company', 'Title', 'Department', 'Description', 'OfficePhone'
                'MobilePhone', 'HomePhone', 'Fax', 'SamAccountName', 'DistinguishedName', 'Office', 'Enabled'
                'whenChanged', 'whenCreated', 'adminCount', 'Memberof', 'msExchPoliciesExcluded', 'proxyAddresses'
            )
            $Selectproperties = @(
                'DisplayName', 'UserPrincipalName', 'mail', 'CN', 'mailNickname', 'Name', 'GivenName', 'Surname', 'StreetAddress',
                'City', 'State', 'Country', 'PostalCode', 'Company', 'Title', 'Department', 'Description', 'OfficePhone'
                'MobilePhone', 'HomePhone', 'Fax', 'SamAccountName', 'DistinguishedName', 'Office', 'Enabled'
                'whenChanged', 'whenCreated', 'adminCount'
            )
            $CalculatedProps = @(
                @{
                    n = 'proxyAddresses'
                    e = {
                  ($PSItem.proxyAddresses | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join '|'
                    }
                },
                @{
                    n = 'OU'
                    e = {
                        $PSItem.DistinguishedName -replace '^.+?,(?=(OU|CN)=)'
                    }
                },
                @{
                    n = 'MemberOf'
                    e = {
                  ($PSItem.MemberOf | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                },
                @{
                    n = 'msExchPoliciesExcluded'
                    e = {
                  ($PSItem.msExchPoliciesExcluded | Where-Object -FilterScript {
                            $_ -ne $null
                        }) -join ';'
                    }
                }
            )
        }
    }
    PROCESS {
        if ($ADObjectFilter) {
            foreach ($CurADObjectFilter in $ADObjectFilter) {
                if (!($DetailedReport)) {
                    Get-ADObject -Filter $CurADObjectFilter -Properties $Props -ResultSetSize $null | Select-Object -Property ($Selectproperties + $CalculatedProps)
                }
                else {
                    Get-ADObject -Filter $CurADObjectFilter -Properties * -ResultSetSize $null | Select-Object -Property ($Selectproperties + $CalculatedProps + $ExtensionAttribute)
                }
            }
        }
        else {
            if (!($DetailedReport)) {
                Get-ADObject -Filter * -Properties $Props -ResultSetSize $null | Select-Object -Property ($Selectproperties + $CalculatedProps)
            }
            else {
                Get-ADObject -Filter * -Properties * -ResultSetSize $null | Select-Object -Property ($Selectproperties + $CalculatedProps + $ExtensionAttribute)
            }
        }
        if ($ExportPath) {
            $result | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
        }
    }
}
