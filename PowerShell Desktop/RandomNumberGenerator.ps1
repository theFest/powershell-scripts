Function RandomNumberGenerator {
    <#
    .SYNOPSIS
    Generates random numbers within a specified range and with optional encoding, sorting, uniqueness, and exporting capabilities.
    
    .DESCRIPTION
    This function generates a specified number of random numbers within a given range, with various optional features for encoding, sorting, uniqueness, and exporting the results.
    Itses the `System.Random` class for generating random numbers, and allows for the encoding of the numbers in multiple format. Additionally, the function provides options for sorting the results in ascending or descending order and removing duplicate values.
    Option to overwrite an existing file or prevent overwriting with the `-NoClobber` parameter. Error handling and various validations are also incorporated into the function to ensure accurate and reliable results.
    
    .PARAMETER Min
    Mandatory - specifies the minimum value for the range of random numbers to be generated.
    .PARAMETER Max
    Mandatory - specifies the maximum value for the range of random numbers to be generated.
    .PARAMETER Count
    Mandatory - specifies the number of random numbers to be generated, choose a minimum value of 1 or a maximum value of 1000.
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
    RandomNumberGenerator -Min 2 -Max 10 -Count 2 -EncodingFormat UTF-32
    ## Generate 5 unique random numbers between 1 and 10 and export the result to a CSV file:
    RandomNumberGenerator -Min 1 -Max 10 -Count 5 -Unique -Export "$env:USERPROFILE\Desktop\RandomNumbers.csv"
    ## Generate 5 random numbers between 1 and 10, encode them in Base64 format and export the result to a CSV file:
    RandomNumberGenerator -Min 1 -Max 10 -Count 5 -Encoding -EncodingFormat ASCII -Export "$env:USERPROFILE\Desktop\RandomNumbers.csv"
    
    .NOTES
    1.1.2
    #>
    [CmdletBinding(DefaultParameterSetName = "RandomNumberGenerator", SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Min,
        
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 1000000000)]
        [int]$Max,
        
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 10000)]
        [int]$Count,
        
        [Parameter(Mandatory = $false)]
        [switch]$Encoding,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Binary", "Base64", "Hexadecimal", "ASCII", "Unicode", "UTF-7", "UTF-32")]
        [string]$EncodingFormat = "Binary",
        
        [Parameter(Mandatory = $false)]
        [switch]$Sort,
        
        [Parameter(Mandatory = $false)]
        [switch]$Unique,
        
        [Parameter(Mandatory = $false)]
        [ValidateScript({
                if ($null -ne $Export) {
                    if (!(Test-Path $Export -PathType "Leaf")) {
                        throw "The specified file path '$Export' does not exist."
                    }
                }
                return $true
            })]
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
                if ($Encoding) {
                    switch ($EncodingFormat) {
                        "Binary" {
                            Write-Verbose -Message "Generating Binary encoded numbers..."
                            $rnDnmbr = [System.Text.Encoding]::UTF8.GetBytes($rnDnmbr)
                        }
                        "Base64" {
                            Write-Verbose -Message "Generating Base64 encoded numbers..."
                            $rnDnmbr = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($rnDnmbr))
                        }
                        "Hexadecimal" {
                            Write-Verbose -Message "Generating Hexadecimal encoded numbers..."
                            $rnDnmbr = [System.BitConverter]::ToString([System.Text.Encoding]::UTF8.GetBytes($rnDnmbr)) -replace '-'
                        }
                        "ASCII" {
                            Write-Verbose -Message "Generating ASCII encoded numbers..."
                            $rnDnmbr = [System.Text.Encoding]::ASCII.GetBytes($rnDnmbr)
                        }
                        "Unicode" {
                            Write-Verbose -Message "Generating Unicode encoded numbers..."
                            $rnDnmbr = [System.Text.Encoding]::Unicode.GetBytes($rnDnmbr)
                        }
                        "UTF-7" {
                            Write-Verbose -Message "Generating UTF-7 encoded numbers..."
                            $rnDnmbr = [System.Text.Encoding]::UTF7.GetBytes($rnDnmbr)
                        }
                        "UTF-32" {
                            Write-Verbose -Message "Generating UTF-32 encoded numbers..."
                            $rnDnmbr = [System.Text.Encoding]::UTF32.GetBytes($rnDnmbr)
                        }
                    }
                }
                $Out = $Output += $rnDnmbr
            }
            if ($Unique) {
                $Output = $Output | Select-Object -Unique
            }
            if ($Sort) {
                $Output = $Output | Sort-Object
            }
            if ($Export) {
                $File = Get-Item $Export -ErrorAction SilentlyContinue
                if ($File.Attributes -band [System.IO.FileAttributes]::Directory) {
                    throw [System.Exception] "Cannot export to a directory. Please specify a file path."
                }
                if ($File.Exists -and !$NoClobber) {
                    $Confirm = Read-Host "File already exists, do you want to overwrite it? [y/n]"
                    if ($Confirm -ne "y") {
                        throw [System.Exception] "Exporting cancelled."
                    }
                }
                $Out | Out-File -FilePath $Export -Verbose
            }
            $Output
        }
        catch [System.Exception] {
            Write-Error $_.Exception.Message
        }
    }
    END {
        Write-Verbose -Message "Finished, cleaning up and exiting..."
        Clear-Variable -Name rnD, rnDnmbr, Out, Output -Force -Verbose
        exit
    }
}