Function Get-ADForestInformation {
    <#
    .SYNOPSIS
    Retrieves information about the Active Directory forest.

    .DESCRIPTION
    This function fetches information about the Active Directory forest, such as forest-wide properties and settings. It can retrieve information for the current forest or for a specified forest using the ForestName parameter.

    .PARAMETER ForestName
    Name of the forest for which information is to be retrieved. If not provided, information for the current forest is retrieved.

    .PARAMETER Credential
    Credential object to authenticate against the forest. If specified, the cmdlet uses these credentials to connect to the forest.

    .EXAMPLE
    Get-ADForestInformation

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(ConfirmImpact = "None")]
    [OutputType([System.DirectoryServices.ActiveDirectory.Forest])]
    param (
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
        [Alias("f")]
        [string]$ForestName = (Get-ADForest).Name,

        [Parameter(Mandatory = $false)]
        [Alias("c")]
        [System.Management.Automation.Credential()]
        [PSCredential]$Credential
    )
    BEGIN {
        if (-not (Get-Module -Name ActiveDirectory -ListAvailable)) {
            throw "Active Directory module not available. This cmdlet requires Active Directory module!"
        }
        $ActiveDirectoryContext = $null
        $StartTime = Get-Date
    }
    PROCESS {
        try {
            if ($Credential) {
                $ActiveDirectoryContext = New-Object -TypeName System.DirectoryServices.ActiveDirectory.DirectoryContext -ArgumentList ("forest", $ForestName, $Credential.UserName, $Credential.Password)
            }
            else {
                $ActiveDirectoryContext = New-Object -TypeName System.DirectoryServices.ActiveDirectory.DirectoryContext -ArgumentList ("forest", $ForestName)
            }
            [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($ActiveDirectoryContext)
        }
        catch {
            Write-Error -Message $_.Exception.Message -ErrorAction Stop
        }
    }
    END {
        $EndTime = Get-Date
        $ElapsedTime = New-TimeSpan -Start $StartTime -End $EndTime
        Write-Verbose -Message "Time taken: $($ElapsedTime.TotalSeconds) seconds"
        $ActiveDirectoryContext = $null
    }
}
