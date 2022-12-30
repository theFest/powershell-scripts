#requires -version 3.0
Function AddUsers {
    <#
    .SYNOPSIS
    Function for adding user/users to Active Directory groups.
    
    .DESCRIPTION
    With this function you can add user/users to AD group either via pipeline or by importing csv file.
    
    .PARAMETER Users
    Mandatory - users that you want to add.
    .PARAMETER FromCSV
    NotMandatory - add users from .csv file.   
    .PARAMETER Filter
    NotMandatory - choose filter, SAM account name is predifined.  
    .PARAMETER GroupName
    Mandatory - Active Directory group in which users will be added.  
    .PARAMETER Delimiter
    NotMandatory - delimiter present in csv file.
    
    .EXAMPLE
    "your_AD_group" | AddUsers -Users "first_user", "second_user" -Verbose
    AddUsers -FromCSV "$env:USERPROFILE\Desktop\your_csv_with_users.csv" -GroupName 'your_AD_group' -Verbose
    
    .NOTES
    Features in new version: RSAT, exec. policy, all groups, etc.
    v1
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true, Mandatory = $false, HelpMessage = "Identity or identites")]
        $Users,
 
        [Parameter(Mandatory = $false, HelpMessage = "Identity or identites from file")]
        $FromCSV,

        [Parameter(ValueFromPipeline = $false, Mandatory = $false, HelpMessage = "UserPrincipalName, SamAccountName")]
        [ValidateSet("SamAccountName", "DisplayName", "Email", "UserPrincipalName")]
        [string]$Filter = "SamAccountName",

        [Parameter(ValueFromPipeline = $true, Mandatory = $false, HelpMessage = "Choose your group")]
        [string]$GroupName,

        [Parameter(Mandatory = $false, HelpMessage = "If your delimiter is not comma, choose the one used in csv file")]
        [string]$Delimiter = ","
    )
    BEGIN {
        if (!(Get-Module -Name ActiveDirectory -ListAvailable -Verbose)) {
            Write-Output "Active Directory is missing, installing..."
            Import-Module -Name ActiveDirectory -Force -Verbose
        }
        Write-Verbose "Selected group details: $(Get-ADGroup -Filter { Name -like $GroupName })"     
    }
    PROCESS {
        if ($FromCSV) {
            $Users = (Import-Csv -Path $FromCSV -Delimiter $Delimiter -Header "Name").Name
        }
        $Users | ForEach-Object {
            try {
                $User = Get-ADuser -Filter "$Filter -eq '$_'" | Select-Object ObjectGUID
                if ($User) {
                    Write-Host "AD user: $_ found in the Active Directory, continuing..." -ForegroundColor Green
                }
            }
            catch {
                Write-Error $_.Exception.Message
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
        Write-Host "Finished, cleaning up and exiting..." -ForegroundColor Cyan
        Clear-Variable -Name Users, GroupName -Force -Verbose -ErrorAction SilentlyContinue
        Clear-History -Verbose
    }
}