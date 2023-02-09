Function RandomNumberGenerator {
    <#
    .SYNOPSIS
    Simple PowerShell random number generator.
    
    .DESCRIPTION
    The function generates random numbers between a given minimum and maximum value, and returns the specified number of random numbers.
    
    .PARAMETER Min
    Mandatory - specifies the minimum value for the range of random numbers to be generated. It is a mandatory parameter with a position of 0.
    .PARAMETER Max
    Mandatory - specifies the maximum value for the range of random numbers to be generated. It is a mandatory parameter with a position of 1.
    .PARAMETER Count
    Mandatory - specifies the number of random numbers to be generated, it is parameter with a position of 2, the parameter also has a validation range, with a minimum value of 1 and a maximum value of 1000.
    .PARAMETER Encryption
    NotMandatory - specifies whether the generated numbers should be encrypted or not. It is an optional parameter with a position of 3, if the parameter is included, the generated numbers are encrypted.
    .PARAMETER Encoding
    NotMandatory - specifies whether the generated numbers should be encoded or not. It is an optional parameter with a position of 4, if the parameter is included, the generated numbers are encoded.
    .PARAMETER EncodingFormat
    NotMandatory - specifies the format in which the generated numbers should be encoded. It is an optional parameter with a position of 4.
    .PARAMETER Sort
    NotMandatory - specifies whether the generated numbers should be sorted or not. It is an optional parameter with a position of 5.
    .PARAMETER Unique
    NotMandatory - specifies whether the generated numbers should be unique or not. It is an optional parameter with a position of 6.
    
    .EXAMPLE
    RandomNumberGenerator -Min 1 -Max 10 -Count 5
    RandomNumberGenerator -Min 1 -Max 10 -Count 5 -Encryption
    RandomNumberGenerator -Min 1 -Max 10 -Count 5 -Encryption -Encoding
    RandomNumberGenerator -Min 10 -Max 100 -Count 1 -EncodingFormat Base64
    
    .NOTES
    v1.0.3
    #>
    [CmdletBinding(DefaultParameterSetName = "RandomNumberGenerator", SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "RandomNumberGenerator")]
        [int]$Min,

        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "RandomNumberGenerator")]
        [int]$Max,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = "RandomNumberGenerator")]
        [ValidateRange(1, 1000)]
        [int]$Count,

        [Parameter(Mandatory = $false, Position = 2, ParameterSetName = "RandomNumberGenerator")]
        [switch]$Encryption,

        [Parameter(Mandatory = $false, Position = 3, ParameterSetName = "RandomNumberGenerator")]
        [switch]$Encoding,

        [Parameter(Mandatory = $false, Position = 4, ParameterSetName = "RandomNumberGenerator")]
        [ValidateSet("Binary", "Base64", "Hexadecimal")]
        [string]$EncodingFormat = "Binary",

        [Parameter(Mandatory = $false, Position = 5, ParameterSetName = "RandomNumberGenerator")]
        [switch]$Sort,

        [Parameter(Mandatory = $false, Position = 6, ParameterSetName = "RandomNumberGenerator")]
        [switch]$Unique
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
                    switch ($EncodingFormat) {
                        "Binary" {
                            $rnDnmbr = [System.Convert]::ToString($rnDnmbr, 2)
                        }
                        "Base64" {
                            $rnDnmbr = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($rnDnmbr))
                        }
                        "Hexadecimal" {
                            $rnDnmbr = [System.Convert]::ToString($rnDnmbr, 16)
                        }
                    }
                }
                $Out += $rnDnmbr
            }
            if ($Unique) {
                $Out = [System.Collections.ArrayList]::new($Out)
                $Out = [System.Linq.Enumerable]::Distinct($Out)
                $Out = [System.Collections.ArrayList]::new($Out)
            }
            if ($Sort) {
                [Array]::Sort($Out)
            }
            return $Out
        }
    }
    END {
        Clear-Variable -Name rnD, rnDnmbr, Out -Force -Verbose 
    }
}