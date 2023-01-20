Function ServerCertificateValidationCallback {
    <#
    .SYNOPSIS
    TLS, SSL circumvent certificate callback validation.

    .DESCRIPTION
    Invoke-WebRequest The underlying connection was closed: Could not establish trust relationship for the SSL TLS secure channel.

    .PARAMETER Operate
    Mandatory - specify whether the certificate validation should be ignored or validated.
    .PARAMETER Certificate
    NotMandatory - pecify a single X509Certificate object that should be used for validation, if this parameter is used, the function will compare the passed certificate with the certificate being validated.
    .PARAMETER TrustedCertificates
    NotMandatory - used to specify a list of trusted X509Certificate objects that should be used for validation. If this parameter is used, the function will check if the certificate being validated is present in the list of trusted certificates.
    .PARAMETER Callback
    NotMandatory - specify a script block that contains a callback function that should be executed when a certificate validation occurs, the script block should return a Boolean value indicating whether the certificate is valid or not.

    .EXAMPLE
    ServerCertificateValidationCallback -Operate Ignore
    
    .NOTES
    v2.1
    #>
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
        [System.Collections.Generic.List[System.Security.Cryptography.X509Certificates.X509Certificate]]$TrustedCertificates,
        
        [Parameter()]
        [scriptblock]$Callback
    )
    $CertCallback = @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
public class ServerCertificateValidationCallback
{
    public static void Ignore()
    {
        if(ServicePointManager.ServerCertificateValidationCallback ==null)
        {
            ServicePointManager.ServerCertificateValidationCallback += 
                delegate
                (
                    Object obj, 
                    X509Certificate certificate, 
                    X509Chain chain, 
                    SslPolicyErrors errors
                )
                {
                    return true;
                };
        }
    }
    public static void Validate(X509Certificate certificate)
    {
        if(ServicePointManager.ServerCertificateValidationCallback == null)
        {
            ServicePointManager.ServerCertificateValidationCallback += 
                (obj, cert, chain, errors) =>
                {
                    return certificate.Equals(cert);
                };
        }
    }
    public static void Validate(List<X509Certificate> trustedCertificates)
    {
        if(ServicePointManager.ServerCertificateValidationCallback == null)
        {
            ServicePointManager.ServerCertificateValidationCallback += 
                (obj, cert, chain, errors) =>
                {
                    return trustedCertificates.Contains(cert);
                };
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
    Add-Type $CertCallback
    if ($Operate -eq "Ignore") {
        [ServerCertificateValidationCallback]::Ignore()
    }
    elseif ($Certificate) {
        [ServerCertificateValidationCallback]::Validate($Certificate)
    }
    elseif ($TrustedCertificates) {
        [ServerCertificateValidationCallback]::Validate($TrustedCertificates)
    }
    elseif ($Callback) {
        [ServerCertificateValidationCallback]::Validate($Callback)
    }
}
