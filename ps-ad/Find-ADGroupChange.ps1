function Find-ADGroupChange {
    <#
    .SYNOPSIS
    Detects and reports changes to Active Directory groups over a specified period.

    .DESCRIPTION
    This function checks for changes in specified Active Directory (AD) groups. It retrieves metadata about these changes, such as the time of the change, the user who made the change, and the attribute that was modified.
    Allows filtering by specific users and can produce detailed output with additional information like version and originating server. Can be customized to monitor specific groups, a set of users, and can report changes within a specified number of hours. Additionally, it supports detailed output for more granular information.

    .EXAMPLE
    Find-ADGroupChange -DetailedOutput -Verbose
    Find-ADGroupChange -Server "DC01" -MonitorGroup "group1-guid", "group2-guid" -Hour 48
    Find-ADGroupChange -Users "User1", "User2" -DetailedOutput -Verbose

    .NOTES
    v0.4.8
    #>
    [CmdletBinding(ConfirmImpact = "None", SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Specify the domain controller to connect to. If not provided, the nearest available DC will be used")]
        [ValidateNotNullOrEmpty()]
        [Alias("s")]
        [string]$Server = (Get-ADDomainController -Discover | Select-Object -ExpandProperty HostName),
    
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Provide the GUIDs of AD groups to monitor. By default, groups with AdminCount = 1 are monitored")]
        [ValidateNotNullOrEmpty()]
        [Alias("m")]
        [string[]]$MonitorGroup = (Get-ADGroup -Filter 'AdminCount -eq 1' -Server $Server).ObjectGUID,
    
        [Parameter(Mandatory = $false, HelpMessage = "Specify the number of hours to look back for changes, default is 24 hours")]
        [Alias("h")]
        [int]$Hour = 24,
    
        [Parameter(Mandatory = $false, HelpMessage = "Provide a list of users to filter changes by. If not provided, changes by all users are included")]
        [Alias("u")]
        [string[]]$Users = @(),
    
        [Parameter(Mandatory = $false, HelpMessage = "Enable this switch to include detailed output such as attribute versions and originating server")]
        [Alias("d")]
        [switch]$DetailedOutput = $false
    )
    BEGIN {
        if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
            Write-Error -Message "Active Directory module not available!" -ErrorAction Stop
            return
        }
        $Members = @()
        Write-Verbose -Message "Processing groups via Server: $Server"
    }
    PROCESS {
        foreach ($SingleGroup in $MonitorGroup) {
            if ($PSCmdlet.ShouldProcess("Group $SingleGroup", "Retrieve metadata")) {
                Write-Verbose -Message "Processing group $SingleGroup"
                try {
                    $GroupMetadata = Get-ADReplicationAttributeMetadata -Server $Server -Object $SingleGroup -ShowAllLinkedValues |
                    Where-Object { $_.IsLinkValue -and ($_.LastOriginatingChangeTime -gt (Get-Date).AddHours(-$Hour)) }
                    if ($Users) {
                        $GroupMetadata = $GroupMetadata | Where-Object { $Users -contains $_.OriginatingChangeDirectoryUser }
                    }
                    foreach ($Metadata in $GroupMetadata) {
                        $GroupInfo = @{
                            GroupDN        = (Get-ADGroup -Identity $SingleGroup).DistinguishedName
                            GroupName      = (Get-ADGroup -Identity $SingleGroup).Name
                            LastChangedBy  = $Metadata.OriginatingChangeDirectoryUser
                            LastChangeTime = $Metadata.LastOriginatingChangeTime
                            Attribute      = $Metadata.AttributeName
                        }
                        if ($DetailedOutput) {
                            $GroupInfo += @{
                                Version           = $Metadata.Version
                                OriginatingServer = $Metadata.OriginatingServer
                            }
                        }
                        $Members += [PSCustomObject]$GroupInfo
                    }
                }
                catch {
                    Write-Error -Message "Failed to process group $SingleGroup on server $Server. Error: $_" -ErrorAction Continue
                }
            }
        }
    }
    END {
        if ($Members.Count -eq 0) {
            Write-Verbose -Message "No changes detected within the last $Hour hours!"
        }
        else {
            $Members | Sort-Object LastChangeTime -Descending | Format-Table -AutoSize
        }
        $null = $Members
    }
}
