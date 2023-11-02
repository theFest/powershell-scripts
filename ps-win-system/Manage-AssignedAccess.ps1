Function Manage-AssignedAccess {
    <#
    .SYNOPSIS
    Manages Assigned Access settings for a specified user account.

    .DESCRIPTION
    The Manage-AssignedAccess function is used to manage the Assigned Access settings for a specified user account. It provides three actions:
    - Clear: Removes the Assigned Access settings for all users.
    - Get: Retrieves the Assigned Access settings for all users.
    - Set: Sets the Assigned Access settings for a specified user account.

    .PARAMETER Action
    Mandatory - Specifies the action to be performed, with available options: Clear, Get, and Set.
    .PARAMETER UserName
    Not Mandatory - Username for which to set the Assigned Access settings.
    .PARAMETER UserSID
    Not Mandatory - Security identifier (SID) for which to set the Assigned Access settings.
    .PARAMETER AppUserModelId
    Not Mandatory - Application user model ID for which to set the Assigned Access settings.
    .PARAMETER ApplicationName
    Not Mandatory - Application name for which to set the Assigned Access settings.
    
    .EXAMPLE
    Manage-AssignedAccess -Action Clear
    Manage-AssignedAccess -Action Get
    Manage-AssignedAccess -Action Set -UserName "your_user" -AppUserModelId "Microsoft.MicrosoftEdge_8wekyb3d8bbwe!MicrosoftEdge"
    Manage-AssignedAccess -Action Set -UserSID "S-1-5-21-3165297888-1234567890-1234567890-1001" -ApplicationName "Microsoft Edge"

    .NOTES
    Version: 0.1.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("Clear", "Get", "Set")]
        [string]$Action,

        [Parameter(Mandatory = $false)]
        [string]$UserName,

        [Parameter(Mandatory = $false)]
        [string]$UserSID,

        [Parameter(Mandatory = $false)]
        [string]$AppUserModelId,

        [Parameter(Mandatory = $false)]
        [string]$ApplicationName
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
                Set-AssignedAccess -UserSID $UserSID -AppName $ApplicationName -Verbose
            }
        }
        default {
            Write-Error "Invalid Action, choose 'Clear', 'Get' or 'Set'"
        }
    }
}
