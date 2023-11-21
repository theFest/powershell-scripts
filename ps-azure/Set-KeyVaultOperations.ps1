Function Set-KeyVaultOperations {
    <#
    .SYNOPSIS
    Simple Azure Key Vault Manager.

    .DESCRIPTION
    With this function you can manage Azure Key Vault instance, given the vault name, secret name, certificates and more.

    .PARAMETER ResourceGroupName
    Mandatory - name of the resource group to use.
    .PARAMETER VaultName
    NotMandatory - specify the name of the key vault, if not specified, the function will prompt the user to select a key vault from those available in the subscription.
    .PARAMETER CreateKeyVaultName
    NotMandatory - name of a new key vault to create, if specified, the function will create the key vault and exit.
    .PARAMETER Location
    NotMandatory - choose location of the key vault. Defaults to "West Europe".
    .PARAMETER SecretName
    NotMandatory - name of a secret.
    .PARAMETER CertificateName
    NotMandatory - name of a certificate.
    .PARAMETER CertPass
    NotMandatory - password for a certificate.
    .PARAMETER ListSecrets
    NotMandatory - list of secrets from the key vault.
    .PARAMETER GetSecret
    NotMandatory - retrieves a secret from the key vault, requires the SecretName parameter.
    .PARAMETER ListCertificates
    NotMandatory - fetches a list of certificates from the key vault.
    .PARAMETER GetCertificate
    NotMandatory - retrieves a certificate from the key vault, requires the CertificateName parameter.
    .PARAMETER AddSecret
    NotMandatory - adds a secret to the key vault, requires the SecretName and SecretValue parameters.
    .PARAMETER SecretValue
    NotMandatory - declare/specify the value of a secret.
    .PARAMETER RemoveSecret
    NotMandatory - removes a secret from the key vault, requires the SecretName parameter.
    .PARAMETER AddCertificate
    NotMandatory - specifies how to add a certificate, defaults to "Default".
    .PARAMETER CertificatePath
    NotMandatory - the path to a certificate file.
    .PARAMETER RemoveCertificate
    NotMandatory - removes a certificate from the key vault, requires the CertificateName parameter.

    .EXAMPLE
    Set-KeyVaultOperations -ResourceGroupName "your_rg" -CreateKeyVaultName "create_your_keyvault_name"
    Set-KeyVaultOperations -ResourceGroupName "your_rg" -VaultName "your_keyvault" -ListSecrets
    Set-KeyVaultOperations -ResourceGroupName "your_rg" -VaultName "your_keyvault" -GetSecret "your_secret"
    Set-KeyVaultOperations -ResourceGroupName "your_rg" -VaultName "your_keyvault" -ListCertificates
    Set-KeyVaultOperations -ResourceGroupName "your_rg" -VaultName "your_keyvault" -GetCertificate "your_cert"
    Set-KeyVaultOperations -ResourceGroupName "your_rg" -VaultName "your_keyvault" -AddSecret -SecretName "SecretKey" -SecretValue "Secret Value"
    Set-KeyVaultOperations -ResourceGroupName "your_rg" -VaultName "your_keyvault" -RemoveSecret -SecretName "SecretKey"
    Set-KeyVaultOperations -ResourceGroupName "your_rg" -VaultName "your_keyvault" -AddCertificate Default -CertificateName "you_cert_name" -CertificatePath "$env:SystemDrive\Temp\your_dn.com.pfx" -CertPass "mySecretPass12345!"
    Set-KeyVaultOperations -ResourceGroupName "your_rg" -VaultName "your_keyvault" -RemoveCertificate -CertificateName "you_cert_name"

    .NOTES
    v1.0.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $false)]
        [string]$VaultName,

        [Parameter(Mandatory = $false)]
        [ValidatePattern('^[a-zA-Z0-9-]{3,24}$')]
        [string]$CreateKeyVaultName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("West Europe", "North Europe", "West US", "East US", "Central US" , "Southeast Asia", "Brazil South")]
        [string]$Location = "West Europe",

        [Parameter(Mandatory = $false)]
        [string]$SecretName,

        [Parameter(Mandatory = $false)]
        [string]$SecretValue,

        [Parameter(Mandatory = $false)]
        [string]$CertificateName,

        [Parameter(Mandatory = $false)]
        [string]$CertPass,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Default", "CertificateString")]
        [string]$AddCertificate = "Default",

        [Parameter(Mandatory = $false)]
        [string]$CertificatePath,

        [Parameter()]
        [switch]$ListSecrets,

        [Parameter()]
        [switch]$GetSecret,

        [Parameter()]
        [switch]$ListCertificates,

        [Parameter()]
        [switch]$GetCertificate,

        [Parameter()]
        [switch]$AddSecret,

        [Parameter()]
        [switch]$RemoveSecret,

        [Parameter()]
        [switch]$RemoveCertificate
    )
    BEGIN {
        if (!(Get-InstalledModule -Name "Az")) {
            Write-Verbose -Message "Installing the Az PowerShell module..."
            try {
                Install-Module -Name "Az" -Scope CurrentUser -Verbose
            }
            catch {
                Write-Error "Failed to import 'Az' module. Error: $_"
                return
            }
        }
        Write-Warning -Message "Checking authentification context against Azure..."
        if (!(Get-AzContext -ErrorAction SilentlyContinue)) {
            try {
                Connect-AzAccount -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to authenticate user. Error: $_"
                return
            }
        }
        if ($CreateKeyVaultName) {
            try {
                New-AzKeyVault -VaultName $CreateKeyVaultName -ResourceGroupName $ResourceGroupName -Location $Location -Verbose
            }
            catch {
                Write-Error "Failed to create Key Vault. Error: $_"
                return
            }
            return
        }
    }
    PROCESS {
        switch ($true) {
            { $ListSecrets } {
                Write-Output "Retrieving the list of secrets from Key Vault $VaultName..."
                Get-AzKeyVaultSecret -VaultName $VaultName | Select-Object -Property Name, Id, Enabled, Created, Expires
            } { $GetSecret } {
                if (!$SecretName) {
                    Write-Error "SecretName parameter is required when using GetSecret switch."
                    return
                }
                Write-Output "Retrieving the secret '$SecretName' from Key Vault $VaultName..."
                Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName
            } { $ListCertificates } {
                Write-Output "Retrieving the list of certificates from Key Vault $VaultName..."
                Get-AzKeyVaultCertificate -VaultName $VaultName | Select-Object -Property Name, Id, Created, Expires
            } { $GetCertificate } {
                if (!$CertificateName) {
                    Write-Error "CertificateName parameter is required when using GetCertificate switch."
                    return
                }
                Write-Output "Retrieving the certificate '$CertificateName' from Key Vault $VaultName..."
                Get-AzKeyVaultCertificate -VaultName $VaultName -Name $CertificateName
            } { $AddSecret } {
                if (!$SecretName -or !$SecretValue) {
                    Write-Error "SecretName and SecretValue parameters are required when using AddSecret switch."
                    return
                }
                Write-Output "Adding the secret '$SecretName' to Key Vault $VaultName..."
                $SecureSecretValue = ConvertTo-SecureString $SecretValue -AsPlainText -Force
                Set-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -SecretValue $SecureSecretValue
            } { $RemoveSecret } {
                if (!$SecretName) {
                    Write-Error "SecretName parameter is required when using RemoveSecret switch."
                    return
                }
                Write-Output "Removing the secret '$SecretName' from Key Vault $VaultName..."
                Remove-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName -Force -Verbose
            } { $AddCertificate } {
                if (!$CertificateName -or !$CertificatePath) {
                    Write-Error "CertificateName and CertificatePath parameters are required when using AddCertificate switch."
                    return
                }
                Write-Output "Adding the certificate '$CertificateName' to Key Vault $VaultName..."
                try {
                    $SecCertPass = ConvertTo-SecureString -String $CertPass -AsPlainText -Force
                    if ($AddCertificate -eq "Default") {
                        Import-AzKeyVaultCertificate -VaultName $VaultName -Name $CertificateName -FilePath $CertificatePath -Password $SecCertPass
                    }
                    elseif ($AddCertificate -eq "CertificateString") {
                        $Base64String = [System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes("$CertificateName"))
                        Import-AzKeyVaultCertificate -VaultName $VaultName -Name $CertificateName -CertificateString $Base64String -Password $SecCertPass
                    }
                }
                catch {
                    Write-Error "Failed to add certificate '$CertificateName' to Key Vault $VaultName : $_"
                }
            } $RemoveCertificate {
                if (!$CertificateName) {
                    Write-Error "CertificateName parameter is required when using RemoveCertificate switch."
                    return
                }
                Write-Output "Removing the certificate '$CertificateName' from Key Vault $VaultName..."
                try {
                    Remove-AzKeyVaultCertificate -VaultName $VaultName -Name $CertificateName -Force
                }
                catch {
                    Write-Error "Failed to remove certificate '$CertificateName' from Key Vault $VaultName : $CertificateName"
                }
            }
            default {
                Write-Error "One of the following switches must be specified: ListSecrets, GetSecret, ListCertificates, GetCertificate, AddSecret, RemoveSecret, AddCertificate, RemoveCertificate"
                return
            }
        }
    }
    END {
        Clear-Variable -Name VaultName, ResourceGroupName, SecretName, SecretValue, CertificateName, CertPass `
            -Force -ErrorAction SilentlyContinue
        Write-Verbose -Message "Finished processing Key Vault commands, closing connection and exiting."
        Disconnect-AzAccount -Verbose
    }
}
