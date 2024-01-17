Function Show-UserSID {
    <#
    .SYNOPSIS
    Gets the Security Identifier (SID) for a specified user.

    .DESCRIPTION
    This function retrieves the Security Identifier (SID) for a given user by translating the user's account name.
    It utilizes the New-Object cmdlet to create an NTAccount object and then translates it to a SecurityIdentifier object to obtain the SID.

    .PARAMETER UserName
    Specifies the name of the user for whom to retrieve the SID.

    .EXAMPLE
    Show-UserSID -UserName "your_user"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, HelpMessage = "Specify the user name")]
        [ValidateNotNullOrEmpty()]
        [string]$UserName
    )
    try {
        $UserSID = (New-Object Security.Principal.NTAccount($UserName)).Translate([Security.Principal.SecurityIdentifier]).Value
        return $UserSID
    }
    catch {
        Write-Error -Message "Error getting SID for user '$UserName'. $_"
        return $null
    }
}
