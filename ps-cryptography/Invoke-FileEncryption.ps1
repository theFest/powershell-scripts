Function Invoke-FileEncryption {
    <#
    .SYNOPSIS
    Encrypt a file with it's secure password.
    
    .DESCRIPTION
    With this simple function you can encrypt a file with it's key, reuse defined or generated Key in a decrypt form.
    
    .PARAMETER Key (choose either Defined or Generated)
    Mandatory - your password with which you will encrypt your file. Don't forget your key because it's used for decryption.
    .PARAMETER Path
    Mandatory - location where the file is located, for example "$env:USERPROFILE\Desktop".
    .PARAMETER Extension
    NotMandatory - declare type of extension to be added for an encrypted file.
    .PARAMETER KeySize
    NotMandatory - define your key size here, recommended is already defined. 
    .PARAMETER BlockSize
    NotMandatory - define your block size here, default is 128. 
    .PARAMETER CipherMode
    NotMandatory - choose cipher mode, default is CBC.  
    .PARAMETER PaddingMode
    NotMandatory - choose padding mode, default is set to Zeros.
    
    .EXAMPLE
    Invoke-FileEncryption -DefinedKey 'my_private_password' -Path "$env:USERPROFILE\Desktop\file_to_encrypt.txt"
    Invoke-FileEncryption -GeneratedKey -Path "$env:USERPROFILE\Desktop\file_to_encrypt.txt"
    
    .NOTES
    v0.1.2
    #>
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName = "DefinedKey")]
        [string]$DefinedKey,

        [Parameter(ParameterSetName = "GeneratedKey")]
        [switch]$GeneratedKey,

        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$Extension = ".aes",

        [Parameter(Mandatory = $false)]
        [int]$KeySize = 256,

        [Parameter(Mandatory = $false)]
        [int]$BlockSize = 128,

        [Parameter(Mandatory = $false)]
        [ValidateSet("CBC", "CFB", "CTS", "ECB", "OFB")]
        $CipherMode = "CBC",

        [Parameter(Mandatory = $false)]
        [ValidateSet("Zeros", "ANSIX923", "ISO10126", "PKCS7", "None")]
        $PaddingMode = "Zeros"
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
            "DefinedKey" {
                $AesManaged.Key = $ShaManaged.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($DefinedKey))
            }
            "GeneratedKey" {                
                $AesManaged.GenerateKey()
                $RandomlyGeneratedKey = [System.Convert]::ToBase64String($AesManaged.Key)
            }
        }
        $File = Get-ChildItem -Path $Path -ErrorAction SilentlyContinue
        if (!$File.FullName) {
            Write-Error -Message "File not found, please check your path: $Path!"
            break
        }
        $PlainBytes = [System.IO.File]::ReadAllBytes($File.FullName)
        $OutFilePath = $File.FullName + $Extension
        $Encryptor = $AesManaged.CreateEncryptor()
        $EncryptedBytes = $Encryptor.TransformFinalBlock($PlainBytes, 0, $PlainBytes.Length)
        $EncryptedBytes = $AesManaged.IV + $EncryptedBytes
        [System.IO.File]::WriteAllBytes($OutFilePath, $EncryptedBytes)
        (Get-Item $OutFilePath).LastWriteTime = $File.LastWriteTime
    }
    END {
        $ShaManaged.Dispose()
        $AesManaged.Dispose()
        if ($DefinedKey) {
            Write-Host "Defined key: $DefinedKey" -ForegroundColor DarkYellow
        }
        if ($GeneratedKey) {
            Write-Host "Generated key: $RandomlyGeneratedKey" -ForegroundColor Yellow
        }
        Write-Host "Encrypted file path: $OutFilePath" -ForegroundColor Green
        Clear-History -Confirm
    }
}