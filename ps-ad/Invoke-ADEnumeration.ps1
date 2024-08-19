function Invoke-ADEnumeration {
    <#
    .SYNOPSIS
    A script for enumerating Active Directory (AD) information by providing a menu-driven interface to perform various enumeration tasks. 

    .DESCRIPTION
    These tasks include retrieving information about the AD forest, domain controllers, groups, group members, Kerberoastable and ASReproastable accounts, as well as details on all computer and user accounts, etc.
    The script allows users to interactively select from a list of options to gather and display detailed AD information. Script provides guidance on security implications, such as protecting high-privilege accounts and enforcing pre-authentication.

    .EXAMPLE
    Invoke-ADEnumeration

    .NOTES
    v0.0.1
    #>
    $DisplayMenu = {
        $Options = @(
            "1. Forest Info",
            "2. Domain Controller Info",
            "3. Groups Info",
            "4. Group Members Info",
            "5. Kerberoastable Accounts",
            "6. ASReproastable Accounts",
            "7. All Computer Accounts Info",
            "8. All User Accounts Info",
            "9. Windows Servers Info",
            "10. AdminSDHolder Protected Users/Groups",
            "Ctrl+C to exit"
        )
        Write-Host "-------------------------------------------------------------------------------------------------------"
        foreach ($Option in $Options) {
            Write-Host $Option -ForegroundColor Yellow
        }
    }
    $HandleSelection = {
        param ($Choice)
        switch ($Choice) {
            '1' {
                $ForestName = Read-Host "Enter Forest name (or press Enter for default)"
                $ForestInfo = if ($ForestName) { Get-ADForest -Identity $ForestName } else { Get-ADForest }
                Write-Host $ForestInfo
            }
            '2' {
                Write-Host "Fetching Domain Controller Info..."
                Write-Host (Get-ADDomainController)
            }
            '3' {
                Write-Host "Fetching AD Group Info..."
                Get-ADGroup -Filter * | Out-File "adgroups.txt"
                Write-Host "Saved to 'adgroups.txt'"
            }
            '4' {
                $GroupName = Read-Host "Enter Group name"
                Write-Host (Get-ADGroupMember -Identity $GroupName)
            }
            '5' {
                $Detail = Read-Host "For details press 'd' or press Enter for names only"
                if ($Detail -eq 'd') {
                    Write-Host "Fetching SPN associated accounts..."
                    Write-Host (Get-ADUser -Filter { ServicePrincipalName -ne $null } -Properties *)
                }
                else {
                    Write-Host (Get-ADUser -Filter { ServicePrincipalName -ne $null } -Properties ServicePrincipalName | Select-Object SamAccountName, Name)
                }
                Write-Host "Kerberoasting targets accounts with SPNs. Secure these accounts by using strong passwords."
            }
            '6' {
                Write-Host "Fetching ASReprostable Accounts Info..."
                $Accounts = Get-ADUser -Filter * -Properties DoesNotRequirePreAuth | Where-Object { $_.DoesNotRequirePreAuth -eq $true }
                Write-Host $Accounts
                Write-Host "ASReproasting targets accounts without pre-authentication. Secure these accounts by enforcing pre-authentication."
            }
            '7' {
                $CompDetail = Read-Host "Press 'd' for details or enter specific computer name"
                if ($CompDetail -eq 'd') {
                    Get-ADComputer -Filter * -Properties * | Out-File "allCompAccounts.txt"
                    Write-Host "Details saved to 'allCompAccounts.txt'"
                }
                else {
                    Write-Host (Get-ADComputer -Filter { Name -eq $CompDetail } -Properties *)
                }
            }
            '8' {
                $UserDetail = Read-Host "Press 'd' for details or enter specific username"
                if ($UserDetail -eq 'd') {
                    Write-Host (Get-ADUser -Filter * -Properties *)
                }
                else {
                    $User = Read-Host "Enter Username"
                    Write-Host (Get-ADUser -Filter { SamAccountName -eq $User } -Properties *)
                }
            }
            '9' {
                $Version = Read-Host "Press 'A' for all servers or enter specific version (2008, 2012, 2016, etc.)"
                $Filter = if ($Version -eq 'A') { "Windows Server" } else { "Windows Server $Version" }
                Write-Host "Fetching servers..."
                $Servers = Get-ADComputer -Filter * -Properties * | Select-Object Name, IPv4Address, OperatingSystem | Where-Object { $_.OperatingSystem -like "*$Filter*" }
                Write-Host $Servers
            }
            '10' {
                $Detailed = Read-Host "Press 'd' for detailed info or press Enter for summary"
                if ($Detailed -eq 'd') {
                    Write-Host (Get-ADObject -Filter { AdminCount -eq 1 } -Properties *)
                }
                else {
                    Write-Host (Get-ADObject -Filter { AdminCount -eq 1 } -Properties * | Select-Object SamAccountName, ObjectClass, MemberOf)
                }
                Write-Host "AdminSDHolder protects high privilege accounts. Ensure secure ACLs."
            }
            default {
                Write-Host "Invalid selection. Please enter a valid option."
            }
        }
    }
    while ($true) {
        &$DisplayMenu
        $Choice = Read-Host "Select Option"
        &$HandleSelection -Choice $Choice
    }
}
