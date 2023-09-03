Function Get-ValidCertificates {
    <#
    .SYNOPSIS
    Retrieves valid certificates from a certificate store based on specified criteria.

    .DESCRIPTION
    This function retrieves certificates from a specified certificate store based on various parameters.
    You can filter certificates by friendly name, expiration date, store location, store name, and more.

    .PARAMETER FriendlyNameFilter
    Filters certificates by their friendly name. You can provide a partial name or use wildcards.

    .PARAMETER NotAfter
    NotManatory - filters certificates to include only those not expired as of the specified date.
    .PARAMETER PromptUser
    NotManatory - user to select a certificate if multiple valid certificates are found.
    .PARAMETER StoreLocation
    NotManatory - the certificate store location (CurrentUser or LocalMachine). Default is CurrentUser.
    .PARAMETER StoreName
    NotManatory - the certificate store name (My, Root, CA, AuthRoot, TrustedPublisher, Disallowed). Default is My.
    .PARAMETER IncludeExpired
    NotManatory - includes expired certificates in the result if this switch is specified.
    .PARAMETER IncludePrivateKey
    NotManatory - includes the private key with the certificate information if this switch is specified.

    .EXAMPLE
    Get-ValidCertificates
    Get-ValidCertificates -FriendlyNameFilter "your_cert_name"
    Get-ValidCertificates -StoreLocation LocalMachine -StoreName Root -IncludeExpired

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$FriendlyNameFilter,

        [Parameter(Mandatory = $false)]
        [datetime]$NotAfter,

        [Parameter(Mandatory = $false)]
        [switch]$PromptUser,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CurrentUser", "LocalMachine")]
        [string]$StoreLocation = "CurrentUser",

        [Parameter(Mandatory = $false)]
        [ValidateSet("My", "Root", "CA", "AuthRoot", "TrustedPublisher", "Disallowed")]
        [string]$StoreName = "My",

        [Parameter(Mandatory = $false)]
        [switch]$IncludeExpired,

        [Parameter(Mandatory = $false)]
        [switch]$IncludePrivateKey
    )
    PROCESS {
        try {
            Write-Verbose -Message "Retrieving certificates..."
            $Store = New-Object System.Security.Cryptography.X509Certificates.X509Store("$StoreName", "$StoreLocation")
            $Store.Open([System.Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
            $ValidCerts = $Store.Certificates | Where-Object {
                ($null -eq $FriendlyNameFilter -or $_.FriendlyName -like "$FriendlyNameFilter*") -and
                ($IncludeExpired -or ($null -eq $NotAfter -or $_.NotAfter -gt $NotAfter))
            }
            if ($ValidCerts.Count -eq 0) {
                Write-Verbose -Message "No valid certificates found."
                return $null
            }
            $Results = @() 
            foreach ($Cert in $ValidCerts) {
                $CertInfo = [PSCustomObject]@{
                    FriendlyName = $Cert.FriendlyName
                    Subject      = $Cert.Subject
                    Issuer       = $Cert.Issuer
                    Thumbprint   = $Cert.Thumbprint
                    SerialNumber = $Cert.GetSerialNumberString()
                }
                if ($IncludePrivateKey) {
                    $CertInfo.PrivateKey = $Cert.PrivateKey
                }
                $Results += $CertInfo
            }
            if ($Results.Count -eq 1 -and !$PromptUser) {
                Write-Verbose -Message "Only one valid certificate found. Returning it immediately without prompting."
                return $Results[0]
            }
            if ($PromptUser) {
                Write-Verbose -Message "Prompting the user to select a certificate..."
                $SelectedCert = [System.Security.Cryptography.X509Certificates.X509Certificate2UI]::SelectFromCollection(
                    $ValidCerts,
                    "Choose a certificate",
                    "Choose a certificate",
                    "SingleSelection"
                ) | Select-Object -First 1
                $SelectedCertInfo = [PSCustomObject]@{
                    FriendlyName = $SelectedCert.FriendlyName
                    Subject      = $SelectedCert.Subject
                    Issuer       = $SelectedCert.Issuer
                    Thumbprint   = $SelectedCert.Thumbprint
                    SerialNumber = $SelectedCert.GetSerialNumberString()
                }
                if ($IncludePrivateKey) {
                    $SelectedCertInfo.PrivateKey = $SelectedCert.PrivateKey
                }
                return $SelectedCertInfo
            }
            else {
                Write-Verbose -Message "Returning all valid certificates..."
                return $Results
            }
        }
        finally {
            $Store.Close()
        }
    }
}
