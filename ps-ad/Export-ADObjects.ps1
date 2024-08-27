function Export-ADObjects {
    <#
    .SYNOPSIS
    Exports Active Directory objects to a CSV file with optional detailed reporting.

    .DESCRIPTION
    This function retrieves Active Directory objects based on specified filters and exports the selected properties to a CSV file, supports exporting both basic and detailed attributes of the AD objects. Detailed report includes additional properties and calculated fields.

    .EXAMPLE
    Export-ADObjects -DetailedReport
    Export-ADObjects -ADObjectFilter 'Name -like "*John*"'

    .NOTES
    v0.4.8
    #>
    [CmdletBinding(ConfirmImpact = "None")]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, HelpMessage = "Filter criteria for the Active Directory objects to export, can use a filter expression or an array of filter expressions")]
        [string[]]$ADObjectFilter,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the CSV file where the AD objects will be exported, default is the Desktop of the current user")]
        [string]$ExportPath = "$env:USERPROFILE\Desktop\ADObjects.csv",

        [Parameter(Mandatory = $false, HelpMessage = "Include detailed information in the report. If not specified, only basic properties will be included")]
        [switch]$DetailedReport
    )
    BEGIN {
        $BaseProps = @(
            'DisplayName', 'UserPrincipalName', 'mail', 'CN', 'mailNickname', 'Name', 'GivenName', 'Surname', 'StreetAddress',
            'City', 'State', 'Country', 'PostalCode', 'Company', 'Title', 'Department', 'Description', 'OfficePhone',
            'MobilePhone', 'HomePhone', 'Fax', 'SamAccountName', 'DistinguishedName', 'Office', 'Enabled',
            'whenChanged', 'whenCreated', 'adminCount'
        )
        $DetailedProps = @(
            'AccountNotDelegated', 'AllowReversiblePasswordEncryption', 'CannotChangePassword', 'Deleted', 'DoesNotRequirePreAuth',
            'HomedirRequired', 'isDeleted', 'LockedOut', 'mAPIRecipient', 'mDBUseDefaults', 'MNSLogonAccount', 'msExchHideFromAddressLists',
            'msNPAllowDialin', 'PasswordExpired', 'PasswordNeverExpires', 'PasswordNotRequired', 'ProtectedFromAccidentalDeletion',
            'SmartcardLogonRequired', 'TrustedForDelegation', 'TrustedToAuthForDelegation', 'UseDESKeyOnly', 'logonHours',
            'msExchMailboxGuid', 'replicationSignature', 'AccountExpirationDate', 'AccountLockoutTime', 'Created', 'createTimeStamp',
            'LastBadPasswordAttempt', 'LastLogonDate', 'Modified', 'modifyTimeStamp', 'msTSExpireDate', 'PasswordLastSet',
            'msExchMailboxSecurityDescriptor', 'nTSecurityDescriptor', 'BadLogonCount', 'codePage', 'countryCode',
            'deletedItemFlags', 'dLMemDefault', 'garbageCollPeriod', 'instanceType', 'msDS-SupportedEncryptionTypes',
            'msDS-User-Account-Control-Computed', 'msExchALObjectVersion', 'msExchMobileMailboxFlags', 'msExchRecipientDisplayType',
            'msExchUserAccountControl', 'primaryGroupID', 'replicatedObjectVersion', 'sAMAccountType', 'sDRightsEffective',
            'userAccountControl', 'accountExpires', 'lastLogonTimestamp', 'lockoutTime', 'msExchRecipientTypeDetails', 'msExchVersion',
            'pwdLastSet', 'uSNChanged', 'uSNCreated', 'ObjectGUID', 'objectSid', 'SID', 'autoReplyMessage', 'CanonicalName',
            'displayNamePrintable', 'Division', 'EmployeeID', 'EmployeeNumber', 'HomeDirectory', 'HomeDrive', 'homeMDB', 'homeMTA',
            'HomePage', 'Initials', 'LastKnownParent', 'legacyExchangeDN', 'LogonWorkstations', 'Manager', 'msExchHomeServerName',
            'msExchUserCulture', 'msTSLicenseVersion', 'msTSManagingLS', 'ObjectCategory', 'ObjectClass', 'Organization', 'OtherName',
            'POBox', 'PrimaryGroup', 'ProfilePath', 'ScriptPath', 'sn', 'textEncodedORAddress', 'userParameters'
        )
        $Props = if ($DetailedReport) { $BaseProps + $DetailedProps } else { $BaseProps }
        $CalcProps = @(
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
    }
    PROCESS {
        $Filter = if ($ADObjectFilter) { $ADObjectFilter } else { '*' }
        $Results = $Filter | ForEach-Object {
            Get-ADObject -Filter $_ -Properties * -ResultSetSize $null |
            Select-Object -Property ($Props + $CalcProps)
        }
        if ($ExportPath) {
            $Results | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
        }
    }
}
