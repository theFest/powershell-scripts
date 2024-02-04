Function Convert-StringToHash {
    <#
    .SYNOPSIS
    Converts a string to hash using various algorithms.

    .DESCRIPTION
    This function takes a string as input and converts it to a hash using different algorithms. It supports multiple encoding types and can generate hashes for various algorithms.

    .PARAMETER String
    The input string that needs to be converted to a hash.
    .PARAMETER Encoding
    Specifies the encoding type for the input string. Default is UTF8.
    .PARAMETER Algorithm
    Specifies the hashing algorithm to be used. Default is MD5.
    .PARAMETER All
    Switch parameter to generate hashes for all supported algorithms.

    .EXAMPLE
    Convert-StringToHash -String "Password123" -Encoding UTF8 -Algorithm MD5

    .NOTES
    v0.0.1
    #>
    [CmdletBinding(DefaultParameterSetName = "Single")]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $false)]
        [string]$String,

        [Parameter(Mandatory = $false, Position = 1, ValueFromPipeline = $false)]
        [ValidateSet("UTF8", "ASCII", "BigEndianUnicode", "Unicode", "UTF32", "UTF7")]
        [string]$Encoding = "UTF8",

        [Parameter(Mandatory = $false, Position = 2, ValueFromPipeline = $false, ParameterSetName = "Single")]
        [ValidateSet("MD5", "SHA1", "SHA256", "SHA384", "SHA512", "RIPEMD160")]
        [string]$Algorithm = "MD5",

        [Parameter(Mandatory = $false, ParameterSetName = "All")]
        [switch][bool]$All
    )
    BEGIN {
        $GetHashObject = {
            param($Algorithm)
            switch ($Algorithm) {
                "RIPEMD160" { New-Object -TypeName System.Security.Cryptography.RIPEMD160Managed }
                default { New-Object -TypeName "System.Security.Cryptography.$($Algorithm)CryptoServiceProvider" }
            }
        }
        $CalculateHash = {
            param($HashObj, $String, $Encoding)
            $ToHash = [System.Text.Encoding]::$Encoding.GetBytes($String)
            $Bytes = $HashObj.ComputeHash($ToHash)
            $Bytes | ForEach-Object { "{0:X2}" -f $_ }
        }
        $Results = @()
    }
    PROCESS {
        if ($All) {
            $Algorithms = "MD5", "SHA1", "SHA256", "SHA384", "SHA512", "RIPEMD160"
            foreach ($Algorithm in $Algorithms) {
                $HashObj = &$GetHashObject $Algorithm
                $Result = &$CalculateHash -HashObj $HashObj -String $String -Encoding $Encoding
                $Results += [PSCustomObject]@{ Algorithm = $Algorithm; Hash = $Result -join '' }
            }
        }
        else {
            $HashObj = &$GetHashObject $Algorithm
            $Result = &$CalculateHash -HashObj $HashObj -String $String -Encoding $Encoding
            $Results += [PSCustomObject]@{ Algorithm = $Algorithm; Hash = $Result -join '' }
        }
    }
    END {
        $Results
    }
}
