Function Show-FSMORoles {
    <#
    .SYNOPSIS
    Retrieves the Flexible Single Master Operations (FSMO) roles in Active Directory.

    .DESCRIPTION
    This function retrieves the FSMO roles in Active Directory, including the Schema Master, Domain Naming Master, Infrastructure Master, Relative Identifier (RID) Master, and Primary Domain Controller (PDC) Emulator.

    .PARAMETER Credential
    Specifies the credentials to use when connecting to Active Directory. If not specified, the function uses the current user's credentials.

    .EXAMPLE
    Show-FSMORoles -Verbose

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(DefaultParameterSetName = "NoCredential")]
    param (
        [Parameter(ParameterSetName = "Credential")]
        [System.Management.Automation.PSCredential]
        $Credential
    )
    BEGIN {
        Write-Verbose -Message "Checking if Active Directory module is available..."
        try {
            if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
                Write-Verbose -Message "Importing Active Directory module..."
                Import-Module ActiveDirectory -ErrorAction Stop -Verbose
            }
        }
        catch {
            Write-Error -Message "Failed to import Active Directory module: $_"
            return
        }
    }
    PROCESS {
        try {
            Write-Verbose -Message "Retrieving FSMO roles..."
            $Forest = if ($Credential) {
                Get-ADForest -Credential $Credential -ErrorAction Stop
            }
            else {
                Get-ADForest -Verbose
            }
            $Domain = if ($Credential) {
                Get-ADDomain -Credential $Credential -ErrorAction Stop
            }
            else {
                Get-ADDomain -Verbose
            }
            $Properties = [ordered]@{
                SchemaMaster         = $Forest.SchemaMaster                                           
                DomainNamingMaster   = $Forest.DomainNamingMaster
                InfrastructureMaster = $Domain.InfrastructureMaster
                RIDMaster            = $Domain.RIDMaster
                PDCEmulator          = $Domain.PDCEmulator
            }
            Write-Verbose -Message "FSMO roles retrieved successfully"
            [PSCustomObject]$Properties
        }
        catch {
            Write-Error $_.Exception.Message
            return
        }
    }
    END {
        Write-Output -InputObject $Properties
    }
}
