#requires -version 5.1
Function Add-UsersToGroup {
    <#
    .SYNOPSIS
    Adds users to an Active Directory group.
    
    .DESCRIPTION
	This function allows you to add users to an Active Directory group either by specifying a list of users directly or by providing a CSV file containing user names. It checks if each user exists in Active Directory before adding them to the group.
    
    .PARAMETER Users
    Mandatory - an array of user names to add to the group.
    .PARAMETER FromCSV
    NotMandatory - the path to a CSV file containing user names, will read user names from this file and add them to the group.
    .PARAMETER Filter
    NotMandatory - filter to use when searching for users in Active Directory. Possible values are "SamAccountName" (default), "DisplayName," "Email," and "UserPrincipalName."
    .PARAMETER GroupName
    Mandatory - the name of the Active Directory group to which users will be added.
    .PARAMETER Delimiter
    NotMandatory - delimiter used in the CSV file when reading user names.
    
    .EXAMPLE
    "your_AD_group" | Add-UsersToGroup -Users "first_user", "second_user" -Verbose
    Add-UsersToGroup -FromCSV "$env:USERPROFILE\Desktop\your_csv_with_users.csv" -GroupName 'your_AD_group' -Verbose
    
    .NOTES
    v0.0.4
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
        [string[]]$Users,
 
        [Parameter(Mandatory = $false)]
        $FromCSV,

        [Parameter(ValueFromPipeline = $false, Mandatory = $false)]
        [ValidateSet("SamAccountName", "DisplayName", "Email", "UserPrincipalName")]
        [string]$Filter = "SamAccountName",

        [Parameter(ValueFromPipeline = $true, Mandatory = $false)]
        [string]$GroupName,

        [Parameter(Mandatory = $false)]
        [string]$Delimiter = ","
    )
    BEGIN {
        if (!(Get-Module -Name ActiveDirectory -ListAvailable -Verbose)) {
            Write-Output "Active Directory is missing, installing..."
            Import-Module -Name ActiveDirectory -Force -Verbose
        }
        Write-Verbose -Message "Selected group details: $(Get-ADGroup -Filter { Name -like $GroupName })"     
    }
    PROCESS {
        if ($FromCSV) {
            Write-Verbose -Message "Importing users from csv file..."
            $Users = (Import-Csv -Path $FromCSV -Delimiter $Delimiter -Header "Name").Name
        }
        $Users | ForEach-Object {
            try {
                $User = (Get-ADuser -Filter "$Filter -eq '$_'").ObjectGUID
                if ($User) {
                    Write-Host "AD user: $_ found in the Active Directory, continuing..." -ForegroundColor Green
                }
            }
            catch {
                Write-Error -Exception $_.Exception.Message
            }
        }
        foreach ($U in $Users) {
            try {
                Add-ADGroupMember -Identity $GroupName -Members $U -ErrorAction SilentlyContinue -Verbose
            }
            catch {
                Write-Host "AD user: $U does not exists in Active Directory, check username!" -ForegroundColor Red
            }
        }
    }
    END {
        Write-Verbose -Message "Finished, cleaning up and exiting. Time: $(Get-Date -Format "dddd | MM/dd/yyyy | HH:mm")"
        Clear-Variable -Name Users, GroupName -Force -Verbose -ErrorAction SilentlyContinue
        Clear-History -Verbose
        exit
    }
}