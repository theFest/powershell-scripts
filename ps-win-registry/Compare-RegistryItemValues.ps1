Function Compare-RegistryItemValues {
    <#
    .SYNOPSIS
    Checks if a registry key exists and compares its value against a provided target value.

    .DESCRIPTION
    This function checks if a specified registry key exists and, optionally, compares its value against a provided target value.

    .PARAMETER Path
    Path of the registry key in the PSDrive format.
    .PARAMETER Property
    Specifies the name of the registry key.
    .PARAMETER TargetValue
    The target value to compare with the registry key's value.
    .PARAMETER UseTransaction
    Indicates whether to use a transaction while accessing the registry.

    .EXAMPLE
    Compare-RegistryItemValues -Path 'HKLM:\SOFTWARE\Example' -Property 'KeyName' -TargetValue 'ExpectedValue' -UseTransaction

    .NOTES
    v0.0.1
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
        Write-Verbose -Message "Script started at $StartTime"
    }
    PROCESS {
        Write-Verbose -Message ("Looking for {0} in {1}" -f $Property, $Path)
        if (Test-Path -Path $Path) {
            if ($UseTransaction) {
                $Item = Get-ItemProperty -Path $Path -Name $Property -ErrorAction "SilentlyContinue" -UseTransaction
            }
            else {
                $Item = Get-ItemProperty -Path $Path -Name $Property -ErrorAction "SilentlyContinue" 
            }
            if ($Item) {
                Write-Verbose -Message ($Item | Select-Object * | Out-String)
                $Exists = $true
                if ($TargetValue) {
                    $ActualValue = $Item.$Property
                    Write-Verbose -Message "Retrieving value for $Property"
                    if ($ActualValue -eq $TargetValue) {
                        $PropertyMatch = $true
                    }
                    else {
                        $PropertyMatch = $false
                    }
                }
            }
            else {
                Write-Host "Not found!" -ForegroundColor Yellow
                $Exists = $false
                $PropertyMatch = $false
            }
        }
        else {
            Write-Warning -Message "Failed to find $Path!"
            $Exists = $false
        }
        $Obj = New-Object -TypeName PSObject -Property @{
            "Path"     = $Path
            "Property" = $Property
            "Exists"   = $Exists
        }
        if ($TargetValue) {
            Write-Verbose -Message "Adding TargetValue Properties"
            $Obj | Add-Member -MemberType NoteProperty -Name "PropertyMatch" -Value $PropertyMatch
            $Obj | Add-Member -MemberType NoteProperty -Name "TargetValue" -Value $TargetValue
            $Obj | Add-Member -MemberType NoteProperty -Name "ActualValue" -Value $ActualValue
        }
        Write-Output -InputObject $Obj
    }
    END {
        $EndTime = Get-Date
        $ExecutionTime = New-TimeSpan -Start $StartTime -End $EndTime
        Write-Host "Script completed at $EndTime" -ForegroundColor DarkCyan
        Write-Verbose -Message "Total execution time: $($ExecutionTime.TotalSeconds) seconds"
    }
}
