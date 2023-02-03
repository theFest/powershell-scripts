Function RandomPasswordGenerator {
    <#
    .SYNOPSIS
    Password generator.
    
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
    v1.0
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
        $upperCase = '[A-HJ-NP-Z\p{Lu}]'
        $lowerCase = '[a-hj-np-z\p{Ll}]'
        $numeric = '[\d\S]'
        $special = '[^\w\s]'
    }
    ## Exclude easily confused characters
    if ($ExcludeConfused) {
        $upperCase = '[A-HJ-NP-Z\p{Lu}]'
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
    Add-Type -AssemblyName System.Web -Verbose
    $password = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, 0)
    ## Check if the password meets the requirements
    while ($(([regex]::Matches($password, $upperCase) `
                | ForEach-Object { $_.Value }).Count -lt $MinUpperCase) -or 
        $(([regex]::Matches($password, $lowerCase) `
                | ForEach-Object { $_.Value }).Count -lt $MinLowerCase) -or 
        $(([regex]::Matches($password, $numeric) `
                | ForEach-Object { $_.Value }).Count -lt $MinNumeric) -or 
        $(([regex]::Matches($password, $special) `
                | ForEach-Object { $_.Value }).Count -lt $MinSpecialChar) -or
           ($CustomCharSet -and $(([regex]::Matches($password, $custom) `
                | ForEach-Object { $_.Value }).Count -lt [math]::Min($PasswordLength, [int][char[]]$CustomCharSet.Length))) -or
           ($Password -match "(.)\1{$MaxRepeatedChar,}")
    ) {
        $Password = [System.Web.Security.Membership]::GeneratePassword($PasswordLength, 0)
    }
    return $Password
}