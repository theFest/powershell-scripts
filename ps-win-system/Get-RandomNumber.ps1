#Requires -Version 5.1
Function Get-RandomNumber {
    <#
    .SYNOPSIS
    Generates random numbers=+chars within a specified range and with optional seeding, encoding, sorting, uniqueness, and exporting capabilities.
    
    .DESCRIPTION
    This function generates a specified number of random numbers within a given range, with various optional features for encoding, sorting, uniqueness, and exporting the results.
    Itses the `System.Random` class for generating random numbers, and allows for the encoding of the numbers in multiple format. Additionally, the function provides options for sorting the results in ascending or descending order and removing duplicate values.
    Option to overwrite an existing file or prevent overwriting with the `-NoClobber` parameter. Error handling and various validations are also incorporated into the function to ensure accurate and reliable results.
    
    .PARAMETER Min
    Mandatory - specifies the minimum value for the range of random numbers to be generated.
    .PARAMETER Max
    Mandatory - specifies the maximum value for the range of random numbers to be generated.
    .PARAMETER Count
    NotMandatory - specifies the number of random numbers to be generated, choose a minimum value of 1 or a maximum value of 1000000.
    .PARAMETER NumberType
    NotMandatory - used to specify the type of random number generator that should be used to generate the numbers. It accepts two possible values: "Random" and "PseudoRandom".
    .PARAMETER Seed
    NotMandatory - value is used to initialize the generator and can be used to generate a predictable sequence of numbers. If a seed value is specified, the generator will use it to generate a repeatable sequence of numbers, if not, it will use a random seed value.
    .PARAMETER Encoding
    NotMandatory - specifies whether the generated numbers should be encoded or not, if the parameter is included, the generated numbers are encoded.
    .PARAMETER EncodingFormat
    NotMandatory - if you choose Encoding switch, this then specifies the format in which the generated numbers should be encoded, choose depending on your needs.
    .PARAMETER Sort
    NotMandatory - specifies whether the generated numbers should be sorted or not.
    .PARAMETER Unique
    NotMandatory - this specifies whether the generated numbers should be unique or not.
    .PARAMETER Export
    NotMandatory - export the result of generated number to a CSV file.
    .PARAMETER NoClobber
    NotMandatory - switch parameter that prevents the script from overwriting an existing file when exporting the random numbers.
    
    .EXAMPLE
    Get-RandomNumber -Min 1 -Max 10 -Count 5
    Get-RandomNumber -Min 1 -Max 50 -Count 10 -Sort
    Get-RandomNumber -Min 1 -Max 100 -Seed 1 -NumberType PseudoRandom
    Get-RandomNumber -Min 1 -Max 1000 -Count 15 -Unique -Export "$env:USERPROFILE\Desktop\RandomNumbers.csv"
    Get-RandomNumber -Min 1 -Max 10000 -Count 20 -Export "$env:USERPROFILE\Desktop\RandomNumbers.csv" -NoClobber
    Get-RandomNumber -Min 1 -Max 100000 -Count 25 -NumberType Random -Encoding -EncodingFormat "Hexadecimal" -Seed 12345
    
    .NOTES
    0.1.3
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Min,
        
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 1000000000)]
        [int]$Max,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000000)]
        [int]$Count = 1,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Random", "PseudoRandom")]
        [string]$NumberType = "Random",
      
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 1000000000)]
        [int]$Seed,

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
        Write-Verbose -Message "Preparing..."
        if ($Min -ge $Max) {
            throw [System.Exception] "Min value must be less than Max value."
        }
        switch ($NumberType) {
            "Random" {
                $RnD = New-Object System.Random
            }
            "PseudoRandom" {
                $RnD = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
            }
        }
    }
    PROCESS {
        Write-Verbose -Message "Generating chars/numbers..."
        try {
            $Output = @()
            for ($i = 1; $i -le $Count; $i++) {
                if ($NumberType -eq "Random") {
                    $RndNmbr = $RnD.Next($Min, $Max)
                }
                elseif ($NumberType -eq "PseudoRandom") {
                    if ($Seed -ne 0) {
                        [array]$SeedBytes = [BitConverter]::GetBytes($Seed)
                        $RnD.GetBytes($SeedBytes)
                    }
                    $RndBytes = New-Object Byte[] 4
                    $RnD.GetBytes($RndBytes)
                    $RndNmbr = [BitConverter]::ToInt32($RndBytes, 0) % ($Max - $Min + 1) + $Min
                }
                $Output += $RndNmbr
            }
            if ($Encoding) {
                switch ($EncodingFormat) {
                    "Binary" {
                        Write-Verbose -Message "Generating 'Binary' encoded format..."
                        $Output = $Output | ForEach-Object { [Convert]::ToString($_, 2) }
                    }
                    "Base64" {
                        Write-Verbose -Message "Generating 'Base64' encoded format..."
                        $Output = $Output | ForEach-Object { [Convert]::ToBase64String([BitConverter]::GetBytes($_)) }
                    }
                    "Hexadecimal" {
                        Write-Verbose -Message "Generating 'Hexadecimal' encoded format..."
                        $Output = $Output | ForEach-Object { "{0:X}" -f $_ }
                    }
                    "ASCII" {
                        Write-Verbose -Message "Generating 'ASCII' encoded format..."
                        $Output = $Output | ForEach-Object { [char][byte]$_ }
                    }
                    "Unicode" {
                        Write-Verbose -Message "Generating 'Unicode' encoded format..."
                        $Output = $Output | ForEach-Object { [char][ushort]$_ }
                    }
                    "UTF-7" {
                        Write-Verbose -Message "Generating 'UTF-7' encoded format..."
                        $Output = $Output | ForEach-Object { [Text.Encoding]::UTF7.GetString([BitConverter]::GetBytes($_)) }
                    }
                    "UTF-32" {
                        Write-Verbose -Message "Generating 'UTF-32' encoded format..."
                        $Output = $Output | ForEach-Object { [Text.Encoding]::UTF32.GetString([BitConverter]::GetBytes($_)) }
                    }
                }
            }
            if ($Sort) {
                $Output = $Output | Sort-Object
            }
            if ($Unique) {
                $Output = $Output | Select-Object -Unique
            }
            if ($Export) {
                if ($NoClobber) {
                    if (Test-Path $Export) {
                        throw "The specified file path '$Export' already exists. Use the NoClobber parameter to overwrite the file."
                    }
                }
                $Output | Set-Content -Path $Export -Force
            }
            else {
                $Output
            }
        }
        catch [System.Exception] {
            Write-Error $_.Exception.Message
        }
    }
    END {
        Write-Verbose -Message "Finished, cleaning up and exiting..."
        Clear-Variable -Name RnD, RndNmbr, Output -Force -Verbose
    }
}
