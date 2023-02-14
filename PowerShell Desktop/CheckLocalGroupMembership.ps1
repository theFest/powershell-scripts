Function CheckLocalGroupMembership {
    <#
    .SYNOPSIS
    Retrieves the members of the specified local groups on a Windows system.
    
    .DESCRIPTION
    This script retrieves the members of the specified local groups on a Windows system.
    It takes one or more group names as input, retrieves the members of each group, and returns the group name and member name as output.
    
    .PARAMETER Group
    Manatory - takes one or more group names as input. The script will retrieve the members of each of the specified groups.
    
    .EXAMPLE
    CheckLocalGroupMembership -Group "Users", "Administrators"
    CheckLocalGroupMembership -Group "Administrators", "Backup Operators"
    CheckLocalGroupMembership -Group 'Administrators', 'Users' | Export-Csv -Path "$env:USERPROFILE\Desktop\UserManagement.csv" -NoTypeInformation
    $GroupsToCheck = Import-Csv -Path "$env:USERPROFILE\Desktop\GroupsToCheckFile.csv" | Select-Object -ExpandProperty Group
    CheckLocalGroupMembership -Group $GroupsToCheck | Export-Csv -Path "$env:USERPROFILE\Desktop\GroupMembership.csv" -NoTypeInformation
    
    .NOTES
    V1.0
    #>
    [CmdletBinding()]
    Param (
      [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
      [string[]]$Group
    )
    BEGIN {
      $Result = @()
    }
    PROCESS {
      foreach ($GroupName in $Group) {
        try {
          $Members = Get-LocalGroupMember -Group $GroupName
          foreach ($Member in $Members) {
            $Result += [PSCustomObject]@{
              Group  = $GroupName
              Member = $Member.Name
            }
          }
        }
        catch {
          Write-Error "Error: Unable to retrieve members of group '$GroupName'"
        }
      }
    }
    END {
      $Result | Select-Object Group, Member
    }
  }