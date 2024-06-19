function Set-TLSValidationPolicy {
    <#
    .SYNOPSIS
    Configures the TLS certificate validation settings.

    .DESCRIPTION
    This function sets the TLS certificate validation options.It can either ignore certificate validation, validate against a specified certificate, a list of trusted certificates, or a custom validation callback. It also provides a simple toggle to suppress or enforce validation checks.

    .EXAMPLE
    Set-TLSValidationPolicy -Operate Ignore
    Set-TLSValidationPolicy -Operate Validate -Certificate $myCert
    Set-TLSValidationPolicy -Operate Validate -TrustedCertificates $myTrustedCerts
    Set-TLSValidationPolicy -Operate Validate -Callback { param ($cert, $chain, $errors) $cert.Subject -eq "CN=trusted" }
    Set-TLSValidationPolicy -Operate Toggle -Ignore $true
    Set-TLSValidationPolicy -Operate Toggle -Ignore $false

    .NOTES
    * for cases such as: 'Invoke-WebRequest The underlying connection was closed: Could not establish trust relationship for the SSL TLS secure channel'
    v0.6.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Operation mode, values are 'Ignore' to ignore TLS certificate validation and 'Validate' to enable certificate validation")]
        [ValidateSet("Ignore", "Validate", "Toggle")]
        [string]$Operate,

        [Parameter(Mandatory = $false, HelpMessage = "Single X509 certificate against which the server's certificate will be validated")]
        [System.Security.Cryptography.X509Certificates.X509Certificate]$Certificate,

        [Parameter(Mandatory = $false, HelpMessage = "List of trusted X509 certificates against which the server's certificate will be validated")]
        [System.Collections.Generic.List[System.Security.Cryptography.X509Certificates.X509Certificate]]$TrustedCertificates,

        [Parameter(Mandatory = $false, HelpMessage = "Defines custom validation logic for the server's certificate")]
        [scriptblock]$Callback,

        [Parameter(Mandatory = $false, HelpMessage = "Value to toggle the TLS certificate validation on or off")]
        [bool]$Ignore
    )
    $CertCallbackCode = @"
using System;
using System.Net;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;
using System.Collections.Generic;

public class CertificateValidationOptions
{
    public static void Ignore()
    {
        ServicePointManager.ServerCertificateValidationCallback = (obj, cert, chain, errors) => true;
    }

    public static void Validate(X509Certificate certificate)
    {
        ServicePointManager.ServerCertificateValidationCallback = (obj, cert, chain, errors) => certificate.Equals(cert);
    }

    public static void Validate(List<X509Certificate> trustedCertificates)
    {
        ServicePointManager.ServerCertificateValidationCallback = (obj, cert, chain, errors) => trustedCertificates.Contains(cert);
    }

    public static void Validate(RemoteCertificateValidationCallback callback)
    {
        ServicePointManager.ServerCertificateValidationCallback = callback;
    }

    public static void Toggle(bool ignore)
    {
        if (ignore)
        {
            ServicePointManager.ServerCertificateValidationCallback = (obj, cert, chain, errors) => true;
        }
        else
        {
            ServicePointManager.ServerCertificateValidationCallback = null;
        }
    }

    public static bool IsIgnore
    {
        get
        {
            var callback = ServicePointManager.ServerCertificateValidationCallback;
            if (callback == null) return false;
            foreach (var del in callback.GetInvocationList())
            {
                if (del.Method.Name == "Ignore") return true;
            }
            return false;
        }
    }
}
"@
    Add-Type -TypeDefinition $CertCallbackCode -Language CSharp
    switch ($Operate) {
        "Ignore" {
            [CertificateValidationOptions]::Ignore()
        }
        "Validate" {
            if ($Certificate) {
                [CertificateValidationOptions]::Validate($Certificate)
            }
            elseif ($TrustedCertificates) {
                [CertificateValidationOptions]::Validate($TrustedCertificates)
            }
            elseif ($Callback) {
                [CertificateValidationOptions]::Validate([System.Net.Security.RemoteCertificateValidationCallback] {
                        param ($cert, $chain, $errors)
                        & $Callback $cert $chain $errors
                    })
            }
            else {
                throw "Validation requires either a Certificate, TrustedCertificates, or a Callback!"
            }
        }
        "Toggle" {
            if ($PSBoundParameters.ContainsKey('Ignore')) {
                [CertificateValidationOptions]::Toggle($Ignore)
            }
            else {
                throw "Toggle operation requires the Ignore parameter to be specified!"
            }
        }
    }
}
