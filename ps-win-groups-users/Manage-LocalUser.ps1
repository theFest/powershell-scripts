Function Manage-LocalUser {
    <#
    .SYNOPSIS
    Manage-LocalUser is a PowerShell function for performing various user management tasks on the local Windows machine. It supports actions such as resetting passwords, adding users, removing users, importing/exporting user data to/from CSV, checking user lockout status, and more.

    .DESCRIPTION
    Manage-LocalUser is a versatile utility that simplifies common tasks related to local user management. It provides a range of actions for modifying and querying local user accounts on a Windows system.

    .PARAMETER Action
    Mandatory - Choose from a list of predefined actions such as "ResetPassword," "AddUser," "RemoveUser," "AddUsers," "RemoveUsers," "GetUsers," "GetMembers," "ExportCSV," "ImportCSV," "CheckLock," and more.
    .PARAMETER Username
    Mandatory - the username or usernames on which the action should be performed. This can be a single username or an array of usernames.
    .PARAMETER GroupName
    NotMandatory - (For "AddUser" and "RemoveUser" actions) Specifies the name of the group to which the user should be added or removed.
    .PARAMETER Password
    NotMandatory - specifies the password to set for the user(s). Only used in actions that require password modification.
    .PARAMETER UserMayNotChangePassword
    NotMandatory - indicates that the user(s) should not be allowed to change their password. Only used in actions that require password modification.
    .PARAMETER PasswordNeverExpires
    NotMandatory - indicates that the user(s) should have passwords set to never expire. Only used in actions that require password modification.
    .PARAMETER AccountNeverExpires
    NotMandatory - indicates that the user(s) should have accounts set to never expire. Only used in actions that require account modification.
    .PARAMETER Description
    NotMandatory - description to associate with the user(s). Only used in actions that require user creation or modification.
    .PARAMETER Disabled
    NotMandatory - (For "AddUser" and "AddUsers" actions) Indicates that the user(s) should be created as disabled accounts.
    .PARAMETER File
    NotMandatory - (For "ImportCSV" and "ExportCSV" actions) Specifies the path to the CSV file to import user data from or export data to.
    .PARAMETER LogFile
    NotMandatory - specifies the path for the log file where operation results and error messages will be recorded.

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "ResetPassword", "AddUser", "RemoveUser", "AddUsers", "RemoveUsers",
            "GetUsers", "GetMembers", "ExportCSV", "ImportCSV", "CheckLock",
            "ProgressReporting", "Logging", "Comments", "Automation",
            "InventoryFile", "ErrorHandling", "Authentication", "InputValidation",
            "Rollback"
        )]
        [string]$Action,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$Username,

        [Parameter(Mandatory = $false)]
        [string[]]$GroupName,

        [Parameter(Mandatory = $false)]
        [string]$Password,

        [Parameter(Mandatory = $false)]
        [switch]$UserMayNotChangePassword,

        [Parameter(Mandatory = $false)]
        [switch]$PasswordNeverExpires,

        [Parameter(Mandatory = $false)]
        [switch]$AccountNeverExpires,

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [switch]$Disabled,

        [Parameter(Mandatory = $false)]
        [string]$File,

        [Parameter(Mandatory = $false)]
        [string]$LogFile = "$env:USERPROFILE\Desktop\UserManagement.csv"
    )
    BEGIN {
        $Log = [System.Collections.ArrayList]::new()
        $Result = [System.Collections.ArrayList]::new()
    }
    PROCESS {
        switch ($Action) {
            "ImportCSV" {
                try {
                    $Data = Import-Csv -Path $File
                    $Result.AddRange($Data)
                }
                catch {
                    Write-Warning -Message "Failed to import data. Error: $_"
                }
            }
            "ResetPassword" {
                $Username | ForEach-Object {
                    $params = @{
                        Name                  = $_
                        Password              = $Password | ConvertTo-SecureString -AsPlainText -Force
                        UserMayChangePassword = !$UserMayNotChangePassword.IsPresent
                        PasswordNeverExpires  = $PasswordNeverExpires.IsPresent
                        AccountNeverExpires   = $AccountNeverExpires.IsPresent
                        Description           = $Description
                        ErrorAction           = "SilentlyContinue"
                        Verbose               = $true
                    }
                    try {
                        Set-LocalUser @params
                    }
                    catch {
                        Write-Warning -Message "Failed to reset password for user $_. Error: $_"
                        $Log.Add("Failed to reset password for user $_. Error: $_")
                    }
                }
            }
            "AddUser" {
                $Username | ForEach-Object {
                    if (Get-LocalUser -Name $_) {
                        Write-Warning -Message "$_ already exists, skipping..."
                        $Result.Add("Exists")
                        return
                    }
                    $params = @{
                        Name                     = $_
                        Password                 = $Password | ConvertTo-SecureString -AsPlainText -Force
                        UserMayNotChangePassword = $UserMayNotChangePassword.IsPresent
                        PasswordNeverExpires     = $PasswordNeverExpires.IsPresent
                        AccountNeverExpires      = $AccountNeverExpires.IsPresent
                        Description              = $Description
                        Disabled                 = $Disabled.IsPresent
                        ErrorAction              = "SilentlyContinue"
                        Verbose                  = $true
                    }
                    try {
                        New-LocalUser @params
                        if ((Get-LocalGroupMember -Group $GroupName | Select-Object Name | Where-Object { $_.Name -eq $_ }).Count -eq 0) {
                            Write-Verbose "Adding user to group $GroupName..."
                            Add-LocalGroupMember -Group $GroupName -Member $_ -ErrorAction SilentlyContinue -Verbose
                            $Result.Add("Success")
                        }
                        else {
                            Write-Warning -Message "User $_ already a member of group $GroupName, skipping..."
                            $Result.Add("AlreadyMember")
                        }
                    }
                    catch {
                        Write-Warning -Message "Failed to add user $_. Error: $_"
                        $Result.Add("Failure")
                    }
                }
            }
            "RemoveUser" {
                $Username | ForEach-Object {
                    if (!(Get-LocalUser -Name $_)) {
                        Write-Warning -Message "$_ does not exist, skipping..."
                        $Result.Add("NotExists")
                        return
                    }
                    $params = @{
                        Name        = $_
                        ErrorAction = "SilentlyContinue"
                        Verbose     = $true
                    }
                    try {
                        Remove-LocalUser @params
                        if ((Get-LocalGroupMember -Group $GroupName | Select-Object Name | Where-Object { $_.Name -eq $_ }).Count -ne 0) {
                            Write-Verbose "Removing user from group $GroupName..."
                            Remove-LocalGroupMember -Group $GroupName -Member $_ -ErrorAction SilentlyContinue -Verbose
                        }
                        $Result.Add("Success")
                    }
                    catch {
                        Write-Warning -Message "Failed to remove user $_. Error: $_"
                        $Result.Add("Failure")
                    }
                }
            }
            "AddUsers" {
                $Users = Get-Content -Path $File
                foreach ($User in $Users) {
                    $params = @{
                        Name                     = $User
                        Password                 = $Password | ConvertTo-SecureString -AsPlainText -Force
                        UserMayNotChangePassword = $UserMayNotChangePassword.IsPresent
                        PasswordNeverExpires     = $PasswordNeverExpires.IsPresent
                        AccountNeverExpires      = $AccountNeverExpires.IsPresent
                        Description              = $Description
                        Disabled                 = $Disabled.IsPresent
                        ErrorAction              = "SilentlyContinue"
                        Verbose                  = $true
                    }
                    try {
                        New-LocalUser @params
                        if ((Get-LocalGroupMember -Group $GroupName | Select-Object Name | Where-Object { $_.Name -eq $User }).Count -eq 0) {
                            Write-Verbose "Adding user $User to group $GroupName..."
                            Add-LocalGroupMember -Group $GroupName -Member $User -ErrorAction SilentlyContinue -Verbose
                            $Result.Add("Success")
                        }
                        else {
                            Write-Warning -Message "User $User already a member of group $GroupName, skipping..."
                            $Result.Add("AlreadyMember")
                        }
                    }
                    catch {
                        Write-Warning -Message "Failed to add user $User. Error: $_"
                        $Result.Add("Failure")
                    }
                }
            }
            "RemoveUsers" {
                $Users = Get-Content -Path $File
                foreach ($User in $Users) {
                    $params = @{
                        Name        = $User
                        ErrorAction = "SilentlyContinue"
                        Verbose     = $true
                    }
                    try {
                        Remove-LocalUser @params
                        if ((Get-LocalGroupMember -Group $GroupName | Select-Object Name | Where-Object { $_.Name -eq $User }).Count -ne 0) {
                            Write-Verbose "Removing user $User from group $GroupName..."
                            Remove-LocalGroupMember -Group $GroupName -Member $User -ErrorAction SilentlyContinue -Verbose
                        }
                        $Result.Add("Success")
                    }
                    catch {
                        Write-Warning -Message "Failed to remove user $User. Error: $_"
                        $Result.Add("Failure")
                    }
                }
            }
            "GetUsers" {
                $Users = Get-LocalUser
                $Result.AddRange($Users)
            }
            "GetMembers" {
                $Members = Get-LocalGroupMember -Group $GroupName
                $Result.AddRange($Members)
            }
            "ExportCSV" {
                if ($Result.Count -eq 0) {
                    Write-Warning -Message "No data to export"
                    return
                }
                try {
                    $Result | Export-Csv -Path $File -NoTypeInformation -Append
                    Write-Verbose -Message "Data exported to $File"
                }
                catch {
                    Write-Warning -Message "Failed to export data. Error: $_"
                }
            }
            "CheckLock" {
                $Username | ForEach-Object {
                    $params = @{
                        Name        = $_
                        ErrorAction = "SilentlyContinue"
                        Verbose     = $true
                    }
                    $User = Get-LocalUser @params
                    if ($User) {
                        if ($User.LockoutEnabled) {
                            $Result.Add("$User.Name is locked out")
                        }
                        else {
                            $Result.Add("$User.Name is not locked out")
                        }
                    }
                    else {
                        $Result.Add("$User.Name not found")
                    }
                }
            }
        }
    }
}
