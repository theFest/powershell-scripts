Function LocalUserManagement {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet(
            "ResetPassword", "AddUser", "RemoveUser", "AddUsers", "RemoveUsers",
            "GetUsers", "GetMembers", "ExportCSV", "ImportCSV", "CheckLock",
            "ProgressReporting", "Logging", "Comments", "Automation",
            "InventoryFile", "ErrorHandling", "Authentication", "InputValidation",
            "Rollback"
        )]
        [string]$Action,

        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$Username,

        [Parameter()]
        [string[]]$GroupName,

        [Parameter()]
        [string]$Password,

        [Parameter()]
        [switch]$UserMayNotChangePassword,

        [Parameter()]
        [switch]$PasswordNeverExpires,

        [Parameter()]
        [switch]$AccountNeverExpires,

        [Parameter()]
        [string]$Description,

        [Parameter()]
        [switch]$Disabled,

        [Parameter()]
        [string]$File,

        [Parameter()]
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
                    $data = Import-Csv -Path $File
                    $Result.AddRange($data)
                }
                catch {
                    Write-Warning -Message "Failed to import data. Error: $_"
                }
            }
            "ResetPassword" {
                $username | ForEach-Object {
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
                $username | ForEach-Object {
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
                        if ((Get-LocalGroupMember -Group $Group | Select-Object Name | Where-Object { $_.Name -eq $_ }).Count -eq 0) {
                            Write-Verbose "Adding user to group $Group..."
                            Add-LocalGroupMember -Group $Group -Member $_ -ErrorAction SilentlyContinue -Verbose
                            $Result.Add("Success")
                        }
                        else {
                            Write-Warning -Message "User $_ already a member of group $Group, skipping..."
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
                $username | ForEach-Object {
                    if (!(Get-LocalUser -Name $)) {
                        Write-Warning -Message "$ does not exist, skipping..."
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
                        if ((Get-LocalGroupMember -Group $Group | Select-Object Name | Where-Object { $.Name -eq $ }).Count -ne 0) {
                            Write-Verbose "Removing user from group $Group..."
                            Remove-LocalGroupMember -Group $Group -Member $_ -ErrorAction SilentlyContinue -Verbose
                        }
                        $Result.Add("Success")
                    }
                    catch {
                        Write-Warning -Message "Failed to remove user $. Error: $"
                        $Result.Add("Failure")
                    }
                }
            }
            "AddUsers" {
                $users = Get-Content -Path $File
                foreach ($user in $users) {
                    $params = @{
                        Name                     = $user
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
                        if ((Get-LocalGroupMember -Group $Group | Select-Object Name | Where-Object { $.Name -eq $user }).Count -eq 0) {
                            Write-Verbose "Adding user $user to group $Group..."
                            Add-LocalGroupMember -Group $Group -Member $user -ErrorAction SilentlyContinue -Verbose
                            $Result.Add("Success")
                        }
                        else {
                            Write-Warning -Message "User $user already a member of group $Group, skipping..."
                            $Result.Add("AlreadyMember")
                        }
                    }
                    catch {
                        Write-Warning -Message "Failed to add user $user. Error: $"
                        $Result.Add("Failure")
                    }
                }
            }
            "RemoveUsers" {
                $users = Get-Content -Path $File
                foreach ($user in $users) {
                    $params = @{
                        Name        = $user
                        ErrorAction = "SilentlyContinue"
                        Verbose     = $true
                    }
                    try {
                        Remove-LocalUser @params
                        if ((Get-LocalGroupMember -Group $Group | Select-Object Name | Where-Object { $_.Name -eq $user }).Count -ne 0) {
                            Write-Verbose "Removing user $user from group $Group..."
                            Remove-LocalGroupMember -Group $Group -Member $user -ErrorAction SilentlyContinue -Verbose
                        }
                        $Result.Add("Success")
                    }
                    catch {
                        Write-Warning -Message "Failed to remove user $user. Error: $_"
                        $Result.Add("Failure")
                    }
                }
            }
            "GetUsers" {
                $users = Get-LocalUser
                $Result.AddRange($users)
            }
            "GetMembers" {
                $members = Get-LocalGroupMember -Group $Group
                $Result.AddRange($members)
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
                $username | ForEach-Object {
                    $params = @{
                        Name        = $_
                        ErrorAction = "SilentlyContinue"
                        Verbose     = $true
                    }
                    $user = Get-LocalUser @params
                    if ($user) {
                        if ($user.LockoutEnabled) {
                            $Result.Add("$user.Name is locked out")
                        }
                        else {
                            $Result.Add("$user.Name is not locked out")
                        }
                    }
                    else {
                        $Result.Add("$user.Name not found")
                    }
                }
            }
        }
    }
}