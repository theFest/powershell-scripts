Function Show-UserSID {
    <#
    .SYNOPSIS
    Gets the Security Identifier (SID) for specified users.

    .DESCRIPTION
    Retrieves the Security Identifier (SID) for users by translating their account names.

    .PARAMETER UserName
    Specifies the user names for which to retrieve the SID, accepts an array of user names.
    .PARAMETER OutputFormat
    Specifies the format for displaying the output, options: 'Table' (default), 'List', 'JSON'.
    .PARAMETER Domain
    Domain to filter users, if specified, only users from this domain will be processed.
    .PARAMETER LogToFile
    File path to log verbose information.
    .PARAMETER IncludeFullName
    Indicates whether to include the user's full name in the output.

    .EXAMPLE
    "user" | Get-UserSID
    Get-UserSID -UserName "user1", "user2" -OutputFormat JSON

    .NOTES
    v0.0.5
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, HelpMessage = "Specify the user names")]
        [ValidateNotNullOrEmpty()]
        [Alias("u")]
        [string[]]$UserName,

        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Specify the output format")]
        [ValidateSet("Table", "List", "JSON")]
        [Alias("o")]
        [string]$OutputFormat = "Table",

        [Parameter(Mandatory = $false, Position = 2, HelpMessage = "Specify the domain to filter users")]
        [Alias("d")]
        [string]$Domain,

        [Parameter(Mandatory = $false, HelpMessage = "Specify a file path to log verbose information.")]
        [Alias("l")]
        [string]$LogToFile,

        [Parameter(Mandatory = $false, HelpMessage = "User's full name in output")]
        [Alias("if")]
        [switch]$IncludeFullName
    )
    PROCESS {
        foreach ($User in $UserName) {
            try {
                if ($Domain -and $User -notmatch "@$Domain") {
                    Write-Warning -Message "Skipping user '$User' as it does not belong to the specified domain '$Domain'"
                    continue
                }
                $NTAccount = New-Object System.Security.Principal.NTAccount($User)
                $UserSID = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).Value
                $FullName = if ($IncludeFullName) {
                    $NTAccount.Translate([System.Security.Principal.NTAccount]).Value
                }
                $Result = [PSCustomObject]@{
                    UserName = $User
                    SID      = $UserSID
                    FullName = if ($FullName) { $FullName } else { 'n/a' }
                }
                switch ($OutputFormat) {
                    "List" {
                        Write-Output $Result.PSObject.Properties | ForEach-Object { "$($_.Name): $($_.Value)" }
                    }
                    "JSON" {
                        $Result | ConvertTo-Json
                    }
                    default {
                        Write-Output $Result | Format-Table -AutoSize
                    }
                }
                if ($LogToFile) {
                    Add-Content -Path $LogToFile -Value "$($Result.UserName): $($Result.SID) $($Result.FullName)"
                }
            }
            catch {
                Write-Error -Message "Failed to get SID for user '$User'. $_"
            }
        }
    }
}
