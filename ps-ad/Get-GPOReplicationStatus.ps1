Function Get-GPOReplicationStatus {
    <#
    .SYNOPSIS
    Retrieves replication status of Group Policy Objects (GPOs) in the specified domain.

    .DESCRIPTION
    This function retrieves replication status information of Group Policy Objects (GPOs) within a domain. It can retrieve the replication status for a specific GPO or for all GPOs in the domain. This information includes the version numbers of the GPOs in both the Active Directory and the SYSVOL share for both user and computer configurations.

    .PARAMETER GPOName
    Name of the GPO for which replication status is to be retrieved.
    .PARAMETER All
    Indicates whether to retrieve replication status for all GPOs in the domain.

    .EXAMPLE
    Get-GPOReplicationStatus -All

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(DefaultParameterSetName = "All", ConfirmImpact = "None")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "One", HelpMessage = "Enter the name of the Group Policy Object")]
        [ValidateNotNullOrEmpty()]
        [Alias("n")]
        [string[]]$GPOName,

        [Parameter(ParameterSetName = "All", HelpMessage = "Retrieves all Group Policy Objects")]
        [Alias("a")]
        [switch]$All
    )
    BEGIN {
        Write-Verbose -Message "Checking if ActiveDirectory module is available..."
        if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
            Write-Warning -Message "ActiveDirectory module is not available. Please install RSAT (Remote Server Administration Tools) and ensure the module is imported!"
            return
        }
        Write-Verbose -Message "Checking if GroupPolicy module is available..."
        if (-not (Get-Module -ListAvailable -Name GroupPolicy)) {
            Write-Warning -Message "GroupPolicy module is not available. Please ensure the Group Policy Management feature is installed!"
            return
        }
    }
    PROCESS {
        foreach ($DomainController in (Get-ADDomainController -Filter * -ErrorAction Stop)) {
            Write-Host "Domain Controller found: $($DomainController.Hostname)" -ForegroundColor Cyan
            try {
                if ($GPOName) {
                    Write-Verbose -Message "Checking replication for GPO '$GPOItem' on Domain Controller '$($DomainController.Hostname)'"
                    foreach ($GPOItem in $GPOName) {
                        $GPO = Get-GPO -Name $GPOItem -Server $DomainController.Hostname -ErrorAction Stop
                        [PSCustomObject]@{
                            GroupPolicyName       = $GPOItem
                            DomainController      = $DomainController.Hostname
                            UserVersion           = $GPO.User.DSVersion
                            UserSysVolVersion     = $GPO.User.SysvolVersion
                            ComputerVersion       = $GPO.Computer.DSVersion
                            ComputerSysVolVersion = $GPO.Computer.SysvolVersion
                        }
                    }
                }
                if ($All) {
                    Write-Verbose -Message "Checking replication for all GPOs on Domain Controller '$($DomainController.Hostname)'"
                    $GPOList = Get-GPO -All -Server $DomainController.Hostname -ErrorAction Stop
                    foreach ($GPO in $GPOList) {
                        [PSCustomObject]@{
                            GroupPolicyName       = $GPO.DisplayName
                            DomainController      = $DomainController.Hostname
                            UserVersion           = $GPO.User.DSVersion
                            UserSysVolVersion     = $GPO.User.SysvolVersion
                            ComputerVersion       = $GPO.Computer.DSVersion
                            ComputerSysVolVersion = $GPO.Computer.SysvolVersion
                        }
                    }
                }
            }
            catch {
                Write-Warning -Message "Error occurred: $($_.Exception.Message)"
            }
        }
    }
    END {
        $TotalGPOsChecked = @()
        foreach ($GPO in $PSBoundParameters['GPOName']) {
            $TotalGPOsChecked += $GPO
        }
        if ($All) {
            $TotalGPOsChecked += "All GPOs"
        }
        Write-Verbose -Message "AD GPO replication check completed. Total GPOs checked: $($TotalGPOsChecked.Count)"
    }
}
