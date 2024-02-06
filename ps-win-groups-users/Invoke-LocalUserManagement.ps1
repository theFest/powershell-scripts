Function Invoke-LocalUserManagement {
    <#
    .SYNOPSIS
    Performs various management operations on local users.

    .DESCRIPTION
    This function allows performing actions such as resetting passwords, adding or removing users, getting user information, exporting data to CSV, and more, for local users on a system.

    .PARAMETER Action
    Action to perform, available include "ResetPassword", "AddUser", "RemoveUser", "AddUsers", "RemoveUsers", "GetUsers", "GetMembers", "ExportCSV", "ImportCSV", "CheckLock", "ProgressReporting", "Logging", "Comments", "Automation", "InventoryFile", "ErrorHandling", "Authentication", "InputValidation", and "Rollback".
    .PARAMETER User
    Specifies the user or users on which the action will be performed.
    .PARAMETER GroupName
    Specifies the group or groups to which the user belongs.
    .PARAMETER Pass
    Specifies the password to set for the user.
    .PARAMETER UserMayNotChangePassword
    Indicates whether the user is allowed to change their password.
    .PARAMETER PasswordNeverExpires
    Indicates whether the user's password should never expire.
    .PARAMETER AccountNeverExpires
    Indicates whether the user's account should never expire.
    .PARAMETER Description
    Specifies the description for the user account.
    .PARAMETER Disabled
    Indicates whether the user account is disabled.
    .PARAMETER File
    Path to a file used for importing or exporting data.
    .PARAMETER LogFile
    Specifies the path to the log file.

    .EXAMPLE
    Invoke-LocalUserManagement -Action ResetPassword -User JohnDoe -Pass "NewPassword123"

    .NOTES
    v0.0.4
    #>
    [CmdletBinding()]
    param (
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
        [string[]]$User,

        [Parameter(Mandatory = $false)]
        [string[]]$GroupName,

        [Parameter(Mandatory = $false)]
        [string]$Pass,

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
                $User | ForEach-Object {
                    $Params = @{
                        Name                  = $_
                        Password              = $Pass | ConvertTo-SecureString -AsPlainText -Force
                        UserMayChangePassword = !$UserMayNotChangePassword.IsPresent
                        PasswordNeverExpires  = $PasswordNeverExpires.IsPresent
                        AccountNeverExpires   = $AccountNeverExpires.IsPresent
                        Description           = $Description
                        ErrorAction           = "SilentlyContinue"
                        Verbose               = $true
                    }
                    try {
                        Set-LocalUser @Params
                    }
                    catch {
                        Write-Warning -Message "Failed to reset password for user $_. Error: $_"
                        $Log.Add("Failed to reset password for user $_. Error: $_")
                    }
                }
            }
            "AddUser" {
                $User | ForEach-Object {
                    if (Get-LocalUser -Name $_) {
                        Write-Warning -Message "$_ already exists, skipping..."
                        $Result.Add("Exists")
                        return
                    }
                    $Params = @{
                        Name                     = $_
                        Password                 = $Pass | ConvertTo-SecureString -AsPlainText -Force
                        UserMayNotChangePassword = $UserMayNotChangePassword.IsPresent
                        PasswordNeverExpires     = $PasswordNeverExpires.IsPresent
                        AccountNeverExpires      = $AccountNeverExpires.IsPresent
                        Description              = $Description
                        Disabled                 = $Disabled.IsPresent
                        ErrorAction              = "SilentlyContinue"
                        Verbose                  = $true
                    }
                    try {
                        New-LocalUser @Params
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
                $User | ForEach-Object {
                    if (!(Get-LocalUser -Name $_)) {
                        Write-Warning -Message "$_ does not exist, skipping..."
                        $Result.Add("NotExists")
                        return
                    }
                    $Params = @{
                        Name        = $_
                        ErrorAction = "SilentlyContinue"
                        Verbose     = $true
                    }
                    try {
                        Remove-LocalUser @Params
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
                    $Params = @{
                        Name                     = $User
                        Password                 = $Pass | ConvertTo-SecureString -AsPlainText -Force
                        UserMayNotChangePassword = $UserMayNotChangePassword.IsPresent
                        PasswordNeverExpires     = $PasswordNeverExpires.IsPresent
                        AccountNeverExpires      = $AccountNeverExpires.IsPresent
                        Description              = $Description
                        Disabled                 = $Disabled.IsPresent
                        ErrorAction              = "SilentlyContinue"
                        Verbose                  = $true
                    }
                    try {
                        New-LocalUser @Params
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
                    $Params = @{
                        Name        = $User
                        ErrorAction = "SilentlyContinue"
                        Verbose     = $true
                    }
                    try {
                        Remove-LocalUser @Params
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
                $User | ForEach-Object {
                    $Params = @{
                        Name        = $_
                        ErrorAction = "SilentlyContinue"
                        Verbose     = $true
                    }
                    $User = Get-LocalUser @Params
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
