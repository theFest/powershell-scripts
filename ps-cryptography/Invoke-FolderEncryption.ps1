Function Invoke-FolderEncryption {
    <#
    .SYNOPSIS
    Encrypts files within a folder and its subfolders.
    
    .DESCRIPTION
    This function encrypts files within a specified folder and its subfolders using AES encryption.
    
    .PARAMETER FolderPath
    Mandatory - the path to the folder containing files to be encrypted.
    .PARAMETER OutputPath
    Mandatory - path to the output folder where encrypted files will be stored.
    .PARAMETER Key
    Mandatory - specifies the encryption key used for encrypting files.
    
    .EXAMPLE
    Invoke-FolderEncryption -FolderPath "$env:USERPROFILE\Desktop\PlainTextFiles" -OutputPath "$env:USERPROFILE\Desktop\EncryptedFolder" -Key "Abc12345$Your_Key"
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [string]$Key
    )
    try {
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -ItemType Directory -Force -Path $OutputPath | Out-Null
        }
        $SaltSize = 16
        $Salt = New-Object byte[] $SaltSize
        $Rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
        $Rng.GetBytes($Salt)
        $KeyBytes = [System.Text.Encoding]::UTF8.GetBytes($Key)
        $KeySecure = New-Object System.Security.Cryptography.Rfc2898DeriveBytes -ArgumentList @($KeyBytes, $Salt, 1000)
        $EncryptionKey = $KeySecure.GetBytes(32)
        Get-ChildItem -Path $FolderPath -Recurse | ForEach-Object {
            $RelativePath = $_.FullName.Substring($FolderPath.Length + 1)
            $OutputFile = Join-Path -Path $OutputPath -ChildPath $RelativePath
            if ($_.PSIsContainer) {
                New-Item -ItemType Directory -Force -Path $OutputFile | Out-Null
            }
            else {
                $Content = Get-Content $_.FullName -Raw
                $Aes = New-Object System.Security.Cryptography.AesCryptoServiceProvider
                $Aes.KeySize = 256
                $Aes.BlockSize = 128
                $Aes.Key = $EncryptionKey
                $Aes.GenerateIV()
                $Encryptor = $Aes.CreateEncryptor($Aes.Key, $Aes.IV)
                $ContentBytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
                $EncryptedContent = $Encryptor.TransformFinalBlock($ContentBytes, 0, $ContentBytes.Length)
                [System.IO.File]::WriteAllBytes($OutputFile, $Salt + $Aes.IV + $EncryptedContent)
            }
        }
        Write-Host "Folder encrypted successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
