Function SimpleCertCallback {
    <#
    .SYNOPSIS
    TLS, SSL circumvent certificate callback validation.
    
    .DESCRIPTION
    For cases such as;
    'Invoke-WebRequest The underlying connection was closed: Could not establish trust relationship for the SSL TLS secure channel.'
    
    .PARAMETER Operate
    Mandatory - use to suppress or revert validation check. Works in a current session but system wide. 
    
    .EXAMPLE
    SimpleCertCallback -Operate true
    
    .NOTES
    v2.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('true', 'false')]
        [string]$Operate
    )
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
                    return $Operate;
                };
        }
    }
}
"@
        Add-Type $CertCallback
    }
    [ServerCertificateValidationCallback]::Ignore()
}