Function KeyVaultManager {
    <#
    .SYNOPSIS
    Manages Azure Key Vault.
    
    .DESCRIPTION
    With this function you can manage Azure Key Vault instance, given the vault name, secret name, certificates and more.
    
    .PARAMETER Subscription
    NotMandatory - specifies the Azure subscription to use, defaults to "Visual Studio Enterprise Subscription".
    .PARAMETER VaultName
    NotMandatory - specify the name of the key vault, if not specified, the function will prompt the user to select a key vault from those available in the subscription.
    .PARAMETER ResourceGroupName
    Mandatory - name of the resource group to use.
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
    KeyVaultManager -CreateKeyVaultName "create_your_keyvault_name" -ResourceGroupName "your_rg"
    KeyVaultManager -VaultName "your_keyvault" -ResourceGroupName "your_rg" -ListSecrets
    KeyVaultManager -VaultName "your_keyvault" -ResourceGroupName "your_rg" -GetSecret "your_secret"
    KeyVaultManager -VaultName "your_keyvault" -ResourceGroupName "your_rg" -ListCertificates
    KeyVaultManager -VaultName "your_keyvault" -ResourceGroupName "your_rg" -GetCertificate "your_cert"
    KeyVaultManager -VaultName "your_keyvault" -ResourceGroupName "your_rg" -AddSecret -SecretName "SecretKey" -SecretValue "Secret Value"
    KeyVaultManager -VaultName "your_keyvault" -ResourceGroupName "your_rg" -RemoveSecret -SecretName "SecretKey"
    KeyVaultManager -VaultName "your_keyvault" -ResourceGroupName "your_rg" -AddCertificate Default -CertificateName "you_cert_name" -CertificatePath "$env:SystemDrive\Temp\you_dn.com.pfx" -CertPass "mySecretPass12345"
    KeyVaultManager -VaultName "your_keyvault" -ResourceGroupName "your_rg" -RemoveCertificate -CertificateName "you_cert_name"
    
    .NOTES
    v1.0
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Visual Studio Enterprise Subscription", "Visual Studio Professional Subscription")] 
        [string]$Subscription = "Visual Studio Enterprise Subscription",

        [Parameter(Mandatory = $false)]
        [string]$VaultName,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $false)]
        [ValidatePattern('^[a-zA-Z0-9-]{3,24}$')]
        [string]$CreateKeyVaultName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("West Europe", "West US", "East US")]
        [string]$Location = "West Europe",

        [Parameter(Mandatory = $false)]
        [string]$SecretName,

        [Parameter(Mandatory = $false)]
        [string]$CertificateName,

        [Parameter(Mandatory = $false)]
        [string]$CertPass,

        [Parameter(Mandatory = $false)]
        [switch]$ListSecrets,

        [Parameter(Mandatory = $false)]
        [switch]$GetSecret,

        [Parameter(Mandatory = $false)]
        [switch]$ListCertificates,

        [Parameter(Mandatory = $false)]
        [switch]$GetCertificate,

        [Parameter(Mandatory = $false)]
        [switch]$AddSecret,

        [Parameter(Mandatory = $false)]
        [string]$SecretValue,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveSecret,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Default", "CertificateString")] 
        [string]$AddCertificate = "Default",

        [Parameter(Mandatory = $false)]
        [string]$CertificatePath,

        [Parameter(Mandatory = $false)]
        [switch]$RemoveCertificate
    )
    BEGIN {
        if (!(Get-Package -Name "Az*")) {
            [Net.ServicePointManager]::SecurityProtocol = "tls12, tls13"
            $AzPSurl = "https://github.com/Azure/azure-powershell/releases/download/v9.4.0-February2023/Az-Cmdlets-9.4.0.36911-x64.msi"
            Invoke-WebRequest -Uri $AzPSurl -OutFile "$env:TEMP\Az-Cmdlets-9.4.0.36911-x64.msi" -Verbose
            $AzInstallerArgs = @{
                FilePath     = 'msiexec.exe'
                ArgumentList = @(
                    "/i $env:TEMP\Az-Cmdlets-9.4.0.36911-x64.msi",
                    "/qr",
                    "/l* $env:TEMP\Az-Cmdlets.log"
                )
                Wait         = $true
            }
            Start-Process @AzInstallerArgs -NoNewWindow
        }
        Write-Verbose -Message "Checking authentification context against Azure..."
        if (!((Get-AzContext).Subscription.Name -eq $Subscription)) {
            Write-Host "You're not connected to Azure, please login interactively..." -ForegroundColor Yellow
            Connect-AzAccount -Verbose
        }
        if ($CreateKeyVaultName) {
            New-AzKeyVault -VaultName $CreateKeyVaultName -ResourceGroupName $ResourceGroupName -Location $Location -Verbose
            continue
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
                    Write-Error "Failed to add certificate '$CertificateName' to Key Vault $VaultName : $"
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