Function Set-CertificateValidationOption {
    <#
    .SYNOPSIS
    Adopted for PowerShell instead of C# code.
    
    .DESCRIPTION
    Comes with different options such as allowing invalid certs.
    
    .PARAMETER Method
    Mandatory - determines if the server certificate should be ignored or validated. It can take two values: "Ignore" or "Validate".
    .PARAMETER Certificate
    Mandatory - this parameter is mandatory if the method is set to "Validate". It accepts an X509Certificate object to use for validation.
    .PARAMETER TrustedCertificates
    NotMandatory - it accepts a list of X509Certificate objects, if provided, the function will validate the server certificate against this list of trusted certificates.
    .PARAMETER CrlUrls
    NotMandatory - If provided, function will check the certificate against the CRLs available at the provided URLs.
    .PARAMETER SkipRevocationChecking
    NotMandatory - if set to true, the function will ignore the revocation check, otherwise it will check the CRLs available at the provided URLs.
    .PARAMETER AllowInvalidCertificates
    NotMandatory - switch parameter, if set to true, the function will allow invalid certificates, otherwise it will return false.
    
    .EXAMPLE
    Set-CertificateValidationOption Ignore
    Set-CertificateValidationOption Validate
    
    .NOTES
    v0.1.7
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Ignore', 'Validate')]
        [string]$Method,

        [Parameter()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate,

        [Parameter()]
        [System.Collections.Generic.List[System.Security.Cryptography.X509Certificates.X509Certificate]]
        $TrustedCertificates,

        [Parameter()]
        [System.Collections.Generic.List[System.Uri]]
        $CrlUrls,

        [Parameter()]
        [switch]
        $SkipRevocationChecking,

        [Parameter()]
        [switch]
        $AllowInvalidCertificates
    )
    if ($Method -eq "Ignore") {
        [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
    } 
    elseif ($Method -eq "Validate") {
        if ($TrustedCertificates) {
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {
                param($sender, $certificate, $chain, $sslPolicyErrors)
                return $TrustedCertificates.Contains($certificate)
            }
        }
        else {
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {
                param($sender, $certificate, $chain, $sslPolicyErrors)            
                if ($SkipRevocationChecking) {
                    $chain.ChainPolicy.RevocationFlag = [System.Security.Cryptography.X509Certificates.X509RevocationFlag]::EntireChain
                    $chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::NoCheck
                }
                if ($AllowInvalidCertificates) {
                    return true
                }
                else {
                    return ($sslPolicyErrors -eq [System.Net.Security.SslPolicyErrors]::None) -and $certificate.Equals($Certificate)
                }
            }
        }
    }
}