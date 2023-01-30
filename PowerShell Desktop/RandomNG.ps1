Class rnDnmbr {
    [int]$Min
    [int]$Max
    [int]$Count
    [switch]$Encryption
    [switch]$Encoding
}
Function RandomNG {
    <#
    .SYNOPSIS
    Simple class-based random number generator.
    
    .DESCRIPTION
    The function generates random numbers between a given minimum and maximum value, and returns the specified number of random numbers.

    .PARAMETER Min
    Mandatory - Minimum value for the random numbers.
    .PARAMETER Max
    Mandatory - Maximum value for the random numbers.
    .PARAMETER Count
    Mandatory - Number of random numbers to generate.
    .PARAMETER Encryption
    NotMandatory - Will encrypt the numbers using the ConvertTo-SecureString cmdlet, which encrypts the input as plain text.
    .PARAMETER Encoding
    NotMandatory - Enable or Disable encoding for the random numbers
    
    .EXAMPLE
    RandomNG -Min 1 -Max 10 -Count 5
    RandomNG -Min 1 -Max 10 -Count 5 -Encryption
    RandomNG -Min 1 -Max 10 -Count 5 -Encryption -Encoding
    
    .NOTES
    v1
    #>
    [CmdletBinding(DefaultParameterSetName = 'randomNG', SupportsShouldProcess = $true)]
    param(
        [Parameter(ParameterSetName = 'randomNG', Mandatory = $true, Position = 0)]
        [int]$Min,

        [Parameter(ParameterSetName = 'randomNG', Mandatory = $true, Position = 0)]
        [int]$Max,

        [Parameter(ParameterSetName = 'randomNG', Mandatory = $true, Position = 1)]
        [ValidateRange(1, 1000)]
        [int]$Count,

        [Parameter(ParameterSetName = 'randomNG', Mandatory = $false, Position = 2)]
        [switch]$Encryption,

        [Parameter(ParameterSetName = 'randomNG', Mandatory = $false, Position = 3)]
        [switch]$Encoding
    )
    BEGIN {
        $rnD = New-Object System.Random
    }
    PROCESS {
        if ($PSCmdlet.ShouldProcess("Generating random numbers")) {
            $Out = @()
            for ($i = 1; $i -le $Count; $i++) {
                $rnDnmbr = $rnD.Next($Min, $Max)
                if ($Encryption) {
                    $rnDnmbr = ConvertTo-SecureString -String $rnDnmbr -AsPlainText -Force
                }
                if ($Encoding) {
                    $rnDnmbr = [System.Text.Encoding]::UTF8.GetBytes($rnDnmbr)
                }
                $Out += $rnDnmbr
            }
            return $Out
        }
    }
    END {
        Clear-Variable -Name rnD, rnDnmbr, Out -Force -Verbose 
    }
}