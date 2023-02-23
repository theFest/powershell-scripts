Class Calculator {
    [int]$LeftOperand
    [int]$RightOperand
    Calculator(
        [int]$LeftOperand,
        [int]$RightOperand) {
        $this.LeftOperand = $LeftOperand
        $this.RightOperand = $RightOperand
    }
    [int] Add() {
        return $this.LeftOperand + $this.RightOperand
    }
    [int] Subtract() {
        return $this.LeftOperand - $this.RightOperand
    }
    [int] Multiply() {
        return $this.LeftOperand * $this.RightOperand
    }
    [int] Divide() {
        if ($this.RightOperand -eq 0) {
            throw "You can't divide by zero!"
        }
        return $this.LeftOperand / $this.RightOperand
    }
}
  
Function SimpleCalc {
    <#
    .SYNOPSIS
    Simple calculator.
    
    .DESCRIPTION
    This basic function that uses class.
    
    .PARAMETER Operation
    Mandatory - description
    .PARAMETER LeftOperand
    Mandatory - description
    .PARAMETER RightOperand
    Mandatory - description
    
    .EXAMPLE
    SimpleCalc -Operation Add -LeftOperand 2 -RightOperand 2
    SimpleCalc -Operation Divide -LeftOperand 10 -RightOperand 1
    SimpleCalc -Operation Multiply -LeftOperand 5 -RightOperand 3 -Verbose
    SimpleCalc -Operation Subtract -LeftOperand 5 -RightOperand 3 -Verbose
    
    .NOTES
    v0.5
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Add", "Subtract", "Multiply", "Divide")]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        [int]$LeftOperand,

        [Parameter(Mandatory = $true)]
        [int]$RightOperand
    )
    BEGIN {
        $SimpleCalc = [Calculator]::new($LeftOperand, $RightOperand)
    }
    PROCESS {
        switch ($Operation) {
            "Add" {
                $Res = $SimpleCalc.Add()
            }
            "Divide" {
                $Res = $SimpleCalc.Divide()
            }
            "Multiply" {
                $Res = $SimpleCalc.Multiply()
            }
            "Subtract" {
                $Res = $SimpleCalc.Subtract()
            }
        }
    }
    END {
        Write-Verbose -Message "Result: $Res"
    }
}