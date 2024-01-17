Function Show-UserSID {
    <#
    .SYNOPSIS
    Gets the Security Identifier (SID) for a specified user.

    .DESCRIPTION
    Retrieves the Security Identifier (SID) for a user by translating the account name.

    .PARAMETER UserName
    Specifies the user name for which to retrieve the SID.

    .EXAMPLE
    "your_user" | Show-UserSID
    Show-UserSID -UserName "your_user" -OutputFormat List

    .NOTES
    v0.0.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, HelpMessage = "Specify the user name")]
        [ValidateNotNullOrEmpty()]
        [Alias("u")]
        [string]$UserName,

        [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Specify the output format. Options: 'Table' (default), 'List', 'JSON'")]
        [ValidateSet("Table", "List", "JSON")]
        [string]$OutputFormat = "Table"
    )
    PROCESS {
        try {
            $NTAccount = New-Object System.Security.Principal.NTAccount($UserName)
            $UserSID = $NTAccount.Translate([System.Security.Principal.SecurityIdentifier]).Value
            $Result = [PSCustomObject]@{
                UserName = $UserName
                SID      = $UserSID
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
        }
        catch {
            Write-Error -Message "Failed to get SID for user '$UserName'. $_"
            return $null
        }
    }
}
