Function Set-ADMembership {
    <#
    .SYNOPSIS
    Manage Active Directory users and groups.

    .DESCRIPTION
    This function you can add or remove multiple users to/from multiple groups, includes information.

    .PARAMETER Action
    NotMandatory - choose operation type.
    .PARAMETER Users
    NotMandatory - multiple AD users that will be added to defined groups.
    .PARAMETER Groups
    NotMandatory - add multiple AD groups in which users will be added.
    .PARAMETER UserAD
    NotMandatory - username used for authentication to Active Directory.
    .PARAMETER PassAD
    NotMandatory - password used for authentication to Active Directory.
    .PARAMETER SearchBase
    NotMandatory - base DN (Distinguished Name) of the Active Directory structure that the script will search for users or groups.
    .PARAMETER UserFilter
    NotMandatory - specifies a filter that the script will use to search for specific users in Active Directory.
    .PARAMETER AuthType
    NotMandatory - authentication type that script will use to connect to Active Directory
    .PARAMETER ResultOutput
    NotMandatory - output csv format of the results returned by the script.
    .PARAMETER Verify
    NotMandatory - specifies whether the script will prompt for confirmation before performing the action.
    .PARAMETER WhatIf
    NotMandatory - perform a dry run and display what actions would be performed, without actually making any changes.

    .EXAMPLE
    Set-ADMembership -Action Add -Users 'some_AD_user1', 'some_AD_user2' -Groups 'AD_group1', 'AD_group1' -UserAD "your_AD_user" -PassAD "your_AD_password" -Verbose -Verify
    Set-ADMembership -Action Remove -Users 'some_AD_user1', 'some_AD_user2' -Groups 'AD_group1', 'AD_group2' -UserAD "your_AD_user" -PassAD "your_AD_password" -Verbose -Verify -WhatIf
    Set-ADMembership -Action Information -UserAD "your_AD_user" -PassAD "your_AD_password" -ResultOutput "$env:TEMP\ResultOutput.csv" -Verbose -Verify

    .NOTES
    v1.0.1
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipelineByPropertyName = $true, HelpMessage = "the action to perform")]
        [ValidateSet("Add", "Remove", "Information")]
        [string]$Action,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Users to modify")]
        [string[]]$Users,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Groups to modify")]
        [string[]]$Groups,

        [Parameter(Mandatory = $false, HelpMessage = "an Active Directory user to authenticate with")]
        [string]$UserAD,

        [Parameter(Mandatory = $false, HelpMessage = "password for the Active Directory user to authenticate with")]
        [string]$PassAD,

        [Parameter(Mandatory = $false, HelpMessage = "the search base for the Active Directory query")]
        [ValidateNotNullOrEmpty()]
        [string]$SearchBase,

        [Parameter(ValueFromPipeline = $false, Mandatory = $false, HelpMessage = "type of user filter to use")]
        [ValidateSet("DisplayName", "SamAccountName", "Email", "UserPrincipalName")]
        [string]$UserFilter = "SamAccountName",

        [Parameter(Mandatory = $false, HelpMessage = "choose authentication type to use")]
        [ValidateSet("Basic", "Negotiate")]
        [string]$AuthType = "Negotiate",

        [Parameter(Mandatory = $false, HelpMessage = "the output file to save results to")]
        [string]$ResultOutput,

        [Parameter(Mandatory = $false, HelpMessage = "verify that the command is valid, but do not perform the action")]
        [switch]$Verify,

        [Parameter(Mandatory = $false, HelpMessage = "shows what would happen if the cmdlet runs")]
        [switch]$WhatIf
    )
    BEGIN {
        $ST = Get-Date ; Write-Verbose -Message "Current time:" ; $ST.ToLongTimeString()
        Start-Transcript -Path "$env:TEMP\ManageADMembership.txt" -Append -IncludeInvocationHeader -Verbose
        $Rsat = Get-WindowsCapability -Name RSAT* -Online | Select-Object Name, State
        if ($null -eq $Rsat -or (!(Test-Path -Path "$env:windir\System32\dsa.msc"))) {
            Write-Warning -Message "Installing and importing AD modules..."
            Install-Module -Name AzureAD -Force -Verbose ; Import-Module -Name ActiveDirectory -Force -Verbose
            Write-Warning -Message "Remote Server Administration Tools are missing, downloading and installing..."
            $RsatURL = "https://www.microsoft.com/en-us/download/confirmation.aspx?id=45520&6B49FDFB-8E5B-4B07-BC31-15695C5A2143=1"
            Invoke-WebRequest -Uri $RsatURL -UseBasicParsing -OutFile "$env:TEMP\WindowsTH-KB2693643-x64.msu" -Verbose
            $RsatInstallerArgs = @{
                FilePath     = 'msiexec.exe'
                ArgumentList = @(
                    "/i $env:TEMP\WindowsTH-KB2693643-x64.msu",
                    "/qr /norestart",
                    "/l* $env:TEMP\WindowsTH-KB2693643-x64.log"
                )
                Wait         = $true
            }
            Start-Process @RsatInstallerArgs -WindowStyle Normal
        }
        else {
            Write-Host "Remote Server Administration Tools are installed." -ForegroundColor Green
            if ($Rsat.Name -contains "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0") {
                Write-Verbose -Message "Active Directory Users and Computers tools are included in RSAT."
            }
            else {
                Write-Warning -Message "Active Directory Users and Computers tools are not included in RSAT!"
            }
        }
    }
    PROCESS {
        try {
            $SecPass = ConvertTo-SecureString -AsPlainText $PassAD -Force -Verbose
            $SecuredCredentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserAD, $SecPass
        }
        catch {
            Write-Error $_
            return
        }
        $UserBlock = { foreach ($User in $Users) {
                $UserCheck = (Get-ADuser -Filter "$UserFilter -eq '$User'" -AuthType $AuthType -Credential $SecuredCredentials).ObjectGUID
                if ($UserCheck) {
                    Write-Verbose -Message "User  --> '$User' exists and is enabled..."
                }
                else {
                    Write-Host "VERBOSE: User  --> '$User' does not exist, check username!" -ForegroundColor Red
                }
            }
            return $User.SamAccountName
        }
        $GroupBlock = { foreach ($Group in $Groups) {
                $GroupCheck = Get-ADGroup -Identity $Group -Credential $SecuredCredentials -AuthType $AuthType -ShowMemberTimeToLive
                if ($GroupCheck) {
                    Write-Verbose -Message "Group --> '$Group' exists..."
                }
                else {
                    Write-Verbose -Message "Group --> '$Group' does not exist..."
                }
            }
            return $Group.SamAccountName
        }
        $ExecCheck = { Invoke-Command $UserBlock -args { $Users, $SecuredCredentials, $AuthType } ; `
                Invoke-Command $GroupBlock -args { $Groups, $SecuredCredentials, $AuthType } }
        switch ($Action) {
            "Add" {
                $Users | ForEach-Object {
                    try {
                        Write-Verbose -Message "User  --> '$_'running..."
                        foreach ($G in $Groups) {
                            Add-ADGroupMember -Identity $G -Members $_ `
                                -Credential $SecuredCredentials -AuthType $AuthType -Verbose -WhatIf:$WhatIf
                        }
                    }
                    catch [System.UnauthorizedAccessException] {
                        Write-Warning -Message "Insufficient permissions!"
                    }
                    finally {
                        if ($Verify) {
                            Write-Verbose -Message "Verifying added users; $_..."
                            Get-ADUser -Identity $_ -Properties * -Credential $SecuredCredentials -AuthType $AuthType -Verbose
                            foreach ($G in $Groups) {
                                $AddedUser = Get-ADGroupMember -Identity $G -Recursive -Credential $SecuredCredentials -AuthType Negotiate -ErrorAction SilentlyContinue
                                if ($AddedUser) {
                                    Write-Host "User $_ was added successfully to group $G" -ForegroundColor Green
                                }
                                else {
                                    Write-Host "Failed to add user $_ to group $G" -ForegroundColor Red
                                }
                            }
                        }
                    }
                }
            }
            "Remove" {
                $Groups | ForEach-Object {
                    try {
                        Write-Verbose -Message "Group --> '$_'running..."
                        foreach ($U in $Users) {
                            Remove-ADGroupMember -Identity $_ -Members $Users `
                                -Credential $SecuredCredentials -AuthType $AuthType -Verbose -WhatIf:$WhatIf -Confirm:$false
                            if ($Verify) {
                                $RemUser = Get-ADGroupMember -Identity $_ -Recursive -Credential $SecuredCredentials -AuthType Negotiate -ErrorAction SilentlyContinue
                                if ($RemUser) {
                                    Write-Host "User $U was removed successfully from group $_" -ForegroundColor Green
                                }
                                else {
                                    Write-Host "Failed to remove user $U from group $_" -ForegroundColor Red
                                }
                            }
                        }
                    }
                    catch [System.UnauthorizedAccessException] {
                        Write-Warning -Message "Insufficient permissions!"
                    }
                }
            }
            "Information" {
                Write-Verbose -Message "Gathering required information, please wait..."
                $Table = @() ; $Record = @{
                    "Group Name" = ""
                    "Name"       = ""
                    "Username"   = ""
                }
                try {
                    $SearchGroups = (Get-AdGroup -Filter "GroupCategory -eq 'Security'" -SearchBase $SearchBase `
                        | Where-Object { $_.Name -like "**" } `
                        | Select-Object Name -ExpandProperty Name)
                    foreach ($Group in $SearchGroups) {
                        $GroupMembers = Get-ADGroupMember -Identity $Group -Recursive `
                        | Select-Object Name, SamAccountName
                        foreach ($Member in $GroupMembers) {
                            $Record."Group Name" = $Group
                            $Record."Name" = $Member.Name
                            $Record."UserName" = $Member.SamAccountName
                            $ObjOutput = New-Object PSObject -Property $Record
                            $Table += $ObjOutput
                        }
                    }
                    if ($ResultOutput) {
                        $Table | Export-Csv -Path $ResultOutput -Force -NoTypeInformation -Verbose
                    }
                }
                catch [System.DirectoryServices.ActiveDirectory.ActiveDirectoryServerDownException] {
                    Write-Warning -Message "Unable to connect to Active Directory server."
                }
                catch [System.DirectoryServices.ActiveDirectory.IdentityNotFoundException] {
                    Write-Warning -Message "Group or User not found."
                }
                catch [System.UnauthorizedAccessException] {
                    Write-Warning -Message "Insufficient permissions to modify group membership."
                }
                catch {
                    Write-Error $_.Exception.Message
                }
                Write-Output -InputObject $Table
                Write-Verbose -Message "Process ended, checking and finishing up..."
            }
        }
        Invoke-Command -ScriptBlock $ExecCheck
    }
    END {
        Write-Verbose "Time taken to finish; [$((Get-Date).Subtract($ST).Duration() -replace ".{8}$")]"
        Clear-Variable -Name Users, Groups, UserAD, PassAD, SecuredCredentials, SearchBase `
            -Verbose -Force -WarningAction SilentlyContinue
        Write-Verbose -Message "Finished, cleaning and exiting..."
        Clear-History -Verbose
        Stop-Transcript
    }
}
