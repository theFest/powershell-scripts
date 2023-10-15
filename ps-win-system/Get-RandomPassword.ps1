#Requires -Version 5.1
Function Get-RandomPassword {
  <#
  .SYNOPSIS
  PowerShell Desktop password generator.

  .DESCRIPTION
  This function generates a strong password that meets certain requirements defined by the parameters.

  .PARAMETER GenerateType
  NotManatory - choose type of generated password, regular or with options.
  .PARAMETER PasswordLength
  Manatory - parameter that specifies the length of the password to be generated.
  .PARAMETER MinUpperCase
  NotManatory - specifies the minimum number of uppercase characters that the password must contain.
  .PARAMETER MinLowerCase
  NotManatory - specifies the minimum number of lowercase characters that the password must contain.
  .PARAMETER MinNumeric
  NotManatory - specifies minimum number of numeric characters that the password must contain.
  .PARAMETER MinSpecialChar
  NotManatory - specifies the minimum number of special characters that the password must contain.
  .PARAMETER CustomCharSet
  NotManatory - specify a custom set of characters to be used when generating the password.
  .PARAMETER Count
  NotManatory - integer to specify the number of passwords to be generated, default is set to one.
  .PARAMETER MaxRepeatedChar
  NotManatory - this parameter specifies the maximum number of times a single character can repeat in the password.
  .PARAMETER ExcludeSimilar
  NotManatory - parameter that, if specified, excludes similar characters from the password.
  .PARAMETER ExcludeConfused
  NotManatory - switch, if specified, excludes easily confused characters from the password.
  .PARAMETER ExcludeAmbiguous
  NotManatory - if specified, excludes ambiguous characters from the password.
  .PARAMETER ExcludeRepeatedChar
  NotManatory - switch, exclude any character that appears in a sequence of more than a certain length.

  .EXAMPLE
  Get-RandomPassword -GenerateType Regular -PasswordLength 8
  Get-RandomPassword -GenerateType Custom -PasswordLength 10 -MinUpperCase 1
  Get-RandomPassword -GenerateType Custom -PasswordLength 12 -MinSpecialChar 2
  Get-RandomPassword -GenerateType Custom -PasswordLength 16 -MaxRepeatedChar 4
  Get-RandomPassword -GenerateType Custom -PasswordLength 18 -MaxRepeatedChar 4 -ExcludeSimilar
  Get-RandomPassword -GenerateType Custom -PasswordLength 20 -MaxRepeatedChar 4 -ExcludeConfused
  Get-RandomPassword -GenerateType Custom -PasswordLength 22 -MaxRepeatedChar 4 -ExcludeAmbiguous

  .NOTES
  v0.0.4
  #>
  [CmdletBinding(SupportsShouldProcess = $true)]
  param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Regular", "Custom")]
    [string]$GenerateType = "Regular",

    [Parameter(Mandatory = $true)]
    [ValidateRange(8, 128)]
    [int]$PasswordLength,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 100)]
    [int]$MinUpperCase = 1,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 100)]
    [int]$MinLowerCase = 1,

    [Parameter(Mandatory = $false)]
    [int]$MinNumeric = 1,

    [Parameter(Mandatory = $false)]
    [int]$MinSpecialChar = 1,

    [Parameter(Mandatory = $false)]
    [ValidateScript({ $_ -ne $null -and $_ -ne '' })]
    [ValidatePattern('^[A-Za-z0-9\p{P}\p{S}\s]+$')]
    [string]$CustomCharSet,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 100)]
    [int]$Count = 1,

    [Parameter(Mandatory = $false)]
    [ValidateRange(2, 128)]
    [int]$MaxRepeatedChar = 2,

    [Parameter()]
    [switch]$ExcludeSimilar,

    [Parameter()]
    [switch]$ExcludeConfused,

    [Parameter()]
    [switch]$ExcludeAmbiguous,

    [Parameter()]
    [switch]$ExcludeRepeatedChar
  )
  BEGIN {
    $ReqEdition = "Desktop"
    if ($ReqEdition -ne $PSVersionTable.PSEdition) {
      throw "This script requires PowerShell $ReqEdition to be able to execute!"
    }
  }
  PROCESS {
    switch ($GenerateType) {
      "Regular" {
        try {
          $RequiredChars = "[A-Z\p{Lu}a-z\p{Ll}\d[^\w\s]]"
          if ($CustomComplexityRule) {
            $RequiredChars = $CustomComplexityRule
          }
          Add-Type -AssemblyName System.Web
          for ($i = 0; $i -lt $Count; $i++) {
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
        $UpperCase = '[A-Z\p{Lu}]' ; $LowerCase = '[a-z\p{Ll}]'
        $Numeric = '[\d]' ; $Special = '[^\w]'
        if ($ExcludeSimilar) {
          $UpperCase = '[A-HJ-NP-Z\p{Lu}]'
          $LowerCase = '[a-hj-np-z\p{Ll}]'
          $Numeric = '[\d\S]' ; $Special = '[^\w\s]'
        }
        if ($ExcludeConfused) {
          $UpperCase = '[A-HJ-NP-Z\p{Lu}]'
          $Numeric = '[\d\S]'
        }
        if ($ExcludeAmbiguous) {
          $Special = '[^\w\s]'
        }
        if ($CustomCharSet) {
          $Custom = "[$CustomCharSet]"
        }
        else {
          $Custom = ''
        }
        while ($(([regex]::Matches($Pass, $UpperCase) `
              | ForEach-Object { $_.Value }).Count -lt $MinUpperCase) `
            -or $(([regex]::Matches($Pass, $LowerCase) `
              | ForEach-Object { $_.Value }).Count -lt $MinLowerCase) `
            -or $(([regex]::Matches($Pass, $Numeric) `
              | ForEach-Object { $_.Value }).Count -lt $MinNumeric) `
            -or $(([regex]::Matches($Pass, $Special) `
              | ForEach-Object { $_.Value }).Count -lt $MinSpecialChar) `
            -or ($CustomCharSet -and $(([regex]::Matches($Pass, $Custom) `
                | ForEach-Object { $_.Value }).Count -lt [math]::Min($PasswordLength, `
                  [int][char[]]$CustomCharSet.Length))) `
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
