Class Calculator {
    ## Input parameters on the class
    [int]$LeftOperand
    [int]$RightOperand
    [string]$Operation

    ## Constructor to initialize object properties with the given parameters
    Calculator(
        [int]$LeftOperand,
        [int]$RightOperand,
        [string]$Operation
    ) {
        ## Add input parameter checks
        if (-not [int]::TryParse($LeftOperand, [ref]$null)) {
            throw "LeftOperand must be an integer."
        }
        if (-not [int]::TryParse($RightOperand, [ref]$null)) {
            throw "RightOperand must be an integer."
        }
        if ($Operation -notin @("Add", "Subtract", "Multiply", "Divide", "Average", "Remainder", "Power", "Percentage", "Modulus")) {
            throw "Operation must be a valid option."
        }
        ## Initializing the Calculator object with the input values passed to the constructor
        $this.LeftOperand = $LeftOperand
        $this.RightOperand = $RightOperand
        $this.Operation = $Operation
    }
    ## Method to perform addition
    [int] Add() {
        return $this.LeftOperand + $this.RightOperand
    }
    ## Method to perform subtraction
    [int] Subtract() {
        return $this.LeftOperand - $this.RightOperand
    }
    ## Method to perform multiplication
    [int] Multiply() {
        return $this.LeftOperand * $this.RightOperand
    }
    ## Method to perform division
    [int] Divide() {
        if ($this.RightOperand -eq 0) {
            throw "Dividing by zero is impossible!"
        }
        return $this.LeftOperand / $this.RightOperand
    }
    ## Method to calculate average
    [int] Average() {
        return ($this.LeftOperand + $this.RightOperand) / 2
    }
    ## Method to calculate remainder
    [int] Remainder() {
        return $this.LeftOperand % $this.RightOperand
    }
    ## Method to perform power calculation
    [int] Power() {
        return [Math]::Pow($this.LeftOperand, $this.RightOperand)
    }
    ## Method to calculate percentage
    [int] Percentage() {
        if ($this.RightOperand -eq 0) {
            throw "Dividing by zero is impossible!"
        }
        return [Math]::Round(($this.LeftOperand * $this.Percentage) / 100)
    }
    ## Method to perform modulus calculation
    [int] Modulus() {
        if ($this.RightOperand -eq 0) {
            throw "Dividing by zero is impossible!"
        }
        return $this.LeftOperand % $this.RightOperand
    }
}

Function Invoke-CustomCalculator {
    <#
    .SYNOPSIS
    Simple calculator that shows how to use class.

    .DESCRIPTION
    Numerical input via the LeftOperand and RightOperand parameters with Operation parameter determines which math operation.

    .PARAMETER Operation
    Mandatory - specifies the mathematical operation to perform.
    .PARAMETER LeftOperand
    Mandatory - value on the left side of the math operation.
    .PARAMETER RightOperand
    NotMandatory - value on the right side of the math operation.
    .PARAMETER Percentage
    NotMandatory - specifies whether to calculate percentage. If specified, the value of RightOperand should be considered as percentage of LeftOperand.

    .EXAMPLE
    Invoke-CustomCalculator -Operation Add -LeftOperand 4 -RightOperand 4
    Invoke-CustomCalculator -Operation Subtract -LeftOperand 64 -RightOperand 48
    Invoke-CustomCalculator -Operation Multiply -LeftOperand 4 -RightOperand 8
    Invoke-CustomCalculator -Operation Remainder -LeftOperand 10 -RightOperand 3
    Invoke-CustomCalculator -Operation Divide -LeftOperand 512 -RightOperand 8
    Invoke-CustomCalculator -Operation Average -LeftOperand 56 -RightOperand 200
    Invoke-CustomCalculator -Operation Power -LeftOperand 8 -RightOperand 3
    Invoke-CustomCalculator -Operation Percentage -LeftOperand 1600 -Percentage 64
    Invoke-CustomCalculator -Operation Modulus -LeftOperand 20048 -RightOperand 3000

    .NOTES
    v0.6.5
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("Add", "Subtract", "Multiply", "Divide", "Average", "Remainder", "Power", "Percentage", "Modulus")]
        [string]$Operation,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateScript({ [int]::TryParse($_, [ref]$null) })]
        [int]$LeftOperand,

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateScript({ [int]::TryParse($_, [ref]$null) })]
        [int]$RightOperand,

        [Parameter(Position = 3)]
        [ValidateRange(0, 100)]
        [int]$Percentage
    )
    BEGIN {
        try {
            $SimpleCalc = [Calculator]::new($LeftOperand, $RightOperand, $Operation)
        }
        catch {
            throw "Error: $_"
        }
    }
    PROCESS {
        $Res = switch ($Operation) {
            "Add" {
                $SimpleCalc.Add()
            }
            "Subtract" {
                $SimpleCalc.Subtract()
            }
            "Multiply" {
                $SimpleCalc.Multiply()
            }
            "Divide" {
                $SimpleCalc.Divide()
            }
            "Average" {
                $SimpleCalc.Average()
            }
            "Remainder" {
                $SimpleCalc.Remainder()
            }
            "Power" {
                $SimpleCalc.Power()
            }
            "Percentage" {
                [Math]::Round(($LeftOperand * $Percentage) / 100)
            }
            "Modulus" {
                $LeftOperand % $RightOperand
            }
        }
    }
    END {
        if ($Operation -ne "Percentage") {
            Write-Output -InputObject "Result: $Res"
        }
        else {
            Write-Output "Result: $Percentage% of $LeftOperand is $Res"
        }
    }
}
