Function DecryptFile {
    <#
    .SYNOPSIS
    Decrypt a file with it's predeclared password.
    
    .DESCRIPTION
    With this simple function you can decrypt a file with it's key. Mandatory to reuse defined or generated key from a encrypt form.
    
    .PARAMETER Key (choose either PreDefined or PreGenerated)
    Mandatory - your password with which you will encrypt your string. Don't forget your key because it's used for decryption.
    .PARAMETER Path
    Mandatory - location where encrypted file resides, for example "$env:USERPROFILE\Desktop\encrypted_file.txt.aes".
    .PARAMETER KeySize
    NotMandatory - define your key size here, recommended is already defined. 
    .PARAMETER BlockSize
    NotMandatory - define your block size here, default is 128. 
    .PARAMETER CipherMode
    NotMandatory - choose cipher mode, default is CBC.  
    .PARAMETER PaddingMode
    NotMandatory - choose padding mode, default is set to Zeros.
    
    .EXAMPLE
    DecryptFile -PreDefinedKey 'my_private_password' -Path "$env:USERPROFILE\Desktop\encrypted_file.txt.aes"
    DecryptFile -PreGeneratedKey '62u8v/KwIhRd7n9LRq75sCa5bOOejuJGC53A3grCZz0=' -Path "$env:USERPROFILE\Desktop\encrypted_file.txt.aes"
    
    .NOTES
    v1
    #>
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = "PreDefinedKey")]
        [string]$PreDefinedKey,

        [Parameter(ParameterSetName = "PreGeneratedKey")]
        [string]$PreGeneratedKey,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [int]$KeySize = 256,

        [Parameter(Mandatory = $false)]
        [int]$BlockSize = 128,

        [Parameter(Mandatory = $false)]
        [ValidateSet('CBC', 'CFB', 'CTS', 'ECB', 'OFB')]
        $CipherMode = 'CBC',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Zeros', 'ANSIX923', 'ISO10126', 'PKCS7', 'None')]
        $PaddingMode = 'Zeros'
    )
    BEGIN {
        $ShaManaged = New-Object System.Security.Cryptography.SHA256Managed
        $AesManaged = New-Object System.Security.Cryptography.AesManaged
    }
    PROCESS {
        $AesManaged.Mode = [System.Security.Cryptography.CipherMode]::$CipherMode
        $AesManaged.Padding = [System.Security.Cryptography.PaddingMode]::$PaddingMode
        $AesManaged.BlockSize = $BlockSize
        $AesManaged.KeySize = $KeySize
        switch ($PSBoundParameters.Keys) {
            'PreGeneratedKey' {                
                $AesManaged.Key = [System.Convert]::FromBase64String($PreGeneratedKey)
            }
            'PreDefinedKey' {
                $AesManaged.Key = $ShaManaged.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($PreDefinedKey))
            }
        }
        $File = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
        if (!$File.FullName) {
            Write-Error -Message "File not found, please check your path: $Path!"
            break
        }
        $CipherBytes = [System.IO.File]::ReadAllBytes($File.FullName)
        $OutFilePath = $File.FullName -replace $File.Extension
        $AesManaged.IV = $CipherBytes[0..15]
        $Decryptor = $AesManaged.CreateDecryptor()
        $DecryptedBytes = $Decryptor.TransformFinalBlock($CipherBytes, 16, $CipherBytes.Length - 16)
        [System.IO.File]::WriteAllBytes($OutFilePath, $DecryptedBytes)
        (Get-Item $OutFilePath).LastWriteTime = $File.LastWriteTime
    }
    END {
        $ShaManaged.Dispose()
        $AesManaged.Dispose()
        if ($PreDefinedKey) {
            Write-Host "PreDefined key: $PreDefinedKey" -ForegroundColor DarkYellow
        }
        if ($PreGeneratedKey) {
            Write-Host "PreGenerated key: $PreGeneratedKey" -ForegroundColor Yellow
        }
        Write-Host "Decrypted file path: $OutFilePath" -ForegroundColor Green
        Clear-History -Confirm
    }
}