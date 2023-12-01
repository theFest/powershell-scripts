Function Invoke-StringDecryption {
    <#
    .SYNOPSIS
    Decrypt a string with it's password.
    
    .DESCRIPTION
    With this simple function you can decrypt a string, mandatory to reuse defined or generated key from a encrypt form.
    
    .PARAMETER EncryptedString
    Mandatory - actual string you wanna to decrypt with your corresponding key. 
    .PARAMETER GeneratedKey
    NotMandatory - your randomly generated password with which you will decrypt your string.
    .PARAMETER PreDefinedKey
    NotMandatory - your predefined password with which you will decrypt your string. 
    .PARAMETER KeySize
    NotMandatory - define your key size here, recommended is already defined. 
    .PARAMETER BlockSize
    NotMandatory - define your block size here, default is 128.   
    .PARAMETER Mode
    NotMandatory - choose cipher mode, default is CBC.  
    .PARAMETER Padding
    NotMandatory - choose padding mode, default is set to Zeros.
    .PARAMETER OutputToFile
    NotMandatory - specifies whether the decrypted string should be output to a file. If this switch is used, the decrypted string will be saved to a file.
    .PARAMETER OutputFilePath
    NotMandatory - file path where the decrypted string will be saved if the OutputToFile switch is used. If not provided, the decrypted string will be saved to a file named 'Decrypted_Output.txt' in the current directory.
    
    .EXAMPLE
    Invoke-StringDecryption -PreDefinedKey 'my_private_password' -EncryptedString 'oqbET916P0HPwYhepHqP3SPF3bd2qageFJgR2/oxpHI='
    Invoke-StringDecryption -GeneratedKey 'n+FnVLTeF0sFKbRonuzgz7ECSQb776wdvsnpSx1q7z4=' -EncryptedString 'R7M8uqAjkI15H9ha9Hxx3WFNlQoli+hl7Gg6vZeAa1Z6G4avLhMxLziC8IYkQLpb'
    
    .NOTES
    v0.2.2
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$EncryptedString,

        [Parameter(Position = 1)]
        [string]$GeneratedKey,

        [Parameter(Position = 2)]
        [string]$PreDefinedKey,

        [Parameter(Position = 3)]
        [int]$KeySize = 256,

        [Parameter(Position = 4)]
        [int]$BlockSize = 128,

        [Parameter(Position = 5)]
        [ValidateSet("CBC", "CFB", "CTS", "ECB", "OFB")]
        $Mode = "CBC",

        [Parameter(Position = 6)]
        [ValidateSet("Zeros", "ANSIX923", "ISO10126", "PKCS7", "None")]
        $Padding = "Zeros",

        [Parameter(Position = 7)]
        [switch]$OutputToFile = $false,

        [Parameter(Position = 8)]
        [string]$OutputFilePath = "$env:USERPROFILE\Desktop\decrypted_string.txt"
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
            switch ($PSBoundParameters.Keys) {
                "GeneratedKey" {
                    $AesManaged.Key = [System.Convert]::FromBase64String($GeneratedKey)
                }
                "PreDefinedKey" {
                    $AesManaged.Key = $ShaManaged.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($PreDefinedKey))
                }
            }
            $CipherBytes = [System.Convert]::FromBase64String($EncryptedString)
            $AesManaged.IV = $CipherBytes[0..15]
            $Decryptor = $AesManaged.CreateDecryptor()
            $DecryptedBytes = $Decryptor.TransformFinalBlock($CipherBytes, 16, $CipherBytes.Length - 16)
            $DecryptedString = [System.Text.Encoding]::UTF8.GetString($DecryptedBytes).Trim([char]0)
            if ($OutputToFile) {
                $DecryptedString | Out-File -FilePath $OutputFilePath -Encoding UTF8 -Force
                Write-Host "Decrypted string saved to $OutputFilePath" -ForegroundColor Cyan
            }
            else {
                Write-Host "Decrypted string: $DecryptedString" -ForegroundColor Green
            }
        }
        catch {
            Write-Error -Message "Error occurred during decryption: $_"
        }
        finally {
            $AesManaged.Dispose()
        }
    }
    END {
        if ($GeneratedKey) {
            Write-Host "PreGenerated string: $GeneratedKey" -ForegroundColor Yellow
        }
        if ($PreDefinedKey) {
            Write-Host "PreDefined string: $PreDefinedKey" -ForegroundColor DarkYellow
        }
        Clear-History -Confirm
    }
}
