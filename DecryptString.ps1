Function DecryptString {
    <#
    .SYNOPSIS
    Decrypt a string with it's password.
    
    .DESCRIPTION
    With this simple function you can decrypt a string, mandatory to reuse defined Key from a encrypt form.
    
    .PARAMETER Key
    Mandatory - your password with which you will decrypt your string. 
    .PARAMETER EncryptedString
    Mandatory - actual string you wanna to decrypt with your corresponding key. 
    .PARAMETER KeySize
    NotMandatory - define your key size here, recommended is already defined. 
    .PARAMETER BlockSize
    NotMandatory - define your block size here, default is 128.   
    .PARAMETER Mode
    NotMandatory - choose cipher mode, default is CBC.  
    .PARAMETER Padding
    NotMandatory - choose padding mode, default is set to Zeros.
    
    .EXAMPLE
    DecryptString -Key 'my_private_password' -EncryptedString 'oqbET916P0HPwYhepHqP3SPF3bd2qageFJgR2/oxpHI='
    
    .NOTES
    v1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key,

        [Parameter(Mandatory = $true)]
        [string]$EncryptedString,

        [Parameter(Mandatory = $false)]
        [int]$KeySize = 256,

        [Parameter(Mandatory = $false)]
        [int]$BlockSize = 128,

        [Parameter(Mandatory = $false)]
        [ValidateSet('CBC', 'CFB', 'CTS', 'ECB', 'OFB', 'CTS', 'CTS', 'CTS')]
        $Mode = 'CBC',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Zeros', 'ANSIX923', 'ISO10126', 'PKCS7', 'None')]
        $Padding = 'Zeros'
    )
    BEGIN {
        $ShaManaged = New-Object System.Security.Cryptography.SHA256Managed
        $AesManaged = New-Object System.Security.Cryptography.AesManaged
    }
    PROCESS {
        $AesManaged.Mode = [System.Security.Cryptography.CipherMode]::$Mode
        $AesManaged.Padding = [System.Security.Cryptography.PaddingMode]::$Padding
        $AesManaged.BlockSize = $BlockSize
        $AesManaged.KeySize = $KeySize
        $AesManaged.Key = $ShaManaged.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Key))
        $CipherBytes = [System.Convert]::FromBase64String($EncryptedString)
        $AesManaged.IV = $CipherBytes[0..15]
        $Decryptor = $AesManaged.CreateDecryptor()
        $DecryptedBytes = $Decryptor.TransformFinalBlock($CipherBytes, 16, $CipherBytes.Length - 16)
        $PublicKey = [System.Text.Encoding]::UTF8.GetString($DecryptedBytes).Trim([char]0)
    }
    END {
        $AesManaged.Dispose()
        Write-Output "Plaintext string: $Key"
        Write-Output "Decrypted string: $PublicKey"
    }
}