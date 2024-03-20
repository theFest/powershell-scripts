Function Find-ADGroupChange {
    <#
    .SYNOPSIS
    Retrieves information about Active Directory groups and their changes.

    .DESCRIPTION
    This function retrieves information about Active Directory groups and their changes, such as the distinguished name and name of the group, and filters the changes based on the last originating change time.

    .PARAMETER Server
    Active Directory server to query for group information. If not specified, the function will automatically discover an appropriate domain controller.
    .PARAMETER MonitorGroup
    Array of group GUIDs to monitor for changes. If not specified, groups with AdminCount equal to 1 will be monitored.
    .PARAMETER Hour
    Specifies the time window, in hours, to filter the changes. Only changes within the specified time window will be included. Default is 24 hours.

    .EXAMPLE
    Find-ADGroupChange -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(ConfirmImpact = "None")]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("s")]
        [string]$Server = (Get-ADDomainController -Discover | Select-Object -ExpandProperty HostName),

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("m")]
        [string[]]$MonitorGroup = (Get-ADGroup -Filter 'AdminCount -eq 1' -Server $Server).ObjectGUID,

        [Parameter(Mandatory = $false)]
        [Alias("h")]
        [int]$Hour = 24
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
            Write-Verbose -Message "Processing group $SingleGroup"
            try {
                $Members += Get-ADReplicationAttributeMetadata -Server $Server -Object $SingleGroup -ShowAllLinkedValues | 
                Where-Object { $_.IsLinkValue } | 
                Select-Object @{
                    Name       = 'GroupDN'
                    Expression = { (Get-ADGroup -Identity $SingleGroup).DistinguishedName }
                }, @{
                    Name       = 'GroupName'
                    Expression = { (Get-ADGroup -Identity $SingleGroup).Name }
                }, *
            }
            catch {
                Write-Error -ErrorRecord $_ -ErrorAction Stop
            }
        }
    }
    END {
        $Members | Where-Object { $_.LastOriginatingChangeTime -gt (Get-Date).AddHours(-$Hour) }
        $null = $Members
    }
}
