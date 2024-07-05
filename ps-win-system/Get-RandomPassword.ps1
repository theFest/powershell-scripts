#requires -Version 5.1
function Get-RandomPassword {
    <#
    .SYNOPSIS
    Generates a random password based on specified criteria.

    .DESCRIPTION
    This function generates random passwords either in a 'Regular' or 'Custom' format, with options to specify length, character types, custom character sets, and exclusion criteria.

    .EXAMPLE
    Get-RandomPassword -GenerateType Regular -PasswordLength 8
    Get-RandomPassword -GenerateType Custom -PasswordLength 10 -MinUpperCase 1
    Get-RandomPassword -GenerateType Custom -PasswordLength 12 -MinSpecialChar 2
    Get-RandomPassword -GenerateType Custom -PasswordLength 16 -MaxRepeatedChar 4
    Get-RandomPassword -GenerateType Custom -PasswordLength 18 -MaxRepeatedChar 4 -ExcludeSimilar
    Get-RandomPassword -GenerateType Custom -PasswordLength 20 -MaxRepeatedChar 4 -ExcludeConfused
    Get-RandomPassword -GenerateType Custom -PasswordLength 22 -MaxRepeatedChar 4 -ExcludeAmbiguous

    .NOTES
    v0.4.0
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Specify whether to generate a 'Regular' or 'Custom' password")]
        [ValidateSet("Regular", "Custom")]
        [Alias("g")]
        [string]$GenerateType = "Regular",
    
        [Parameter(Mandatory = $true, HelpMessage = "Length of the generated password")]
        [ValidateRange(8, 128)]
        [Alias("l")]
        [int]$PasswordLength,
    
        [Parameter(Mandatory = $false, HelpMessage = "Minimum number of uppercase characters")]
        [ValidateRange(1, 100)]
        [Alias("u")]
        [int]$MinUpperCase = 1,
    
        [Parameter(Mandatory = $false, HelpMessage = "Minimum number of lowercase characters")]
        [ValidateRange(1, 100)]
        [Alias("lc")]
        [int]$MinLowerCase = 1,
    
        [Parameter(Mandatory = $false, HelpMessage = "Minimum number of numeric characters")]
        [Alias("nn")]
        [int]$MinNumeric = 1,
    
        [Parameter(Mandatory = $false, HelpMessage = "Minimum number of special characters")]
        [Alias("sc")]
        [int]$MinSpecialChar = 1,
    
        [Parameter(Mandatory = $false, HelpMessage = "Custom character set to use in generating passwords")]
        [ValidateScript({ $_ -ne $null -and $_ -ne '' })]
        [ValidatePattern('^[A-Za-z0-9\p{P}\p{S}\s]+$')]
        [Alias("cs")]
        [string]$CustomCharSet,
    
        [Parameter(Mandatory = $false, HelpMessage = "Number of passwords to generate")]
        [ValidateRange(1, 100)]
        [Alias("ct")]
        [int]$Count = 1,
    
        [Parameter(Mandatory = $false, HelpMessage = "Maximum allowed repeated characters")]
        [ValidateRange(2, 128)]
        [Alias("mx")]
        [int]$MaxRepeatedChar = 2,
    
        [Parameter(Mandatory = $false, HelpMessage = "Exclude characters that look similar")]
        [Alias("es")]
        [switch]$ExcludeSimilar,
    
        [Parameter(Mandatory = $false, HelpMessage = "Exclude visually confused characters")]
        [Alias("ec")]
        [switch]$ExcludeConfused,
    
        [Parameter(Mandatory = $false, HelpMessage = "Exclude ambiguous characters")]
        [Alias("amb")]
        [switch]$ExcludeAmbiguous,
    
        [Parameter(Mandatory = $false, HelpMessage = "Exclude repeated characters altogether")]
        [Alias("rr")]
        [switch]$ExcludeRepeatedChar
    )
    BEGIN {
        $ReqEdition = "Desktop"
        if ($ReqEdition -ne $PSVersionTable.PSEdition) {
            throw "This script requires PowerShell $ReqEdition to be able to execute!"
        }
    }
    PROCESS {
        $Passwords = @()
        switch ($GenerateType) {
            "Regular" {
                try {
                    $RequiredChars = "[A-Z\p{Lu}a-z\p{Ll}\d[^\w\s]]"
                    if ($CustomComplexityRule) {
                        $RequiredChars = $CustomComplexityRule
                    }
                    Add-Type -AssemblyName System.Web
                    for ($i = 0; $i -lt $Count; $i++) {
                        $Pass = ""
                        while (!($Pass -match $RequiredChars) `
                                -or ($Pass -match "(.)\1{$MaxRepeatedChar,}") `
                                -or ($ExcludeRepeatedChar -and $Pass -match "(.)\1")) {
                            $Pass = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, 0)
                        }
                        $Passwords += $Pass
                    }
                }
                catch {
                    Write-Error $_.Exception.Message
                }
            }
            "Custom" {
                Add-Type -AssemblyName System.Web
                $UpperCase = '[A-Z\p{Lu}]'
                $LowerCase = '[a-z\p{Ll}]'
                $Numeric = '[\d]'
                $Special = '[^\w\s]'
                if ($ExcludeSimilar) {
                    $UpperCase = '[A-HJ-NP-Z\p{Lu}]'
                    $LowerCase = '[a-hj-np-z\p{Ll}]'
                    $Numeric = '[\d\S]'
                    $Special = '[^\w\s]'
                }
                if ($ExcludeConfused) {
                    $UpperCase = '[A-HJ-NP-Z\p{Lu}]'
                    $Numeric = '[\d\S]'
                }
                if ($ExcludeAmbiguous) {
                    $Special = '[^\w\s]'
                }
                while (
                    ([regex]::Matches($Pass, $UpperCase) | ForEach-Object { $_.Value }).Count -lt $MinUpperCase `
                        -or ([regex]::Matches($Pass, $LowerCase) | ForEach-Object { $_.Value }).Count -lt $MinLowerCase `
                        -or ([regex]::Matches($Pass, $Numeric) | ForEach-Object { $_.Value }).Count -lt $MinNumeric `
                        -or ([regex]::Matches($Pass, $Special) | ForEach-Object { $_.Value }).Count -lt $MinSpecialChar `
                        -or ($CustomCharSet -and ([regex]::Matches($Pass, "[$CustomCharSet]") | ForEach-Object { $_.Value }).Count -lt [math]::Min($PasswordLength, [int][char[]]$CustomCharSet.Length)) `
                        -or ($Pass -match "(.)\1{$MaxRepeatedChar,}")
                ) {
                    $Pass = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, 0)
                }
            }
        }
    }
    END {
        return $Pass
        Remove-Variable -Name Pass, Passwords -ErrorAction SilentlyContinue
        Clear-Variable -Name Pass, Passwords -Force -Verbose -ErrorAction SilentlyContinue
        Clear-History -Verbose
    }
}
