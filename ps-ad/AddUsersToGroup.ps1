#requires -version 5.1
Function AddUsersToGroup {
    <#
    .SYNOPSIS
    Function for adding user/users to Active Directory groups.
    
    .DESCRIPTION
    With this function you can add user/users to AD group either via pipeline or by importing csv file.
    
    .PARAMETER Users
    Mandatory - users(identity or identites) that you want to add.
    .PARAMETER FromCSV
    NotMandatory - add users(identites from file) from .csv file.   
    .PARAMETER Filter
    NotMandatory - choose filter, SAM account name is predifined.  
    .PARAMETER GroupName
    Mandatory - Active Directory group in which users will be added.  
    .PARAMETER Delimiter
    NotMandatory - delimiter present in csv file, if your delimiter is not comma, choose the one used in csv file.
    
    .EXAMPLE
    "your_AD_group" | AddUsersToGroup -Users "first_user", "second_user" -Verbose
    AddUsersToGroup -FromCSV "$env:USERPROFILE\Desktop\your_csv_with_users.csv" -GroupName 'your_AD_group' -Verbose
    
    .NOTES
    v1.0.1
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
        Write-Verbose -Message "Finished, cleaning up and exiting. Time: $(Get-Date -Format "dddd | MM/dd/yyyy | HH:mm")"
        Clear-Variable -Name Users, GroupName -Force -Verbose -ErrorAction SilentlyContinue
        Clear-History -Verbose
        exit
    }
}