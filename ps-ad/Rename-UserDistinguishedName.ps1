Function Rename-UserDistinguishedName {
    <#
    .SYNOPSIS
    Converts the DistinguishedName for all users matching the specified filter.

    .DESCRIPTION
    This function retrieves all Active Directory users based on the provided filter and checks if their DistinguishedName matches their SamAccountName. If not, it updates the DistinguishedName to match the SamAccountName.

    .PARAMETER Filter
    Specifies the filter to use when retrieving users, default value is "*", which retrieves all users. Accepts wildcard characters.

    .EXAMPLE
    Rename-UserDistinguishedName -Filter "Name -like 'John*'"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(ConfirmImpact = "Medium", SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Filter = "*"
    )
    try {
        $AllUsers = Get-ADUser -Filter $Filter -Properties SamAccountName, UserPrincipalName, DistinguishedName -ErrorAction Stop |
        Select-Object -Property SamAccountName, UserPrincipalName, DistinguishedName |
        Where-Object { $_.UserPrincipalName -and $_.SamAccountName }
        if ($pscmdlet.ShouldProcess("All Users", "Set")) {
            foreach ($User in $AllUsers) {
                $OldRDN = $User.DistinguishedName.split(',')[0].split('=')[1]
                if ($OldRDN -ne $User.SamAccountName) {
                    Write-Verbose -Message "Changing DistinguishedName for $($User.SamAccountName)..."
                    Rename-ADObject -Identity $User.DistinguishedName -NewName $User.SamAccountName -Confirm:$false -ErrorAction Stop
                }
            }
        }
    }
    catch {
        [Management.Automation.ErrorRecord]$ErrorRec = $_
        $Info = [PSCustomObject]@{
            Exception = $ErrorRec.Exception.Message
            Reason    = $ErrorRec.CategoryInfo.Reason
            Target    = $ErrorRec.CategoryInfo.TargetName
            Script    = $ErrorRec.InvocationInfo.ScriptName
            Line      = $ErrorRec.InvocationInfo.ScriptLineNumber
            Column    = $ErrorRec.InvocationInfo.OffsetInLine
        }
        $Info | Out-String | Write-Verbose
        Write-Host $ErrorRec.Exception.Message -ForegroundColor Cyan
    }
}
