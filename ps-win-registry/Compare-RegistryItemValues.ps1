function Compare-RegistryItemValues {
    <#
    .SYNOPSIS
    Compares the value of a specified registry property with an optional target value.

    .DESCRIPTION
    This function compares the value of a specified registry property at a given registry path. It checks whether the property exists and, if a target value is provided, compares the actual value of the property with the target value.

    .EXAMPLE
    Compare-RegistryItemValues -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' -Property 'ProductName' -TargetValue 'Windows 10 Pro' -Verbose

    .NOTES
    v0.3.3
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Enter a registry path using the PSDrive format")]
        [ValidateNotNullOrEmpty()]
        [Alias("p")]
        [string]$Path,
        
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = "Enter a registry key name")]
        [ValidateNotNullOrEmpty()]
        [Alias("n")]
        [string]$Property,
    
        [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true, HelpMessage = "Specify the target value to compare")]
        [Alias("tv")]
        [string]$TargetValue,
        
        [Parameter(Mandatory = $false, HelpMessage = "Indicates whether to use a transaction")]
        [Alias("ut")]
        [switch]$UseTransaction
    )
    BEGIN {
        $Exists = $false
        $PropertyMatch = $false
        $ActualValue = $null
        $StartTime = Get-Date
        Write-Verbose -Message "Starting registry comparison at $StartTime"
    }
    PROCESS {
        Write-Verbose -Message "Checking registry path: $Path and property: $Property"  
        try {
            if (Test-Path -Path $Path) {
                Write-Verbose -Message "Registry path exists. Retrieving property: $Property"
                if ($UseTransaction) {
                    $Item = Get-ItemProperty -Path $Path -Name $Property -ErrorAction "SilentlyContinue" -UseTransaction
                }
                else {
                    $Item = Get-ItemProperty -Path $Path -Name $Property -ErrorAction "SilentlyContinue"
                }
                if ($Item) {
                    $Exists = $true
                    $ActualValue = $Item.$Property
                    Write-Verbose -Message "Found property $Property with value: $ActualValue"
                    if ($TargetValue) {
                        Write-Verbose -Message "Comparing actual value with target value: $TargetValue"
                        $PropertyMatch = ($ActualValue -eq $TargetValue)
                    }
                }
                else {
                    Write-Warning "Property '$Property' not found at path: $Path"
                }
            }
            else {
                Write-Warning "Registry path '$Path' not found!"
            }
        }
        catch {
            Write-Error "An error occurred while accessing the registry path '$Path'. Details: $_"
        }
        $Obj = [PSCustomObject]@{
            "Path"     = $Path
            "Property" = $Property
            "Exists"   = $Exists
        }
        if ($TargetValue) {
            $Obj | Add-Member -MemberType NoteProperty -Name "TargetValue" -Value $TargetValue
            $Obj | Add-Member -MemberType NoteProperty -Name "ActualValue" -Value $ActualValue
            $Obj | Add-Member -MemberType NoteProperty -Name "PropertyMatch" -Value $PropertyMatch
        }
        Write-Output $Obj
    }
    END {
        $EndTime = Get-Date
        $ExecutionTime = New-TimeSpan -Start $StartTime -End $EndTime
        Write-Verbose -Message "Total execution time: $($ExecutionTime.TotalSeconds) seconds"
    }
}
