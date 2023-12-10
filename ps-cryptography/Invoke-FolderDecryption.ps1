Function Invoke-FolderDecryption {
    <#
    .SYNOPSIS
    Decrypts encrypted files within a folder and its subfolders.
    
    .DESCRIPTION
    This function decrypts files within a specified folder and its subfolders that were previously encrypted using AES encryption.
    
    .PARAMETER FolderPath
    Mandatory - the path to the folder containing encrypted files.
    .PARAMETER OutputPath
    Mandatory - path to the output folder where decrypted files will be stored.
    .PARAMETER Key
    Mandatory - specifies the decryption key used for decrypting files.
    
    .EXAMPLE
    Invoke-FolderDecryption -FolderPath "$env:USERPROFILE\Desktop\EncryptedFolder" -OutputPath "$env:USERPROFILE\Desktop\DecryptedFolder" -Key "Abc12345$Your_Key"
    
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
        Get-ChildItem -Path $FolderPath -Recurse | ForEach-Object {
            $RelativePath = $_.FullName.Substring($FolderPath.Length + 1)
            $OutputFile = Join-Path -Path $OutputPath -ChildPath $RelativePath
            if ($_.PSIsContainer) {
                New-Item -ItemType Directory -Force -Path $OutputFile | Out-Null
            }
            else {
                $Content = Get-Content $_.FullName -Encoding Byte
                $SaltSize = 16
                $Salt = $Content[0..($SaltSize - 1)]
                $Iv = $Content[$SaltSize..($SaltSize + 15)]
                $EncryptedContent = $Content[($SaltSize + 16)..($Content.Length - 1)]
                $KeyBytes = [System.Text.Encoding]::UTF8.GetBytes($Key)
                $KeySecure = New-Object System.Security.Cryptography.Rfc2898DeriveBytes -ArgumentList @($KeyBytes, $Salt, 1000)
                $DecryptionKey = $KeySecure.GetBytes(32)
                $Aes = New-Object System.Security.Cryptography.AesCryptoServiceProvider
                $Aes.KeySize = 256
                $Aes.BlockSize = 128
                $Aes.Key = $DecryptionKey
                $Aes.IV = $Iv
                $Decryptor = $Aes.CreateDecryptor($Aes.Key, $Aes.IV)
                $DecryptedContent = $Decryptor.TransformFinalBlock($EncryptedContent, 0, $EncryptedContent.Length)
                $OutputFileDir = Split-Path -Path $OutputFile -Parent
                if (-not (Test-Path -Path $OutputFileDir)) {
                    New-Item -ItemType Directory -Force -Path $OutputFileDir | Out-Null
                }
                [System.IO.File]::WriteAllBytes($OutputFile, $DecryptedContent)
            }
        }
        Write-Host "Folder decrypted successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
