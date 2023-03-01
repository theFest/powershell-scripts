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
        ## nitializing the Calculator object with the input values passed to the constructor
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
    ## Method to calculate percentage
    [int] Percentage() {
        if ($this.RightOperand -eq 0) {
            throw "Dividing by zero is impossible!"
        }
        return ($this.LeftOperand / $this.RightOperand) * 100
    }
}

Function SimpleCalc {
    <#
    .SYNOPSIS
    Simple calculator that shows how to use class.

    .DESCRIPTION
    Script block takes in numerical input via the LeftOperand and RightOperand parameters.
    Operation parameter determines which math operation to perform on the LeftOperand and RightOperand parameters.
    
    .PARAMETER Operation
    Mandatory - specifies the mathematical operation to perform.
    .PARAMETER LeftOperand
    Mandatory - value on the left side of the math operation.
    .PARAMETER RightOperand
    Mandatory - value on the right side of the math operation.
    .PARAMETER Percentage
    Optional - specifies whether to calculate percentage. If specified, the value of RightOperand should be considered as percentage of LeftOperand.
    
    .EXAMPLE
    SimpleCalc -Operation Add -LeftOperand 4 -RightOperand 4
    SimpleCalc -Operation Subtract -LeftOperand 64 -RightOperand 48
    SimpleCalc -Operation Multiply -LeftOperand 4 -RightOperand 8
    SimpleCalc -Operation Divide -LeftOperand 512 -RightOperand 8
    SimpleCalc -Operation Average -LeftOperand 56 -RightOperand 200
    SimpleCalc -Operation Percentage -LeftOperand 264 -Percentage 97
    
    .NOTES
    v0.6.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet("Add", "Subtract", "Multiply", "Divide", "Average", "Percentage")]
        [string]$Operation,

        [Parameter(Mandatory = $true, Position = 1)]
        [int]$LeftOperand,

        [Parameter(Mandatory = $false, Position = 2)]
        [int]$RightOperand,

        [Parameter(Position = 3)]
        [int]$Percentage
    )
    BEGIN {
        Write-Verbose -Message $Operation
        ## Here we can now initialize a new calculator object based on our class
        $SimpleCalc = [Calculator]::new($LeftOperand, $RightOperand, $Operation)
    }
    PROCESS {
		## Now, we will assign a switch statemant block to a variable called $Res
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
            "Percentage" {
                ($LeftOperand * $Percentage) / 100
            }
        }
    }
    END {
        if ($Operation -ne "Percentage") {
            Write-Output -InputObject "Result: $Res" 
        }
        else {
            Write-Output "$Percentage% of $LeftOperand is $Res"
        }
    }
}
