Class Calculator {
    [int]$LeftOperand
    [int]$RightOperand
    [string]$Operation

    ## Constructor to initialize object properties
    Calculator(
        [int]$LeftOperand,
        [int]$RightOperand,
        [string]$Operation
    ) {
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
            throw "You can't divide by zero!"
        }
        return $this.LeftOperand / $this.RightOperand
    }
    ## Method to calculate average
    [int] Average() {
        return ($this.LeftOperand + $this.RightOperand) / 2
    }
}

Function SimpleCalc {
    <#
    .SYNOPSIS
    Simple calculator that shows how to use class.

    .DESCRIPTION
    This script block takes in numerical input via the LeftOperand and RightOperand parameters.
    The Operation parameter determines which mathematical operation to perform on the LeftOperand and RightOperand parameters.
    
    .PARAMETER Operation
    Mandatory - specifies the mathematical operation to perform.
    .PARAMETER LeftOperand
    Mandatory - value on the left side of the mathematical operation.
    .PARAMETER RightOperand
    Mandatory - value on the right side of the mathematical operation.
    
    .EXAMPLE
    SimpleCalc -Operation Add -LeftOperand 2 -RightOperand 2
    SimpleCalc -Operation Divide -LeftOperand 10 -RightOperand 1
    SimpleCalc -Operation Multiply -LeftOperand 5 -RightOperand 3 -Verbose
    SimpleCalc -Operation Subtract -LeftOperand 5 -RightOperand 3 -Verbose
    SimpleCalc -Operation Average -LeftOperand 3 -RightOperand 111 -Verbose
    
    .NOTES
    v0.6.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Pick the math operation")]
        [ValidateSet("Add", "Subtract", "Multiply", "Divide", "Average")]
        [string]$Operation,

        [Parameter(Mandatory = $true, Position = 1, HelpMessage = "Enter the left operand")]
        [int]$LeftOperand,

        [Parameter(Mandatory = $true, Position = 2, HelpMessage = "Enter the right operand")]
        [int]$RightOperand
    )
    BEGIN {
        Write-Verbose -Message $Operation
        ## Here we can now initialize a new calculator object based on our class
        $SimpleCalc = [Calculator]::new($LeftOperand, $RightOperand, $Operation)
    }
    PROCESS {
        switch ($Operation) {
            "Add" {
                $Res = $SimpleCalc.Add()
            }
            "Subtract" {
                $Res = $SimpleCalc.Subtract()
            }
            "Multiply" {
                $Res = $SimpleCalc.Multiply()
            }
            "Divide" {
                $Res = $SimpleCalc.Divide()
            }
            "Average" {
                $Res = $SimpleCalc.Average()
            }
        }
    }
    END {
        Write-Output -InputObject "Result: $Res" 
    }
}