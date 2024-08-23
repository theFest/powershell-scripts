#requires -Version 5.1
function Add-UsersToGroup {
    <#
    .SYNOPSIS
    Adds specified users to an Active Directory group.

    .DESCRIPTION
    This function adds users to a specified Active Directory group. Users can be provided directly via the `-Users` parameter or read from a CSV file specified by the `-FromCSV` parameter.
    The CSV file must be formatted with a single line of usernames separated by the specified delimiter, also validates the presence of the Active Directory module and handles errors for missing users or invalid group names.

    .EXAMPLE
    Add-UsersToGroup -Users "user1", "user2" -GroupName "DnsAdmins"
    Add-UsersToGroup -FromCSV "$env:USERPROFILE\Desktop\users_list.csv" -GroupName "DnsAdmins"

    .NOTES
    v0.4.8
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "Medium")]
    param (
        [Parameter(Mandatory = $false, Position = 0, ValueFromPipeline = $true, ValueFromRemainingArguments = $true, HelpMessage = "Usernames to add to the group")]
        [ValidateNotNullOrEmpty()]
        [Alias("u")]
        [string[]]$Users,

        [Parameter(Mandatory = $false, Position = 4, HelpMessage = "Path to a CSV file containing usernames to add to the group")]
        [ValidateScript({ 
                if (Test-Path -Path $_ -PathType Leaf) { $true } else { throw "The file '$_' does not exist." }
            })]
        [Alias("c")]
        [string]$FromCSV,

        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Attribute to filter users when searching in Active Directory")]
        [ValidateSet("SamAccountName", "DisplayName", "Email", "UserPrincipalName")]
        [Alias("f")]
        [string]$Filter = "SamAccountName",

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Name of the group to which users will be added")]
        [ValidatePattern('^[^\\/:*?"<>|]+$')]
        [ValidateNotNullOrEmpty()]
        [Alias("g")]
        [string]$GroupName,

        [Parameter(Mandatory = $false, Position = 3, HelpMessage = "Delimiter used in the CSV file")]
        [ValidateSet(",", ";", "`t", "|", " ")]
        [Alias("d")]
        [string]$Delimiter = ","
    )
    BEGIN {
        $ErrorUsers = @()
        if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
            Write-Verbose -Message "Active Directory module is not available, installing..."
            try {
                Install-Module -Name ActiveDirectory -ErrorAction Stop
                Import-Module -Name ActiveDirectory -ErrorAction Stop
            }
            catch {
                throw "Failed to install or import the Active Directory module. $_"
            }
        }
        else {
            Import-Module -Name ActiveDirectory
        }
        try {
            $Group = Get-ADGroup -Filter { Name -eq $GroupName } -ErrorAction Stop
            Write-Verbose -Message "Selected group: $($Group.Name) | DistinguishedName: $($Group.DistinguishedName)"
        }
        catch {
            throw "The group '$GroupName' does not exist in Active Directory. $_"
        }
    }
    PROCESS {
        if ($FromCSV) {
            Write-Verbose "Importing users from CSV file: $FromCSV..."
            try {
                $RawContent = Get-Content -Path $FromCSV -Raw
                $ImportedUsers = $RawContent -split [regex]::Escape($Delimiter) | ForEach-Object { $_.Trim() }
                if (-not $ImportedUsers) {
                    throw "No users were found in the CSV file '$FromCSV'. Ensure the file has correct formatting."
                }
                $Users = $ImportedUsers
            }
            catch {
                throw "Failed to import users from CSV file '$FromCSV'. $_"
            }
        }
        if (-not $Users) {
            throw "No users specified for addition to the group '$GroupName'."
        }
        foreach ($UserName in $Users) {
            try {
                $ADUser = Get-ADUser -Filter "$Filter -eq '$UserName'" -ErrorAction Stop
                Write-Verbose "Found user: $($ADUser.SamAccountName) ($UserName), adding to group..."
                Add-ADGroupMember -Identity $GroupName -Members $ADUser -ErrorAction Stop -Verbose
                Write-Host "Successfully added user '$UserName' to the group '$GroupName'." -ForegroundColor Green
            }
            catch {
                Write-Warning -Message "Failed to add user '$UserName' to the group '$GroupName'. $_"
                $ErrorUsers += $UserName
            }
        }
    }
    END {
        $TotalUsers = if ($Users) { $Users.Count } else { 0 }
        $SuccessfulAdds = $TotalUsers - $ErrorUsers.Count
        $FailedAdds = $ErrorUsers.Count
        Write-Verbose -Message "Processing complete."
        Write-Host "------------------------------ Summary ------------------------------" -ForegroundColor Cyan
        Write-Host "Total users processed: $TotalUsers"
        Write-Host "Successfully added to '$GroupName': $SuccessfulAdds" -ForegroundColor Green
        Write-Host "Failed to add to '$GroupName': $FailedAdds" -ForegroundColor Red
        if ($FailedAdds -gt 0) {
            Write-Host "`nFailed Users:" -ForegroundColor Yellow
            foreach ($FailedUser in $ErrorUsers) {
                Write-Host "- $FailedUser" -ForegroundColor Yellow
            }
        }
        Write-Verbose -Message "`nOperation completed on: $(Get-Date -Format 'dddd, MM/dd/yyyy | HH:mm')"
        Remove-Variable -Name Users, FromCSV, GroupName -ErrorAction SilentlyContinue
    }
}
