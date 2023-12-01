Function Invoke-StringEncryption {
    <#
    .SYNOPSIS
    Encrypt a string with it's password.
    
    .DESCRIPTION
    With this simple function you can encrypt a string with it's key, something like 'public/private'(PKI). Also reuse defined or generated key in a decrypt form.

    .PARAMETER DefinedKey
    NotMandatory - your password with which you will encrypt your string. Don't forget your key because it's used for decryption.
    .PARAMETER GeneratedKey
    NotMandatory - your randomly generated password with which you will encrypt your string. Don't forget your key because it's used for decryption.
    .PARAMETER UnencryptedString
    Mandatory - actual string you wanna encrypt with your corresponding key.
    .PARAMETER KeySize
    NotMandatory - define your key size here, recommended is already defined. 
    .PARAMETER BlockSize
    NotMandatory - define your block size here, default is 128. 
    .PARAMETER Mode
    NotMandatory - choose cipher mode, default is CBC.  
    .PARAMETER Padding
    NotMandatory - choose padding mode, default is set to Zeros.
    .PARAMETER FilePath
    NotMandatory - if specified, saves the encrypted string or content to the provided file path.
    .PARAMETER InitializationVector
    NotMandatory - custom initialization vector for encryption.

    .EXAMPLE
    Invoke-StringEncryption -GeneratedKey -UnencryptedString '"y_string_to_encrypt" 
    Invoke-StringEncryption -DefinedKey "my_private_password" -UnencryptedString "my_string_to_encrypt"
    Invoke-StringEncryption -DefinedKey "MySecretKey" -UnencryptedString "SensitiveData" -FilePath "$env:USERPROFILE\Desktop\encrypted.txt"

    .NOTES
    v0.2.2
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$DefinedKey,

        [Parameter(Mandatory = $false)]
        [switch]$GeneratedKey,

        [Parameter(Mandatory = $true)]
        [string]$UnencryptedString,

        [Parameter(Mandatory = $false)]
        [int]$KeySize = 256,

        [Parameter(Mandatory = $false)]
        [int]$BlockSize = 128,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CBC", "CFB", "CTS", "ECB", "OFB")]
        $Mode = "CBC",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Zeros", "ANSIX923", "ISO10126", "PKCS7", "None")]
        $Padding = "Zeros",

        [Parameter(Mandatory = $false)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [byte[]]$InitializationVector
    )
    BEGIN {
        $ShaManaged = New-Object System.Security.Cryptography.SHA256Managed
        $AesManaged = New-Object System.Security.Cryptography.AesManaged
    }
    PROCESS {
        try {
            $AesManaged.Mode = [System.Security.Cryptography.CipherMode]::$Mode
            $AesManaged.Padding = [System.Security.Cryptography.PaddingMode]::$Padding
            $AesManaged.BlockSize = $BlockSize
            $AesManaged.KeySize = $KeySize
            if ($null -eq $InitializationVector) {
                $AesManaged.GenerateIV()
                $InitializationVector = $AesManaged.IV
            }
            else {
                $AesManaged.IV = $InitializationVector
            }
            switch ($PSBoundParameters.Keys) {
                "DefinedKey" {
                    $AesManaged.Key = $ShaManaged.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($DefinedKey))
                }
                "GeneratedKey" {
                    $AesManaged.GenerateKey()
                }
            }
            $PlainBytes = [System.Text.Encoding]::UTF8.GetBytes($UnencryptedString)
            $Encryptor = $AesManaged.CreateEncryptor()
            $EncryptedBytes = $Encryptor.TransformFinalBlock($PlainBytes, 0, $PlainBytes.Length)
            $EncryptedBytes = $InitializationVector + $EncryptedBytes
            $EncryptedString = [System.Convert]::ToBase64String($EncryptedBytes)
            if ($FilePath -ne $null) {
                [System.IO.File]::WriteAllBytes($FilePath, $EncryptedBytes)
            }
            Write-Host "Encryption successful" -ForegroundColor Green
            return $EncryptedString
        }
        catch {
            Write-Error -Message "Encryption failed: $_"
        }
    }
    END {
        $AesManaged.Dispose()
    }
}
