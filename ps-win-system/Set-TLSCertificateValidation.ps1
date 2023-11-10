Function Set-TLSCertificateValidation {
    <#
    .SYNOPSIS
    Configure TLS/SSL certificate validation options.

    .DESCRIPTION
    This function allows you to configure TLS/SSL certificate validation options to either ignore or validate certificates.

    .PARAMETER Operate
    Mandatory - Specify whether the certificate validation should be ignored or validated.
    .PARAMETER Certificate
    Not Mandatory - Define a single X509Certificate object that should be used for validation. If used, the function will compare the passed certificate with the certificate being validated.
    .PARAMETER TrustedCertificates
    Not Mandatory - List of trusted X509Certificate objects that should be used for validation. If used, the function will check if the certificate being validated is present in the list of trusted certificates.
    .PARAMETER Callback
    Not Mandatory - Specify a script block that contains a callback function that should be executed when a certificate validation occurs. The script block should return a Boolean value indicating whether the certificate is valid or not.

    .EXAMPLE
    Set-TLSCertificateValidation -Operate Ignore
    Set-TLSCertificateValidation -Operate Validate -Certificate $MyCertificate
    Set-TLSCertificateValidation -Operate Validate -TrustedCertificates $TrustedCerts
    Set-TLSCertificateValidation -Operate Validate -Callback { param($cert, $chain, $errors) $cert.Subject -eq "CN=ValidCert" }

    .NOTES
    Version: 0.2.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Ignore', 'Validate')]
        [string]$Operate,
        
        [Parameter()]
        [System.Security.Cryptography.X509Certificates.X509Certificate]
        $Certificate,
        
        [Parameter()]
        [System.Collections.Generic.List[System.Security.Cryptography.X509Certificates.X509Certificate]]
        $TrustedCertificates,
        
        [Parameter()]
        [scriptblock]$Callback
    )
    $CertCallbackCode = @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

public class CertificateValidationOptions
{
    public static void Ignore()
    {
        if(ServicePointManager.ServerCertificateValidationCallback == null)
        {
            ServicePointManager.ServerCertificateValidationCallback += (obj, cert, chain, errors) => true;
        }
    }

    public static void Validate(X509Certificate certificate)
    {
        if(ServicePointManager.ServerCertificateValidationCallback == null)
        {
            ServicePointManager.ServerCertificateValidationCallback += (obj, cert, chain, errors) => certificate.Equals(cert);
        }
    }

    public static void Validate(List<X509Certificate> trustedCertificates)
    {
        if(ServicePointManager.ServerCertificateValidationCallback == null)
        {
            ServicePointManager.ServerCertificateValidationCallback += (obj, cert, chain, errors) => trustedCertificates.Contains(cert);
        }
    }

    public static void Validate(Func<X509Certificate, X509Chain, SslPolicyErrors, bool> callback)
    {
        if(ServicePointManager.ServerCertificateValidationCallback == null)
        {
            ServicePointManager.ServerCertificateValidationCallback += callback;
        }
    }

    public static bool IsIgnore
    {
        get
        {
            if(ServicePointManager.ServerCertificateValidationCallback == null)
                return false;

            return ServicePointManager.ServerCertificateValidationCallback.Method.Name == "Ignore";
        }
    }
}
"@
    Add-Type -TypeDefinition $CertCallbackCode

    if ($Operate -eq "Ignore") {
        [CertificateValidationOptions]::Ignore()
    }
    elseif ($Certificate) {
        [CertificateValidationOptions]::Validate($Certificate)
    }
    elseif ($TrustedCertificates) {
        [CertificateValidationOptions]::Validate($TrustedCertificates)
    }
    elseif ($Callback) {
        [CertificateValidationOptions]::Validate($Callback)
    }
}
