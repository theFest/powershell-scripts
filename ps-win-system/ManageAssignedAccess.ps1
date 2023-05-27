Function ManageAssignedAccess {
    <#
    .SYNOPSIS
    Manages Assigned Access settings for a specified user account.

    .DESCRIPTION
    The ManageAssignedAccess function is used to manage the Assigned Access settings for a specified user account, provides three actions:
    - Clear: Removes the Assigned Access settings for all users.
    - Get: Retrieves the Assigned Access settings for all users.
    - Set: Sets the Assigned Access settings for a specified user account.

    .PARAMETER Action
    Mandtory - specifies the action to be performed, the available options are Clear, Get, and Set.
    .PARAMETER UserName
    NotMandtory - username for which to set the Assigned Access settings.
    .PARAMETER UserSID
    NotMandtory - security identifier (SID) for which to set the Assigned Access settings.
    .PARAMETER AppUserModelId
    NotMandtory - application user model ID for which to set the Assigned Access settings.
    .PARAMETER ApplicationName
    NotMandtory - application name for which to set the Assigned Access settings.
    
    .EXAMPLE
    Clear-AssignedAccess
    Get-AssignedAccess
    Set-AssignedAccess -UserName "your_user" -AppUserModelId "Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge"
    Set-AssignedAccess -UserSID "S-1-5-21-3165297888-1234567890-1234567890-1001" -AppName "Microsoft Edge"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("Clear", "Get", "Set")]
        [string]$Action,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]$UserName,

        [Parameter(Mandatory = $false, Position = 2)]
        [string]$UserSID,

        [Parameter(Mandatory = $false)]
        [string]$AppUserModelId,

        [Parameter(Mandatory = $false)]
        [string]$AppName
    )
    switch ($Action) {
        "Clear" {
            Clear-AssignedAccess -Verbose
        }
        "Get" {
            Get-AssignedAccess -Verbose
        }
        "Set" {
            if ($UserName) {
                Set-AssignedAccess -UserName $UserName -AppUserModelId $AppUserModelId -Verbose
            }
            elseif ($UserSID) {
                Set-AssignedAccess -UserSID $UserSID -AppName $AppName -Verbose
            }
        }
        default {
            throw "Invalid Action, choose 'Clear', 'Get' or 'Set'"
        }
    }
}
