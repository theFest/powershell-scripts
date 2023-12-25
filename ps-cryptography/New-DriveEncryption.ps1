Function New-DriveEncryption {
    <#
    .SYNOPSIS
    Encrypts files on a specified drive using the specified encryption algorithm.

    .DESCRIPTION
    This function encrypts files on the specified drive using either AES, DES, or RSA encryption algorithms. The encrypted files are saved in the specified output path.

    .PARAMETER EncryptionAlgorithm
    Mandatory - the encryption algorithm to use. Valid values are "AES", "DES", or "RSA".
    .PARAMETER DriveLetter
    Mandatory - specifies the drive letter of the target drive (e.g., "G:").
    .PARAMETER OutputPath
    NotMandatory - path where the encrypted files will be saved. Defaults to "C:\Temp".
    .PARAMETER Pass
    Mandatory - the password or key required for encryption.
    .PARAMETER IncludeSubdirectories
    NotMandatory - includes subdirectories for encryption.

    .EXAMPLE
    New-DriveEncryption -EncryptionAlgorithm AES -DriveLetter "G:" -Pass "12345MyEncryptPassword" -IncludeSubdirectories

    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("AES", "DES", "RSA", IgnoreCase = $true)]
        [string]$EncryptionAlgorithm,

        [Parameter(Mandatory = $true)]
        [ValidatePattern("[A-Z]:")]
        [string]$DriveLetter,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "C:\Temp",

        [Parameter(Mandatory = $true)]
        [string]$Pass,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeSubdirectories
    )
    try {
        Function Get-AESIV {
            $IV = New-Object Byte[] 16
            [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($IV)
            return $IV
        }
        $DriveInfo = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$DriveLetter'"
        if (!$DriveInfo) {
            throw "Drive $DriveLetter not found!"
        }
        $ExcludedFolders = @('Windows', 'Program Files', 'Program Files (x86)', 'Recovery', 'System Volume Information')
        $DataToEncrypt = Get-ChildItem -Path $DriveLetter -File -Recurse:$IncludeSubdirectories -Exclude $ExcludedFolders
        if (!$DataToEncrypt) {
            throw "No files found at specified path!"
        }
        foreach ($File in $DataToEncrypt) {
            $OutputFile = Join-Path $OutputPath "$($File.BaseName).encrypted"
            $Content = Get-Content -Path $File.FullName -Raw
            switch ($EncryptionAlgorithm.ToLower()) {
                "aes" {
                    $AES = [System.Security.Cryptography.AesManaged]::new()
                    $AES.KeySize = 256
                    $AES.BlockSize = 128
                    $AES.Key = (New-Object Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($Pass))              
                    $AES.IV = Get-AESIV
                    $Cipher = $AES.CreateEncryptor()
                    $ContentBytes = [Text.Encoding]::UTF8.GetBytes($Content)
                    $EncryptedContent = $Cipher.TransformFinalBlock($ContentBytes, 0, $ContentBytes.Length)
                    $ObfuscatedContent = @{
                        "Content"   = [Convert]::ToBase64String($EncryptedContent)
                        "Algorithm" = "AES"
                        "IV"        = [Convert]::ToBase64String($AES.IV)
                    } | ConvertTo-Json -Verbose
                    $ObfuscatedContent | Out-File -FilePath $OutputFile -Verbose
                    Write-Host "Encrypted file: $($File.FullName) -> $OutputFile" -ForegroundColor Gray
                }
                "DES" {
                    $DES = [System.Security.Cryptography.DESCryptoServiceProvider]::new()
                    $DES.Key = [System.Text.Encoding]::UTF8.GetBytes($Pass.Substring(0, 8))
                    $DES.IV = [System.Text.Encoding]::UTF8.GetBytes($Pass.Substring(0, 8))
                    $Cipher = $DES.CreateEncryptor()
                    $ContentBytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
                    $EncryptedContent = $Cipher.TransformFinalBlock($ContentBytes, 0, $ContentBytes.Length)
                    $ObfuscatedContent = @{
                        "Content"   = [Convert]::ToBase64String($EncryptedContent)
                        "Algorithm" = "DES"
                    } | ConvertTo-Json -Verbose
                    $ObfuscatedContent | Out-File -FilePath $OutputFile -Verbose
                    Write-Host "Encrypted file: $($File.FullName) -> $OutputFile" -ForegroundColor Gray
                }
                "RSA" {
                    $RSA = [System.Security.Cryptography.RSACryptoServiceProvider]::new(2048)
                    $RSA.FromXmlString($Pass)
                    $ContentBytes = [System.Text.Encoding]::UTF8.GetBytes($Content)
                    $EncryptedContent = $RSA.Encrypt($ContentBytes, $true)
                    $ObfuscatedContent = @{
                        "Content"   = [Convert]::ToBase64String($EncryptedContent)
                        "Algorithm" = "RSA"
                    } | ConvertTo-Json -Verbose
                    $ObfuscatedContent | Out-File -FilePath $OutputFile -Verbose
                    Write-Host "Encrypted file: $($File.FullName) -> $OutputFile" -ForegroundColor Gray
                }
                default { 
                    throw "Invalid encryption algorithm specified: $EncryptionAlgorithm!" 
                }
            }
        }
        Write-Host "Encryption of drive $DriveLetter completed!" -ForegroundColor Green
    }
    catch {
        Write-Error -Message "Encryption failed: $_"
    }
}
