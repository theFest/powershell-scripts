Function Invoke-Function {
    <#
    .SYNOPSIS
    A versatile PowerShell function for executing a command called "DoSomething" for each item in an array, with customizable parameters and asynchronous job support.

    .DESCRIPTION
    The Invoke-Function PowerShell function is designed to execute a command named "DoSomething" for each item in the "InputObject" array. It offers flexibility through various parameters, allowing users to customize the behavior of the command. It provides the option to run tasks asynchronously using PowerShell's background job feature, making it suitable for lengthy operations or tasks that should run in the background while other work continues.

    .PARAMETER InputObject
    Specifies the array of items on which the "DoSomething" command will be executed.
    .PARAMETER Param1
    Specifies a required parameter for the "DoSomething" command.
    .PARAMETER Param2
    Specifies a required parameter for the "DoSomething" command.
    .PARAMETER Switch1
    Indicates an optional switch for the "DoSomething" command.
    .PARAMETER Switch2
    Indicates another optional switch for the "DoSomething" command.
    .PARAMETER AsJob
    A switch that enables running the function in the background as a job.
    .PARAMETER AdvancedParam1
    Specifies an optional parameter that accepts values from a predefined set ("Option1" or "Option2").
    .PARAMETER AdvancedParam2
    Specifies an optional parameter that accepts an integer value in the range of 1 to 5.
    .PARAMETER AdvancedParam3
    Specifies an optional parameter that should be a valid file path.
    .PARAMETER AdvancedParam4
    Specifies an optional parameter that should not be null or empty.

    .EXAMPLE
    This example demonstrates the use of the Invoke-Function with various parameters:
    $items = @("Item1", "Item2", "Item3")
    Invoke-Function -InputObject $items -Param1 "Value1" -Param2 "Value2" -Switch1 -AdvancedParam1 "Option1" -AdvancedParam2 4 -AdvancedParam3 "C:\Example\File.txt" -AdvancedParam4 "SomeValue"

    .NOTES
    v0.0.2
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
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
        $Results = @()
        $Params = @{
            "Param1" = $Param1
            "Param2" = $Param2
        }
        if ($Switch1) {
            $Params["Switch1"] = $true
        }
        if ($Switch2) {
            $Params["Switch2"] = $true
        }
    }
    PROCESS {
        foreach ($Item in $InputObject) {
            if ($PSCmdlet.ShouldProcess($Item)) {
                $Result = ## DoSomething -Input $item @params
                $Results += $Result
            }
        }
    }
    END {
        if ($AsJob) {
            $Job = Start-Job -ScriptBlock {
                param($InputObject, $Params, $Switch1, $Switch2, $AdvancedParam1, $AdvancedParam2, $AdvancedParam3, $AdvancedParam4)
                InvokeFunction -InputObject $InputObject -AsJob $false @Params -Switch1:$Switch1 -Switch2:$Switch2 `
                    -AdvancedParam1:$AdvancedParam1 `
                    -AdvancedParam2:$AdvancedParam2 `
                    -AdvancedParam3:$AdvancedParam3 `
                    -AdvancedParam4:$AdvancedParam4
            } -ArgumentList $InputObject, $params, $Switch1, $Switch2, $AdvancedParam1, $AdvancedParam2, $AdvancedParam3, $AdvancedParam4
            Write-Verbose -Message "Job $($Job.Id) started."
            Write-Output -InputObject $Job
        }
        else {
            Write-Output $Results
        }
    }
}

Function DoSomething {
    param($In, $Param1, $Param2, $Switch1, $Switch2, $AdvancedParam1, $AdvancedParam2, $AdvancedParam3, $AdvancedParam4)
    $Output = "Input: $In, Param1: $Param1, Param2: $Param2, Switch1: $Switch1, Switch2: $Switch2, AdvancedParam1: $AdvancedParam1, AdvancedParam2: $AdvancedParam2, AdvancedParam3: $AdvancedParam3, AdvancedParam4: $AdvancedParam4"
    Write-Output $Output
}
