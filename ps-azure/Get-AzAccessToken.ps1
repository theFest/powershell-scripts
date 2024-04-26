Function Get-AzAccessToken {
    <#
    .SYNOPSIS
    Retrieves an Azure access token for authentication.

    .DESCRIPTION
    This function retrieves an Azure access token using the client credentials flow or a client certificate for authentication.

    .PARAMETER ClientId
    Client ID of the Azure AD application.
    .PARAMETER ClientSecret
    Client secret associated with the Azure AD application.
    .PARAMETER ApplicationID
    Application ID of the Azure AD application when using a client certificate.
    .PARAMETER CertificateThumbprint
    Thumbprint of the client certificate stored in the Local Machine certificate store.
    .PARAMETER TenantId
    Specifies the ID of the Azure AD tenant.
    .PARAMETER Resource
    Specifies the target resource for the access token.
    .PARAMETER Scope
    Scope for the access token, default is "https://vault.azure.net/.default".

    .EXAMPLE
    Get-AzAccessToken -ClientId "your_ClientId" -ClientSecret "your:ClientSecret" -TenantId "your_TenantId" -Resource "https://management.azure.com"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'Resource')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Scope')]
        [String]$ClientId,
            
        [Parameter(Mandatory = $true, ParameterSetName = 'Resource')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Scope')]
        [string]$ClientSecret,
            
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [string]$ApplicationID,
            
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [string]$CertificateThumbprint,
            
        [Parameter(Mandatory = $true, ParameterSetName = 'Certificate')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Resource')]
        [Parameter(Mandatory = $true, ParameterSetName = 'Scope')]
        [string]$TenantId,
            
        [Parameter(Mandatory = $true, ParameterSetName = 'Resource')]
        [string]$Resource,
            
        [Parameter(Mandatory = $false, ParameterSetName = 'Certificate')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Scope')]
        [ValidateSet("https://vault.azure.net/.default", "https://management.azure.com/.default", "https://graph.microsoft.com/.default")]
        [string]$Scope = "https://vault.azure.net/.default"
    )
    BEGIN {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
        $ContentType = "application/x-www-form-urlencoded"
        $UserAgent = [Microsoft.PowerShell.Commands.PSUserAgent]::FireFox
    } 
    PROCESS {
        if ($CertificateThumbprint) {
            $Certificate = Get-ChildItem -Path "Cert:\LocalMachine\My\$CertificateThumbprint"
            $CertificateBase64Hash = [System.Convert]::ToBase64String($Certificate.GetCertHash())
            Write-Debug -Message "[D] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Creating JWT header"
            $JWTHeader = @{
                alg = "RS256"
                typ = "JWT"
                x5t = $CertificateBase64Hash -Replace '\+', '-' -Replace '/', '_' -Replace '='
            }
            Write-Debug -Message "[D] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Creating JWT payload"
            $JWTPayLoad = @{
                aud = "https://login.microsoftonline.com/$($TenantID)/oauth2/token"
                exp = ([System.DateTimeOffset](Get-date).AddMinutes(5)).ToUnixTimeSeconds()
                iss = $ApplicationID
                jti = [System.Guid]::NewGuid()
                nbf = ([System.DateTimeOffset](Get-Date).ToUniversalTime()).ToUnixTimeSeconds()
                sub = $ApplicationID  
            }  
            Write-Debug -Message "[D] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Converting header and payload to base64"
            $JWTHeaderToByte = [System.Text.Encoding]::UTF8.GetBytes(($JWTHeader | ConvertTo-Json))  
            $EncodedHeader = [System.Convert]::ToBase64String($JWTHeaderToByte)  
            $JWTPayLoadToByte = [System.Text.Encoding]::UTF8.GetBytes(($JWTPayload | ConvertTo-Json))  
            $EncodedPayload = [System.Convert]::ToBase64String($JWTPayLoadToByte)  
            Write-Debug -Message "[D] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Joining header and Payload with '.' to create a valid (unsigned) JWT"
            $JWT = $EncodedHeader + "." + $EncodedPayload  
            Write-Debug -Message "[D] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Obtain the private key object of your certificate"  
            $PrivateKey = ([System.Security.Cryptography.X509Certificates.RSACertificateExtensions]::GetRSAPrivateKey($Certificate))  
            Write-Debug -Message "[D] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Define RSA signature and hashing algorithm"
            $RSAPadding = [System.Security.Cryptography.RSASignaturePadding]::Pkcs1  
            $HashAlgorithm = [System.Security.Cryptography.HashAlgorithmName]::SHA256  
            Write-Debug -Message "[D] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Creating a signature of the JWT"
            $Signature = [System.Convert]::ToBase64String(  
                $PrivateKey.SignData([System.Text.Encoding]::UTF8.GetBytes($JWT), $HashAlgorithm, $RSAPadding)  
            ) -Replace '\+', '-' -Replace '/', '_' -Replace '='  
            Write-Debug -Message "[D] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Joining the signature to the JWT with '.'"
            $JWT = $JWT + "." + $Signature  
            Write-Debug -Message "[D] $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss') Creating a hash with body parameters" 
            $Body = @{  
                client_id             = $ApplicationID  
                client_assertion      = $JWT  
                client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"  
                scope                 = $Scope  
                grant_type            = "client_credentials"  
            }
        }
        else {
            $Body = @{ 
                "grant_type"    = "client_credentials" 
                "client_id"     = $ClientId
                "client_secret" = $ClientSecret
            }
        }
        switch ($PSCmdlet.ParameterSetName) {
            "Resource" {
                $Body["Resource"] = $Resource
            } 
            "Scope" {
                $Body["Scope"] = $Scope
            }
        }
        $Uri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"    
        $Header = @{  
            Authorization = "Bearer $JWT"  
        }
        $Token = Invoke-RestMethod -UseBasicParsing -Method POST -UserAgent $UserAgent -ContentType $ContentType -Uri $Uri -Headers $Header -Body $Body -Verbose:$false | Select-Object -ExpandProperty access_token
    } 
    END {
        $script:GraphHeader = @{  
            Authorization = "Bearer $Token"  
        }
        $script:GraphAccessToken = $Token
        return $Token
    }
}
