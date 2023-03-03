#requires -version 5.1
Function RandomPasswordGenerator {
  <#
  .SYNOPSIS
  PowerShell Desktop password generator.

  .DESCRIPTION
  This function generates a strong password that meets certain requirements defined by the parameters.

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
  .PARAMETER ExcludeSimilar
  NotManatory - switch parameter that, if specified, excludes similar characters from the password.
  .PARAMETER ExcludeConfused
  NotManatory - switch parameter that, if specified, excludes easily confused characters from the password.
  .PARAMETER ExcludeAmbiguous
  NotManatory - if specified, excludes ambiguous characters from the password.
  .PARAMETER CustomCharSet
  NotManatory - specify a custom set of characters to be used when generating the password. If this parameter is not specified, all characters are eligible.
  .PARAMETER MaxRepeatedChar
  NotManatory - this parameter specifies the maximum number of times a single character can repeat in the password. The default value is 2.

  .EXAMPLE
  RandomPasswordGenerator -PasswordLength 8
  RandomPasswordGenerator -PasswordLength 10 -MinUpperCase 1
  RandomPasswordGenerator -PasswordLength 12 -MinSpecialChar 2
  RandomPasswordGenerator -PasswordLength 14 -MaxRepeatedChar 4

  .NOTES
  v1.0.1
  #>
  param (
    [Parameter(Mandatory = $true)]
    [int]$PasswordLength,

    [Parameter(Mandatory = $false)]
    [int]$MinUpperCase = 1,

    [Parameter(Mandatory = $false)]
    [int]$MinLowerCase = 1,

    [Parameter(Mandatory = $false)]
    [int]$MinNumeric = 1,

    [Parameter(Mandatory = $false)]
    [int]$MinSpecialChar = 1,

    [Parameter(Mandatory = $false)]
    [switch]$ExcludeSimilar,

    [Parameter(Mandatory = $false)]
    [switch]$ExcludeConfused,

    [Parameter(Mandatory = $false)]
    [switch]$ExcludeAmbiguous,

    [Parameter(Mandatory = $false)]
    [string]$CustomCharSet,

    [int]$MaxRepeatedChar = 2
  )
  ## Character sets to be used
  $UpperCase = '[A-Z\p{Lu}]' ; $LowerCase = '[a-z\p{Ll}]'
  $Numeric = '[\d]' ; $Special = '[^\w]'
  ## Exclude similar characters
  if ($ExcludeSimilar) {
    $UpperCase = '[A-HJ-NP-Z\p{Lu}]'
    $lowerCase = '[a-hj-np-z\p{Ll}]'
    $Numeric = '[\d\S]'
    $Special = '[^\w\s]'
  }
  ## Exclude easily confused characters
  if ($ExcludeConfused) {
    $UpperCase = '[A-HJ-NP-Z\p{Lu}]'
    $Numeric = '[\d\S]'
  }
  ## Exclude ambiguous characters
  if ($ExcludeAmbiguous) {
    $Special = '[^\w\s]'
  }
  ## Include custom character set
  if ($CustomCharSet) {
    $Custom = "[$CustomCharSet]"
  }
  else {
    $Custom = ''
  }
  $ReqEdition = 'Desktop'
  if ($ReqEdition -gt $PSVersionTable.PSEdition) {
    throw "This script requires PowerShell $ReqEdition to be able to execute!"
  }
  Add-Type -AssemblyName System.Web
  #$Pass = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, 0)
  ## Check if the password meets the requirements
  while ($(([regex]::Matches($Pass, $upperCase) `
        | ForEach-Object { $_.Value }).Count -lt $MinUpperCase) -or `
    $(([regex]::Matches($Pass, $lowerCase) `
        | ForEach-Object { $_.Value }).Count -lt $MinLowerCase) -or `
    $(([regex]::Matches($Pass, $numeric) `
        | ForEach-Object { $_.Value }).Count -lt $MinNumeric) -or `
    $(([regex]::Matches($Pass, $special) `
        | ForEach-Object { $_.Value }).Count -lt $MinSpecialChar) -or `
    ($CustomCharSet -and $(([regex]::Matches($Pass, $Custom) `
        | ForEach-Object { $_.Value }).Count -lt [math]::Min($PasswordLength, `
            [int][char[]]$CustomCharSet.Length))) -or `
    ($Pass -match "(.)\1{$MaxRepeatedChar,}")
  ) {
    $Pass = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, 0)
  }
  return $Pass
}
