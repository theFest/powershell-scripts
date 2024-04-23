Function Set-CertificateValidationOption {
    <#
    .SYNOPSIS
    Sets TLS validation options for .NET applications.

    .DESCRIPTION
    This function allows you to set various TLS validation options for .NET applications. It provides flexibility to either ignore certificate validation or validate certificates against trusted certificates.

    .PARAMETER Method
    Method to set TLS validation options, values are "Ignore" and "Validate".
    .PARAMETER Certificate
    Certificate used for validation when the method is set to "Validate".
    .PARAMETER TrustedCertificates
    Collection of trusted certificates used for validation when the method is set to "Validate".
    .PARAMETER CrlUrls
    An array of Certificate Revocation List (CRL) URLs.
    .PARAMETER SkipRevocationChecking
    Indicates whether to skip revocation checking during certificate validation.

    .EXAMPLE
    Set-CertificateValidationOption -Method Ignore -Verbose
    Set-CertificateValidationOption -Method Validate -Certificate $Cert -Verbose

    .NOTES
    v0.2.4
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Ignore", "Validate")]
        [string]$Method,

        [Parameter(Mandatory = $false)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,

        [Parameter(Mandatory = $false)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2Collection]$TrustedCertificates,

        [Parameter(Mandatory = $false)]
        [System.Uri[]]$CrlUrls,

        [Parameter(Mandatory = $false)]
        [switch]$SkipRevocationChecking
    )
    switch ($Method) {
        "Ignore" {
            Write-Verbose -Message "Ignoring certificate validation"
            [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
        }
        "Validate" {
            if ($TrustedCertificates) {
                Write-Verbose -Message "Validating certificates against trusted certificates"
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {
                    param($CallbackSender, $Certificate, $Chain, $SslPolicyErrors)
                    return $TrustedCertificates.Contains($Certificate)
                }
            }
            else {
                Write-Verbose "Performing default certificate validation"
                [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {
                    param($CallbackSender, $certificate, $Chain, $SslPolicyErrors)            
                    if ($SkipRevocationChecking) {
                        Write-Verbose -Message "Skipping revocation checking"
                        $Chain.ChainPolicy.RevocationFlag = [System.Security.Cryptography.X509Certificates.X509RevocationFlag]::EntireChain
                        $Chain.ChainPolicy.RevocationMode = [System.Security.Cryptography.X509Certificates.X509RevocationMode]::NoCheck
                    }
                    $Valid = ($SslPolicyErrors -eq [System.Net.Security.SslPolicyErrors]::None) -and $Certificate.Equals($Certificate)
                    if (-not $Valid) {
                        Write-Verbose -Message "Certificate validation failed."
                    }
                    return $Valid
                }
            }
        }
        default {
            Write-Error -Message "Invalid Method. Use 'Ignore' or 'Validate'!"
        }
    }
}
