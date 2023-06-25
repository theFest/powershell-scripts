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
    This is an example of a PowerShell function that uses a background job to execute a command called "DoSomething" for each item in the "InputObject" array.
    The function accepts several parameters that allow the user to customize the behavior of the command, such as specifying parameters and switches.
    The function uses the PowerShell CmdletBinding attribute to provide a number of features, including support for ShouldProcess and ConfirmImpact.
    The ShouldProcess feature allows the function to ask the user for confirmation before performing any actions that could have an impact, while the ConfirmImpact feature allows the function to specify the level of impact for which confirmation is required.
    The function uses the Begin, Process, and End blocks to perform different tasks. In the Begin block, the function initializes variables and sets up the parameters that will be passed to the DoSomething command.
    In the Process block, the function loops through each item in the InputObject array, calls the DoSomething command with the appropriate parameters, and adds the results to an array.
    In the End block, the function either returns the results or starts a background job to run the function with the AsJob parameter set to true.
    This function provides an example of how to use PowerShell's background job feature to perform tasks asynchronously, which can be useful for long-running tasks or tasks that need to be performed in the background while the user continues to work on other tasks.
    The function also demonstrates how to use various PowerShell features, such as parameter validation and support for ShouldProcess and ConfirmImpact.

    .NOTES
    v0.0.1
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

function DoSomething {
    param($In, $Param1, $Param2, $Switch1, $Switch2, $AdvancedParam1, $AdvancedParam2, $AdvancedParam3, $AdvancedParam4)
    $Output = "Input: $In, Param1: $Param1, Param2: $Param2, Switch1: $Switch1, Switch2: $Switch2, AdvancedParam1: $AdvancedParam1, AdvancedParam2: $AdvancedParam2, AdvancedParam3: $AdvancedParam3, AdvancedParam4: $AdvancedParam4"
    Write-Output $Output
}
