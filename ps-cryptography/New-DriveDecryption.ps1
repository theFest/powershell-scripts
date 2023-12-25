Function New-DriveDecryption {
    <#
    .SYNOPSIS
    Decrypts files on a specified drive using various encryption algorithms.

    .DESCRIPTION
    This function is designed to decrypt files on a specified drive that have been encrypted using different encryption algorithms, such as AES, DES, or RSA.

    .PARAMETER DriveLetter
    Mandatory - the drive letter of the encrypted drive.
    .PARAMETER Pass
    Mandatory - specifies the decryption password or key.
    .PARAMETER OutputPath
    Mandatory - path where the decrypted files will be saved.

    .EXAMPLE
    New-DriveDecryption -DriveLetter "G:" -Pass "12345MyEncryptPassword" -OutputPath "$env:SystemDrive\DecryptedFolder"

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidatePattern("[A-Z]:")]
        [string]$DriveLetter,

        [Parameter(Mandatory = $true)]
        [string]$Pass,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    try {
        $EncryptedFiles = Get-ChildItem -Path $DriveLetter -File -Recurse -Include *.encrypted
        if (!$EncryptedFiles) {
            throw "No encrypted files found at specified path!"
        }
        foreach ($File in $EncryptedFiles) {
            $OutputFile = Join-Path $OutputPath "$($File.BaseName).decrypted"
            $EncryptedContent = Get-Content -Path $File.FullName -Raw | ConvertFrom-Json
            switch ($EncryptedContent.Algorithm.ToLower()) {
                "AES" {
                    $AES = [System.Security.Cryptography.AesManaged]::new()
                    $AES.KeySize = 256
                    $AES.BlockSize = 128
                    $AES.Key = (New-Object Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($Pass))              
                    $AES.IV = [Convert]::FromBase64String($EncryptedContent.IV)
                    $Cipher = $AES.CreateDecryptor()
                    $EncryptedBytes = [Convert]::FromBase64String($EncryptedContent.Content)
                    $DecryptedContent = $Cipher.TransformFinalBlock($EncryptedBytes, 0, $EncryptedBytes.Length)
                    [Text.Encoding]::UTF8.GetString($DecryptedContent) | Out-File -FilePath $OutputFile
                    Write-Host "Decrypted file: $($File.FullName) -> $OutputFile" -ForegroundColor Gray
                }
                "DES" {
                    $DES = [System.Security.Cryptography.DESCryptoServiceProvider]::new()
                    $DES.Key = [System.Text.Encoding]::UTF8.GetBytes($Pass.Substring(0, 8))
                    $DES.IV = [System.Text.Encoding]::UTF8.GetBytes($Pass.Substring(0, 8))
                    $Cipher = $DES.CreateDecryptor()
                    $EncryptedBytes = [Convert]::FromBase64String($EncryptedContent.Content)
                    $DecryptedContent = $Cipher.TransformFinalBlock($EncryptedBytes, 0, $EncryptedBytes.Length)
                    [Text.Encoding]::UTF8.GetString($DecryptedContent) | Out-File -FilePath $OutputFile
                    Write-Host "Decrypted file: $($File.FullName) -> $OutputFile" -ForegroundColor Gray
                }
                "RSA" {
                    $RSA = [System.Security.Cryptography.RSACryptoServiceProvider]::new(2048)
                    $RSA.FromXmlString($Pass)
                    $EncryptedBytes = [Convert]::FromBase64String($EncryptedContent.Content)
                    $DecryptedContent = $RSA.Decrypt($EncryptedBytes, $true)
                    [Text.Encoding]::UTF8.GetString($DecryptedContent) | Out-File -FilePath $OutputFile
                    Write-Host "Decrypted file: $($File.FullName) -> $OutputFile" -ForegroundColor Gray
                }
                default {
                    throw "Invalid encryption algorithm detected in file: $($File.FullName)!"
                }
            }
        }
        Write-Host "Decryption of encrypted files on drive $DriveLetter completed!" -ForegroundColor Green
    }
    catch {
        Write-Error -Message "Decryption failed: $_"
    }
}
