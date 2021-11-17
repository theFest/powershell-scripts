Function DecryptString {
    <#
    .SYNOPSIS
    Decrypt a string with it's password.
    
    .DESCRIPTION
    With this simple function you can decrypt a string, mandatory to reuse defined or generated key from a encrypt form.
    
    .PARAMETER GeneratedKey
    NotMandatory - your randomly generated password with which you will decrypt your string.
    .PARAMETER PreDefinedKey
    NotMandatory - your predefined password with which you will decrypt your string. 
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
    DecryptString -PreDefinedKey 'my_private_password' -EncryptedString 'oqbET916P0HPwYhepHqP3SPF3bd2qageFJgR2/oxpHI='
    DecryptString -GeneratedKey 'n+FnVLTeF0sFKbRonuzgz7ECSQb776wdvsnpSx1q7z4=' -EncryptedString 'R7M8uqAjkI15H9ha9Hxx3WFNlQoli+hl7Gg6vZeAa1Z6G4avLhMxLziC8IYkQLpb'

    .NOTES
    v2
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$GeneratedKey,

        [Parameter()]
        [string]$PreDefinedKey,

        [Parameter(Mandatory = $true)]
        [string]$EncryptedString,

        [Parameter(Mandatory = $false)]
        [int]$KeySize = 256,

        [Parameter(Mandatory = $false)]
        [int]$BlockSize = 128,

        [Parameter(Mandatory = $false)]
        [ValidateSet('CBC', 'CFB', 'CTS', 'ECB', 'OFB')]
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
        switch ($PSBoundParameters.Keys) {
            'GeneratedKey' {
                $AesManaged.Key = [System.Convert]::FromBase64String($GeneratedKey)
                }
            'PreDefinedKey' {
                $AesManaged.Key = $ShaManaged.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($PreDefinedKey))
            }
        }
        $CipherBytes = [System.Convert]::FromBase64String($EncryptedString)
        $AesManaged.IV = $CipherBytes[0..15]
        $Decryptor = $AesManaged.CreateDecryptor()
        $DecryptedBytes = $Decryptor.TransformFinalBlock($CipherBytes, 16, $CipherBytes.Length - 16)
        $PublicKey = [System.Text.Encoding]::UTF8.GetString($DecryptedBytes).Trim([char]0)
    }
    END {
        $AesManaged.Dispose()
        if ($GeneratedKey) {
            Write-Host "PreGenerated string: $GeneratedKey" -ForegroundColor Yellow
        }
        if ($PreDefinedKey) {
            Write-Host "PreDefined string: $PreDefinedKey" -ForegroundColor DarkYellow
        }
        Write-Host "Decrypted string: $PublicKey" -ForegroundColor Green
        Clear-History -Confirm
    }
}