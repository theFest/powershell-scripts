Function New-Base64Decode {
    <#
    .SYNOPSIS
    Decodes a Base64 string to its original text.
    
    .DESCRIPTION
    This function decodes a Base64-encoded string back to its original text representation.
    
    .PARAMETER Base64String
    Mandatory - specifies the Base64-encoded string to be decoded.
    
    .EXAMPLE
    New-Base64Decode -Base64String "SGVsbG8sIFdvcmxkIQ=="
    
    .NOTES
    v0.0.1
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Base64String
    )
    PROCESS {
        try {
            $DecodedBytes = [System.Convert]::FromBase64String($Base64String)
            $DecodedText = [System.Text.Encoding]::UTF8.GetString($DecodedBytes)
            Write-Output -InputObject $DecodedText
        }
        catch {
            Write-Error -Message "Error decoding Base64 string: $_"
        }
    }
}
