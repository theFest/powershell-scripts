Function InvokeFunction {
    <#
    .SYNOPSIS
    Example function using simple background job.

    .DESCRIPTION
    purpose of this function is to execute a command called "DoSomething" for each item in the "InputObject" array, it accepts several parameters that allow the user to customize the behavior of the command.

    .PARAMETER InputObject
    Parameter description
    .PARAMETER Param1
    Parameter description
    .PARAMETER Param2
    Parameter description
    .PARAMETER Switch1
    Parameter description
    .PARAMETER Switch2
    Parameter description
    .PARAMETER AsJob
    Parameter description
    .PARAMETER AdvancedParam1
    Parameter description
    .PARAMETER AdvancedParam2
    Parameter description
    .PARAMETER AdvancedParam3
    Parameter description

    .PARAMETER AdvancedParam4
    Parameter description

    .EXAMPLE
    An example

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [string[]]$InputObject,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Param1,

        [Parameter(Mandatory = $true, Position = 2)]
        [string]$Param2,

        [Parameter(Mandatory = $false)]
        [switch]$Switch1,

        [Parameter(Mandatory = $false)]
        [switch]$Switch2,

        [Parameter(Mandatory = $false)]
        [switch]$AsJob,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Option1", "Option2")]
        [string]$AdvancedParam1,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$AdvancedParam2 = 3,

        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path $_ })]
        [string]$AdvancedParam3,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$AdvancedParam4
    )
    BEGIN {
        $results = @()
        $params = @{
            'Param1' = $Param1
            'Param2' = $Param2
        }
        if ($Switch1) {
            $params['Switch1'] = $true
        }
        if ($Switch2) {
            $params['Switch2'] = $true
        }
    }
    PROCESS {
        foreach ($item in $InputObject) {
            if ($PSCmdlet.ShouldProcess($item)) {
                $result = ## DoSomething -Input $item @params
                $results += $result
            }
        }
    }
    END {
        if ($AsJob) {
            $job = Start-Job -ScriptBlock {
                param($InputObject, $Params, $Switch1, $Switch2, $AdvancedParam1, $AdvancedParam2, $AdvancedParam3, $AdvancedParam4)
                InvokeFunction -InputObject $InputObject -AsJob $false @Params -Switch1:$Switch1 -Switch2:$Switch2 -AdvancedParam1:$AdvancedParam1 -AdvancedParam2:$AdvancedParam2 -AdvancedParam3:$AdvancedParam3 -AdvancedParam4:$AdvancedParam4
            } -ArgumentList $InputObject, $params, $Switch1, $Switch2, $AdvancedParam1, $AdvancedParam2, $AdvancedParam3, $AdvancedParam4
            Write-Output "Job $($job.Id) started."
            Write-Output $job
        }
        else {
            Write-Output $results
        }
    }
}
