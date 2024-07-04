#requires -Version 5.1
function Get-RandomNumber {
    <#
    .SYNOPSIS
    Generates random numbers within specified parameters and optionally exports them to a file.

    .DESCRIPTION
    This function generates random numbers based on specified parameters such as minimum and maximum values, type of random generation (pseudo or true random), count of numbers, encoding options, sorting, uniqueness, and exporting to file capabilities.

    .EXAMPLE
    Get-RandomNumber -Min 1 -Max 10
    Get-RandomNumber -Min 1 -Max 50 -Count 2 -Sort
    Get-RandomNumber -Min 1 -Max 100 -Seed 1 -NumberType PseudoRandom
    Get-RandomNumber -Min 1 -Max 1000 -Unique -Export "$env:USERPROFILE\Desktop\RandomNumbers.csv"
    Get-RandomNumber -Min 1 -Max 10000 -Count 20 -Export "$env:USERPROFILE\Desktop\RandomNumbers.csv" -NoClobber
    Get-RandomNumber -Min 1 -Max 100000 -Count 25 -NumberType Random -Encoding -EncodingFormat "Hexadecimal" -Seed 12345

    .NOTES
    v0.3.8
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true, HelpMessage = "Minimum value for generating random numbers")]
        [Alias("n")]
        [int]$Min,
        
        [Parameter(Mandatory = $true, HelpMessage = "Maximum value (inclusive) for generating random numbers")]
        [ValidateRange(1, 1000000000)]
        [Alias("x")]
        [int]$Max,
        
        [Parameter(Mandatory = $false, HelpMessage = "Number of random numbers to generate")]
        [ValidateRange(1, 1000000)]
        [Alias("c")]
        [int]$Count = 1,
        
        [Parameter(Mandatory = $false, HelpMessage = "Type of random number generation: 'Random' or 'PseudoRandom'")]
        [ValidateSet("Random", "PseudoRandom")]
        [Alias("t")]
        [string]$NumberType = "Random",
      
        [Parameter(Mandatory = $false, HelpMessage = "Seed value for generating pseudo-random numbers")]
        [ValidateRange(1, 1000000000)]
        [Alias("s")]
        [int]$Seed,

        [Parameter(Mandatory = $false, HelpMessage = "Enable encoding of generated numbers")]
        [Alias("en")]
        [switch]$Encoding,
        
        [Parameter(Mandatory = $false, HelpMessage = "Encoding format for the output (default is Binary)")]
        [ValidateSet("Binary", "Base64", "Hexadecimal", "ASCII", "Unicode", "UTF-7", "UTF-32")]
        [Alias("f")]
        [string]$EncodingFormat = "Binary",
        
        [Parameter(Mandatory = $false, HelpMessage = "Sort the generated numbers")]
        [Alias("st")]
        [switch]$Sort,
        
        [Parameter(Mandatory = $false, HelpMessage = "Ensure generated numbers are unique")]
        [Alias("uq")]
        [switch]$Unique,
        
        [Parameter(Mandatory = $false, HelpMessage = "Path to export the generated numbers")]
        [ValidateScript({
                if ($null -ne $_) {
                    if (!(Test-Path (Split-Path $_ -Parent))) {
                        throw "The specified directory '$($_ | Split-Path -Parent)' does not exist!"
                    }
                }
                return $true
            })]
        [Alias("e")]
        [string]$Export,

        [Parameter(Mandatory = $false, HelpMessage = "Prevent overwriting an existing file")]
        [Alias("nc")]
        [switch]$NoClobber
    )
    BEGIN {
        if ($Min -ge $Max) {
            throw [System.Exception] "Min value must be less than Max value."
        }
        switch ($NumberType) {
            "Random" {
                $RnD = if ($PSBoundParameters.ContainsKey('Seed')) {
                    New-Object System.Random($Seed)
                }
                else {
                    New-Object System.Random
                }
            }
            "PseudoRandom" {
                $RnD = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
            }
        }
    }
    PROCESS {
        try {
            $Output = @()
            for ($i = 1; $i -le $Count; $i++) {
                if ($NumberType -eq "Random") {
                    $RndNmbr = $RnD.Next($Min, $Max)
                }
                elseif ($NumberType -eq "PseudoRandom") {
                    $RndBytes = New-Object Byte[] 4
                    $RnD.GetBytes($RndBytes)
                    $RndNmbr = [Math]::Abs([BitConverter]::ToInt32($RndBytes, 0)) % ($Max - $Min + 1) + $Min
                }
                $Output += $RndNmbr
            }
            if ($Encoding) {
                Write-Verbose -Message "Encoding numbers to $EncodingFormat format..."
                $Output = switch ($EncodingFormat) {
                    "Binary" { $Output | ForEach-Object { [Convert]::ToString($_, 2) } }
                    "Base64" { $Output | ForEach-Object { [Convert]::ToBase64String([BitConverter]::GetBytes($_)) } }
                    "Hexadecimal" { $Output | ForEach-Object { "{0:X}" -f $_ } }
                    "ASCII" { $Output | ForEach-Object { [char][byte]$_ } }
                    "Unicode" { $Output | ForEach-Object { [char][ushort]$_ } }
                    "UTF-7" { $Output | ForEach-Object { [Text.Encoding]::UTF7.GetString([BitConverter]::GetBytes($_)) } }
                    "UTF-32" { $Output | ForEach-Object { [Text.Encoding]::UTF32.GetString([BitConverter]::GetBytes($_)) } }
                }
            }
            if ($Sort) {
                $Output = $Output | Sort-Object
            }
            if ($Unique) {
                $Output = $Output | Select-Object -Unique
            }
            if ($Export) {
                Write-Verbose -Message "Exporting to file: $Export"
                $ExportPath = $Export
                if (!(Test-Path $ExportPath)) {
                    $null = New-Item -Path $ExportPath -ItemType File -Force
                }
                elseif ($NoClobber) {
                    throw "The specified file path '$ExportPath' already exists. Use the NoClobber parameter to prevent overwriting the file."
                }
                $Output | Set-Content -Path $ExportPath -Force -Verbose
            }
            else {
                $Output
            }
        }
        catch [System.Exception] {
            Write-Error -Message $_.Exception.Message
        }
    }
    END {
        Remove-Variable -Name RnD, RndNmbr, Output -ErrorAction SilentlyContinue
    }
}
