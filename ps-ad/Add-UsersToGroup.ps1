#Requires -Version 5.1
Function Add-UsersToGroup {
    <#
    .SYNOPSIS
    Adds users to a specified Active Directory group.

    .DESCRIPTION
    This function adds users to a specified Active Directory group. Users can be provided directly as an array of usernames or through a CSV file containing usernames. Users are added based on a specified attribute (e.g., SamAccountName, DisplayName) and the name of the target group.

    .PARAMETER Users
    The usernames to add to the group, can be provided as an array of strings.
    .PARAMETER FromCSV
    Path to a CSV file containing usernames to add to the group, each row in the CSV file should contain a single username.
    .PARAMETER Filter
    Attribute to filter users when searching in Active Directory, supported attributes include SamAccountName, DisplayName, Email, and UserPrincipalName. Default is SamAccountName.
    .PARAMETER GroupName
    The name of the group to which users will be added.
    .PARAMETER Delimiter
    Delimiter used in the CSV file, default delimiter is a comma (,).

    .EXAMPLE
    Add-UsersToGroup -Users "your_user1", "your_user2" -GroupName "your_group" -Verbose

    .NOTES
    v0.2.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromRemainingArguments = $true, HelpMessage = "Usernames to add to the group")]
        [Alias("u")]
        [string[]]$Users,

        [Parameter(Mandatory = $false, Position = 4, HelpMessage = "Path to a CSV file containing usernames to add to the group")]
        [ValidateScript({ 
                Test-Path -Path $_ -PathType Leaf
            })]
        [Alias("c")]
        [string]$FromCSV,

        [Parameter(Mandatory = $false, Position = 2, ValueFromPipeline = $false, HelpMessage = "Attribute to filter users when searching in Active Directory")]
        [ValidateSet("SamAccountName", "DisplayName", "Email", "UserPrincipalName")]
        [Alias("f")]
        [string]$Filter = "SamAccountName",

        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, HelpMessage = "Name of the group to which users will be added")]
        [Alias("g")]
        [string]$GroupName,

        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Delimiter used in the CSV file")]
        [Alias("d")]
        [string]$Delimiter = ","
    )
    BEGIN {
        if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
            Write-Output "Active Directory module is missing, attempting to install..."
            Install-Module -Name ActiveDirectory -Force -Verbose
            Import-Module -Name ActiveDirectory -Force -Verbose
        }
        Write-Verbose -Message "Selected group details: $(Get-ADGroup -Filter { Name -eq $GroupName })"
    }
    PROCESS {
        if ($FromCSV) {
            Write-Verbose -Message "Importing users from CSV file: $FromCSV..."
            $Users = (Import-Csv -Path $FromCSV -Delimiter $Delimiter -Header "Name").Name
        }
        foreach ($UserName in $Users) {
            try {
                $ADUser = Get-ADUser -Filter "$Filter -eq '$UserName'"
                if ($ADUser) {
                    Write-Host "AD user: $UserName found in Active Directory, continuing..." -ForegroundColor Green
                    Add-ADGroupMember -Identity $GroupName -Members $ADUser -ErrorAction SilentlyContinue -Verbose
                }
                else {
                    Write-Warning -Message "AD user: $UserName does not exist in Active Directory, please check the username!"
                }
            }
            catch {
                Write-Error -Message "Error occurred while processing user: $UserName ~ $_"
            }
        }
    }
    END {
        Write-Verbose -Message "Finished, cleaning up and exiting. Time: $(Get-Date -Format "dddd | MM/dd/yyyy | HH:mm")"
        Clear-Variable -Name Users, GroupName -Force -Verbose -ErrorAction SilentlyContinue
        Clear-History
    }
}
