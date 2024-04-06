Function Get-GPOReplicationStatus {
    <#
    .SYNOPSIS
    Retrieves the replication status of Group Policy Objects (GPOs) across domain controllers.

    .DESCRIPTION
    This function retrieves the replication status of specified GPOs or all GPOs across domain controllers in the Active Directory environment. It checks both the Domain System (DS) version and the Sysvol version for both user and computer settings of the GPOs.

    .PARAMETER GPOName
    Name(s) of the Group Policy Object(s) to check for replication status.
    .PARAMETER All
    Use to check replication status for all GPOs.

    .EXAMPLE
    Get-GPOReplicationStatus -All
    Get-GPOReplicationStatus -GPOName "GPO1", "GPO2"

    .NOTES
    v0.0.3
    #>
    [CmdletBinding(DefaultParameterSetName = "All", ConfirmImpact = "None")]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "One", HelpMessage = "Enter the name of the Group Policy Object")]
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
                Write-Verbose -Message "Checking replication for specified GPO(s)..."
                if ($GPOName) {
                    foreach ($GPOItem in $GPOName) {
                        Write-Verbose -Message "Checking replication for GPO '$GPOItem' on Domain Controller '$($DomainController.Hostname)'"
                        $GPO = Get-GPO -Name $GPOItem -Server $DomainController.Hostname -ErrorAction Stop
                        $ReplicationStatus = [PSCustomObject]@{
                            GroupPolicyName       = $GPOItem
                            DomainController      = $DomainController.Hostname
                            UserVersion           = $GPO.User.DSVersion
                            UserSysVolVersion     = $GPO.User.SysvolVersion
                            ComputerVersion       = $GPO.Computer.DSVersion
                            ComputerSysVolVersion = $GPO.Computer.SysvolVersion
                        }
                        if ($null -eq $ReplicationStatus.UserVersion -or $null -eq $ReplicationStatus.ComputerVersion) {
                            Write-Warning -Message "Replication issue detected for GPO '$GPOItem' on Domain Controller '$($DomainController.Hostname)'. Please investigate."
                        }
                        else {
                            Write-Output -InputObject $ReplicationStatus
                        }
                    }
                }
                Write-Verbose -Message "Checking replication for all GPOs..."
                if ($All) {
                    Write-Verbose -Message "Checking replication for all GPOs on Domain Controller '$($DomainController.Hostname)'"
                    $GPOList = Get-GPO -All -Server $DomainController.Hostname -ErrorAction Stop
                    foreach ($GPO in $GPOList) {
                        $ReplicationStatus = [PSCustomObject]@{
                            GroupPolicyName       = $GPO.DisplayName
                            DomainController      = $DomainController.Hostname
                            UserVersion           = $GPO.User.DSVersion
                            UserSysVolVersion     = $GPO.User.SysvolVersion
                            ComputerVersion       = $GPO.Computer.DSVersion
                            ComputerSysVolVersion = $GPO.Computer.SysvolVersion
                        }
                        if ($null -eq $ReplicationStatus.UserVersion -or $null -eq $ReplicationStatus.ComputerVersion) {
                            Write-Warning -Message "Replication issue detected for GPO '$($GPO.DisplayName)' on Domain Controller '$($DomainController.Hostname)'. Please investigate."
                        }
                        else {
                            Write-Output -InputObject $ReplicationStatus
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
        Write-Verbose -Message "Checking Calculate and display total GPOs checked"
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
