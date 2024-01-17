Function Show-UserSID {
    <#
    .SYNOPSIS
    Gets the Security Identifier (SID) for a specified user.

    .DESCRIPTION
    Retrieves the Security Identifier (SID) for a user by translating the account name.

    .PARAMETER UserName
    Specifies the user name for which to retrieve the SID.

    .EXAMPLE
    Show-UserSID -UserName "your_user"

    .NOTES
    v0.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline = $true, HelpMessage = "Specify the user name")]
        [ValidateNotNullOrEmpty()]
        [Alias("u")]
        [string]$UserName
    )
    process {
        try {
            $NTAccount = New-Object System.Security.Principal.NTAccount($UserName)
            $UserSID = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).Value
            $Result = [PSCustomObject]@{
                UserName = $UserName
                SID      = $UserSID
            }
            Write-Output -InputObject $Result
        }
        catch {
            Write-Error -Message "Failed to get SID for user '$UserName'. $_"
            return $null
        }
    }
}
