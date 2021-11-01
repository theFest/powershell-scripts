Function CertCallback {
    <#
    .SYNOPSIS
    TLS, SSL circumvent certificate callback validation.
    
    .DESCRIPTION
    Suppress 'Invoke-WebRequest The underlying connection was closed: Could not establish trust relationship for the SSL TLS secure channel.'
    
    .EXAMPLE
    CertCallback
    
    .NOTES
    v1
    #>
    if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type) {
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
}
"@
        Add-Type $CertCallback
    }
    [ServerCertificateValidationCallback]::Ignore()
}