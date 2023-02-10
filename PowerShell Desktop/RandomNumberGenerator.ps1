Function RandomNumberGenerator {
    <#
    .SYNOPSIS
    Generates random numbers within a specified range and with optional encryption, encoding, sorting, uniqueness, and exporting capabilities.
    
    .DESCRIPTION
    This function generates a specified number of random numbers within a given range, with various optional features for encryption, encoding, sorting, uniqueness, and exporting the results.
    Itses the `System.Random` class for generating random numbers, and allows for the encoding of the numbers in either binary, base64, or hexadecimal format.
    Additionally, the function provides options for sorting the results in ascending or descending order and removing duplicate values. The output can also be exported to a file with the option to overwrite an existing file or prevent overwriting with the `-NoClobber` parameter.
    Error handling and various validations are also incorporated into the function to ensure accurate and reliable results.
    
    .PARAMETER Min
    Mandatory - specifies the minimum value for the range of random numbers to be generated.
    .PARAMETER Max
    Mandatory - specifies the maximum value for the range of random numbers to be generated.
    .PARAMETER Count
    Mandatory - specifies the number of random numbers to be generated, choose a minimum value of 1 or a maximum value of 1000.
    .PARAMETER Encryption
    NotMandatory - specifies whether the generated numbers should be encrypted or not, if the parameter is included, the generated numbers are encrypted.
    .PARAMETER Encoding
    NotMandatory - specifies whether the generated numbers should be encoded or not, if the parameter is included, the generated numbers are encoded.
    .PARAMETER EncodingFormat
    NotMandatory - specifies the format in which the generated numbers should be encoded.
    .PARAMETER Sort
    NotMandatory - specifies whether the generated numbers should be sorted or not.
    .PARAMETER Unique
    NotMandatory - specifies whether the generated numbers should be unique or not.
    .PARAMETER Export
    NotMandatory - export the result of generated number to a CSV file.
    .PARAMETER NoClobber
    NotMandatory - switch parameter that prevents the script from overwriting an existing file when exporting the random numbers.
    
    .EXAMPLE
    ## Generate 5 random numbers between 1 and 10:
    RandomNumberGenerator -Min 1 -Max 10 -Count 1
    ## Generate 5 random numbers between 1 and 10, encrypt them, and sort them:
    RandomNumberGenerator -Min 1 -Max 10 -Count 5 -Encryption -Sort
    ## Generate 5 unique random numbers between 1 and 10 and export the result to a CSV file:
    RandomNumberGenerator -Min 1 -Max 10 -Count 5 -Unique -Export "$env:USERPROFILE\Desktop\RandomNumbers.csv"
    ## Generate 5 random numbers between 1 and 10, encode them in Base64 format and export the result to a CSV file:
    RandomNumberGenerator -Min 1 -Max 10 -Count 5 -Encoding -EncodingFormat "Base64" -Export "$env:USERPROFILE\Desktop\RandomNumbers.csv"
    
    .NOTES
    1.1.0
    #>
    [CmdletBinding(DefaultParameterSetName = "RandomNumberGenerator", SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Min,
        
        [Parameter(Mandatory = $true)]
        [int]$Max,
        
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 1000)]
        [int]$Count,
        
        [Parameter(Mandatory = $false)]
        [switch]$Encryption,
        
        [Parameter(Mandatory = $false)]
        [switch]$Encoding,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Binary", "Base64", "Hexadecimal")]
        [string]$EncodingFormat = "Binary",
        
        [Parameter(Mandatory = $false)]
        [switch]$Sort,
        
        [Parameter(Mandatory = $false)]
        [switch]$Unique,
        
        [Parameter(Mandatory = $false)]
        [ValidateScript({ Test-Path $_ -PathType 'Leaf' })]
        [string]$Export,

        [Parameter(Mandatory = $false)]
        [switch]$NoClobber
    )
    BEGIN {
        Write-Verbose -Message "Preparing and doing prechecks..."
        if ($Min -ge $Max) {
            throw [System.Exception] "Min value must be less than Max value."
        }
        $rnD = New-Object System.Random
    }
    PROCESS {
        Write-Verbose -Message "Generating random number's..."
        try {
            $Output = @()
            for ($i = 1; $i -le $Count; $i++) {
                $rnDnmbr = $rnD.Next($Min, $Max)
                if ($Encryption) {
                    $rnDnmbr = ConvertTo-SecureString -String $rnDnmbr -AsPlainText -Force
                }
                if ($Encoding) {
                    switch ($EncodingFormat) {
                        "Binary" {
                            $rnDnmbr = [System.Text.Encoding]::UTF8.GetBytes($rnDnmbr)
                        }
                        "Base64" {
                            $rnDnmbr = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($rnDnmbr))
                        }
                        "Hexadecimal" {
                            $rnDnmbr = [System.BitConverter]::ToString([System.Text.Encoding]::UTF8.GetBytes($rnDnmbr)) -replace '-'
                        }
                    }
                }
                $Output += $rnDnmbr
            }
            if ($Unique) {
                $Output = $Output | Select-Object -Unique
            }
            if ($Sort) {
                $Output = $Output | Sort-Object
            }
            if ($Export) {
                if ($NoClobber -and (Test-Path -Path $Export)) {
                    throw [System.Exception] "File already exists. Use -NoClobber to force overwrite."
                }
                else {
                    $Output | Out-File -FilePath $Export -Encoding UTF8
                }
            }
            $Output
        }
        catch {
            Write-Error -Message $_
        }
    }
    END {
        Write-Verbose -Message "Finished, cleaning up and exiting..."
        Clear-Variable -Name rnD, rnDnmbr, Output -Force -Verbose
        exit
    }
}